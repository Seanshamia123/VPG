# payments.py - Complete multi-provider payment system (IntaSend + Paystack)
import sys
import os
from flask import request, jsonify, current_app
from flask_restx import Namespace, Resource, fields
from datetime import datetime, timedelta
import uuid
import logging
from werkzeug.security import check_password_hash

# Add the parent directory to the Python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from models import Subscription, User, Advertiser, db
from .decorators import token_required
from config import Config

# ============================================
# DEVELOPMENT MODE FLAG
# ============================================
DEVELOPMENT_MODE = True # Set to False to re-enable subscription checks
# ============================================

# Import payment services with error handling
try:
    from .intasend_service import IntaSendService, SubscriptionPlans
except ImportError as e:
    logging.error(f"Failed to import IntaSend service: {e}")
    class IntaSendService:
        def __init__(self, *args, **kwargs):
            pass
        def create_checkout_session(self, *args, **kwargs):
            return {"error": "IntaSend service not configured"}
        def verify_payment(self, *args, **kwargs):
            return {"error": "IntaSend service not configured"}
        def get_supported_currencies(self):
            return []
    
    class SubscriptionPlans:
        @classmethod
        def get_plans(cls):
            return []
        @classmethod
        def get_plan_by_id(cls, plan_id):
            raise ValueError("IntaSend service not configured")
        @classmethod
        def get_plan_price(cls, plan_id, currency):
            raise ValueError("IntaSend service not configured")

try:
    from .paystack_service import PaystackService, get_payment_provider
except ImportError as e:
    logging.error(f"Failed to import Paystack service: {e}")
    class PaystackService:
        def __init__(self, *args, **kwargs):
            pass
        def initialize_transaction(self, *args, **kwargs):
            return {"error": "Paystack service not configured"}
        def verify_transaction(self, *args, **kwargs):
            return {"error": "Paystack service not configured"}
        def get_supported_currencies(self):
            return []
    
    def get_payment_provider(currency, payment_method, phone_number=None):
        return 'paystack'

api = Namespace('payment', description='Multi-provider payment management with IntaSend and Paystack')

# Initialize payment services
intasend_service = None
paystack_service = None

def init_payment_services():
    """Initialize both IntaSend and Paystack services"""
    global intasend_service, paystack_service
    
    if intasend_service is None:
        try:
            intasend_service = IntaSendService(
                publishable_key=Config.INTASEND_PUBLISHABLE_KEY,
                secret_key=Config.INTASEND_SECRET_KEY,
                is_test=Config.INTASEND_IS_TEST
            )
            logging.info("=== IntaSend Service Initialized ===")
            logging.info(f"Publishable Key: {Config.INTASEND_PUBLISHABLE_KEY[:20]}...")
            logging.info(f"Is Test: {Config.INTASEND_IS_TEST}")
        except Exception as e:
            logging.error(f"Failed to initialize IntaSend service: {e}")
    
    if paystack_service is None:
        try:
            paystack_service = PaystackService(
                secret_key=Config.PAYSTACK_SECRET_KEY,
                is_test=getattr(Config, 'PAYSTACK_IS_TEST', True)
            )
            logging.info("=== Paystack Service Initialized ===")
            logging.info(f"Secret Key: {Config.PAYSTACK_SECRET_KEY[:20]}...")
            logging.info(f"Is Test: {getattr(Config, 'PAYSTACK_IS_TEST', True)}")
        except Exception as e:
            logging.error(f"Failed to initialize Paystack service: {e}")
    
    return intasend_service, paystack_service


def authenticate_with_credentials(email, password, user_type):
    """
    CRITICAL: Authenticate user without JWT for subscription-during-signup flow
    This allows subscription creation before login tokens are issued
    """
    try:
        # Get user based on type
        if user_type == 'advertiser':
            user = Advertiser.query.filter_by(email=email).first()
        else:
            user = User.query.filter_by(email=email).first()
        
        if not user:
            logging.warning(f"User not found: {email}, type: {user_type}")
            return None
        
        # Verify password
        if not check_password_hash(user.password_hash, password):
            logging.warning(f"Invalid password for user: {email}")
            return None
        
        logging.info(f"✓ Credential authentication successful for {email}")
        return user
        
    except Exception as e:
        logging.error(f"Authentication error: {e}")
        return None


# Models for API documentation
payment_request_model = api.model('PaymentRequest', {
    'plan_id': fields.String(required=True, description='Subscription plan ID (basic, premium)'),
    'currency': fields.String(required=True, description='Payment currency (KES, USD, EUR, NGN, GHS, ZAR)'),
    'payment_method': fields.String(required=True, description='Payment method: mpesa, card, bank_transfer'),
    'phone_number': fields.String(required=False, description='Phone number for M-Pesa payments (254XXXXXXXXX)'),
    'redirect_url': fields.String(required=False, description='URL to redirect after payment'),
    'email': fields.String(required=False, description='Email address'),
    'pending_login_email': fields.String(required=False, description='Email for credential auth during signup'),
    'pending_login_password': fields.String(required=False, description='Password for credential auth'),
    'pending_login_user_type': fields.String(required=False, description='User type: advertiser or user'),
})

checkout_response_model = api.model('CheckoutResponse', {
    'success': fields.Boolean(description='Success status'),
    'provider': fields.String(description='Payment provider used (intasend or paystack)'),
    'payment_type': fields.String(description='Type of payment (mpesa_stk_push, web_checkout, card_direct)'),
    'checkout_url': fields.String(description='Checkout URL (for Paystack card/bank payments)'),
    'checkout_id': fields.String(description='Checkout session ID'),
    'reference': fields.String(description='Payment reference'),
    'amount': fields.Float(description='Payment amount'),
    'currency': fields.String(description='Payment currency'),
    'message': fields.String(description='Status message'),
})

subscription_plan_model = api.model('SubscriptionPlan', {
    'id': fields.String(description='Plan ID'),
    'name': fields.String(description='Plan name'),
    'description': fields.String(description='Plan description'),
    'price_kes': fields.Float(description='Price in KES'),
    'price_usd': fields.Float(description='Price in USD'),
    'price_eur': fields.Float(description='Price in EUR'),
    'duration_days': fields.Integer(description='Duration in days'),
    'features': fields.List(fields.String, description='Plan features'),
    'is_popular': fields.Boolean(description='Is popular plan'),
})

payment_verification_model = api.model('PaymentVerification', {
    'success': fields.Boolean(description='Verification success'),
    'status': fields.String(description='Payment status (complete, pending, failed)'),
    'subscription_id': fields.Integer(description='Created subscription ID'),
    'message': fields.String(description='Status message'),
})


@api.route('/plans')
class SubscriptionPlansList(Resource):
    @api.marshal_list_with(subscription_plan_model)
    def get(self):
        """Get all available subscription plans"""
        try:
            plans = SubscriptionPlans.get_plans()
            return [plan.__dict__ for plan in plans]
        except Exception as e:
            logging.error(f"Error fetching plans: {e}")
            api.abort(500, "Failed to fetch subscription plans")


@api.route('/plans/<string:plan_id>')
class SubscriptionPlanDetail(Resource):
    @api.marshal_with(subscription_plan_model)
    def get(self, plan_id):
        """Get specific subscription plan details"""
        try:
            plan = SubscriptionPlans.get_plan_by_id(plan_id)
            return plan.__dict__
        except ValueError as e:
            api.abort(404, str(e))
        except Exception as e:
            logging.error(f"Error fetching plan {plan_id}: {e}")
            api.abort(500, "Failed to fetch subscription plan")


@api.route('/currencies')
class SupportedCurrencies(Resource):
    def get(self):
        """Get supported currencies for all payment providers"""
        intasend, paystack = init_payment_services()
        
        currencies = []
        
        if intasend:
            try:
                intasend_currencies = intasend.get_supported_currencies()
                for curr in intasend_currencies:
                    curr['provider'] = 'intasend'
                    curr['methods'] = ['mpesa']
                    currencies.append(curr)
            except Exception as e:
                logging.error(f"Failed to get IntaSend currencies: {e}")
        
        if paystack:
            try:
                paystack_currencies = paystack.get_supported_currencies()
                for curr in paystack_currencies:
                    curr['provider'] = 'paystack'
                    curr['methods'] = ['card', 'bank_transfer']
                    currencies.append(curr)
            except Exception as e:
                logging.error(f"Failed to get Paystack currencies: {e}")
        
        return {'currencies': currencies}


@api.route('/providers')
class PaymentProviders(Resource):
    def get(self):
        """Get available payment providers and their supported methods"""
        return {
            'providers': [
                {
                    'id': 'intasend',
                    'name': 'IntaSend',
                    'methods': ['mpesa'],
                    'currencies': ['KES'],
                    'description': 'M-Pesa payments for Kenya',
                    'features': ['STK Push', 'Instant verification']
                },
                {
                    'id': 'paystack',
                    'name': 'Paystack',
                    'methods': ['card', 'bank_transfer'],
                    'currencies': ['KES', 'NGN', 'GHS', 'ZAR', 'USD'],
                    'description': 'Card payments and bank transfers',
                    'features': ['Multiple cards', 'Bank transfer', 'Mobile money']
                }
            ]
        }


@api.route('/create-checkout')
class CreateCheckout(Resource):
    @api.expect(payment_request_model)
    @api.marshal_with(checkout_response_model, code=201)
    def post(self):
        """
        Create payment checkout session
        Routes to appropriate provider based on payment method:
        - M-Pesa → IntaSend
        - Card/Bank Transfer → Paystack
        
        Supports both JWT authentication and credential-based authentication
        """
        if DEVELOPMENT_MODE:
            logging.warning("⚠️  DEVELOPMENT MODE: Subscription checks disabled")
        
        data = request.get_json() or {}
        
        print("\n=== CREATE CHECKOUT REQUEST ===")
        print(f"Headers: {dict(request.headers)}")
        print(f"Body keys: {data.keys()}")
        print(f"Payment method: {data.get('payment_method')}")
        print("=" * 30)
        
        current_user = None
        is_pending_login = False
        
        # Try JWT authentication first
        auth_header = request.headers.get('Authorization', '')
        if auth_header.startswith('Bearer '):
            try:
                from flask_jwt_extended import verify_jwt_in_request, get_jwt_identity
                verify_jwt_in_request()
                user_id = get_jwt_identity()
                
                current_user = Advertiser.query.get(user_id) or User.query.get(user_id)
                
                if current_user:
                    logging.info(f"✓ JWT authenticated user: {user_id}")
                    
            except Exception as e:
                logging.warning(f"JWT verification failed: {e}")
                current_user = None
        
        # If no JWT, try credential-based authentication
        if not current_user:
            pending_email = data.get('pending_login_email')
            pending_password = data.get('pending_login_password')
            pending_user_type = data.get('pending_login_user_type', 'advertiser')
            
            if pending_email and pending_password:
                logging.info(f"=== ATTEMPTING CREDENTIAL AUTH ===")
                logging.info(f"Email: {pending_email}")
                logging.info(f"User Type: {pending_user_type}")
                
                current_user = authenticate_with_credentials(
                    pending_email,
                    pending_password,
                    pending_user_type
                )
                
                if current_user:
                    is_pending_login = True
                    logging.info(f"✓ Credential authentication succeeded")
                else:
                    logging.error(f"✗ Credential authentication failed")
                    return {
                        'success': False,
                        'error': 'Invalid email or password'
                    }, 401
        
        # If still no user, reject
        if not current_user:
            logging.error("No authentication method succeeded")
            return {
                'success': False,
                'error': 'Authentication required. Please provide valid credentials or JWT token.'
            }, 401
        
        # Verify this is an advertiser
        if not isinstance(current_user, Advertiser):
            return {
                'success': False,
                'error': 'Subscriptions are only available for advertisers'
            }, 400
        
        # Validate required fields
        plan_id = data.get('plan_id')
        currency = data.get('currency', 'KES').upper()
        payment_method = data.get('payment_method', 'card').lower()
        phone_number = data.get('phone_number')
        redirect_url = data.get('redirect_url')
        email = data.get('email') or current_user.email
        
        if not plan_id:
            return {'success': False, 'error': 'Plan ID is required'}, 400
        
        if not payment_method:
            return {'success': False, 'error': 'Payment method is required'}, 400
        
        try:
            # Get plan details
            plan = SubscriptionPlans.get_plan_by_id(plan_id)
            amount = SubscriptionPlans.get_plan_price(plan_id, currency)
            amount = round(float(amount), 2)
            
            # Generate unique reference
            reference = f"SUB_{current_user.id}_{plan_id}_{uuid.uuid4().hex[:8].upper()}"
            
            # Determine payment provider
            provider = get_payment_provider(currency, payment_method, phone_number)
            
            logging.info(f"\n=== CREATING CHECKOUT SESSION ===")
            logging.info(f"Advertiser: {current_user.email} (ID: {current_user.id})")
            logging.info(f"Provider: {provider}")
            logging.info(f"Payment Method: {payment_method}")
            logging.info(f"Amount: {amount} {currency}")
            logging.info(f"Reference: {reference}")
            logging.info(f"Is Pending Login: {is_pending_login}")
            
            # Initialize payment services
            intasend, paystack = init_payment_services()
            
            # Route to appropriate provider
            if provider == 'intasend':
                # ===== INTASEND (M-PESA) =====
                if not intasend:
                    return {
                        'success': False,
                        'error': 'IntaSend payment service is not available'
                    }, 503
                
                if not phone_number:
                    return {
                        'success': False,
                        'error': 'Phone number is required for M-Pesa payments'
                    }, 400
                
                logging.info(f"Processing M-Pesa payment via IntaSend")
                logging.info(f"Phone: {phone_number}")
                
                # Get customer name
                customer_name = (current_user.name or '').split(' ', 1)
                first_name = customer_name[0] if customer_name else ''
                last_name = customer_name[1] if len(customer_name) > 1 else ''
                
                # Create IntaSend checkout
                checkout_response = intasend.create_checkout_session(
                    amount=amount,
                    currency=currency,
                    email=email,
                    phone_number=phone_number,
                    first_name=first_name,
                    last_name=last_name,
                    redirect_url=redirect_url or f"{Config.BASE_URL}/payment-success",
                    webhook_url=f"{Config.BASE_URL}/api/payment/webhook/intasend",
                    reference=reference
                )
                
                if 'error' in checkout_response:
                    logging.error(f"IntaSend error: {checkout_response['error']}")
                    return {
                        'success': False,
                        'error': f"M-Pesa payment creation failed: {checkout_response['error']}"
                    }, 400
                
                # Create pending subscription record
                checkout_id = checkout_response.get('checkout_id')
                invoice_id = checkout_response.get('invoice_id')
                
                pending_sub = Subscription(
                    user_id=current_user.id,
                    plan_id=plan.id,
                    plan_name=plan.name,
                    amount_paid=amount,
                    currency=currency,
                    payment_method='IntaSend-MPesa',
                    checkout_id=checkout_id,
                    payment_reference=reference,
                    invoice_id=invoice_id,
                    start_date=datetime.utcnow(),
                    end_date=datetime.utcnow() + timedelta(days=plan.duration_days),
                    status='pending',
                    payment_status='pending'
                )
                db.session.add(pending_sub)
                db.session.commit()
                
                logging.info(f"✓ Pending subscription created: ID={pending_sub.id}")
                
                payment_type = checkout_response.get('payment_type', 'mpesa_stk_push')
                
                return {
                    'success': True,
                    'provider': 'intasend',
                    'payment_type': payment_type,
                    'checkout_id': checkout_id,
                    'invoice_id': invoice_id,
                    'reference': reference,
                    'amount': amount,
                    'currency': currency,
                    'phone_number': checkout_response.get('phone_number'),
                    'message': checkout_response.get('message', 'Check your phone for M-Pesa prompt'),
                    'state': checkout_response.get('state', 'PENDING')
                }, 201
            
            else:
                # ===== PAYSTACK (CARD / BANK TRANSFER) =====
                if not paystack:
                    return {
                        'success': False,
                        'error': 'Paystack payment service is not available'
                    }, 503
                
                logging.info(f"Processing {payment_method} payment via Paystack")
                
                # Determine payment channels
                channels = ['card', 'bank', 'bank_transfer']
                if payment_method == 'bank_transfer':
                    channels = ['bank', 'bank_transfer']
                elif payment_method == 'card':
                    channels = ['card']
                
                # Create Paystack transaction
                checkout_response = paystack.initialize_transaction(
                    email=email,
                    amount=amount,
                    currency=currency,
                    reference=reference,
                    callback_url=redirect_url or f"{Config.BASE_URL}/payment-success",
                    channels=channels,
                    metadata={
                        'user_id': current_user.id,
                        'plan_id': plan_id,
                        'plan_name': plan.name,
                        'payment_method': payment_method
                    }
                )
                
                if not checkout_response.get('success'):
                    logging.error(f"Paystack error: {checkout_response.get('error')}")
                    return {
                        'success': False,
                        'error': f"Payment initialization failed: {checkout_response.get('error', 'Unknown error')}"
                    }, 400
                
                # Create pending subscription record
                access_code = checkout_response.get('access_code')
                
                pending_sub = Subscription(
                    user_id=current_user.id,
                    plan_id=plan.id,
                    plan_name=plan.name,
                    amount_paid=amount,
                    currency=currency,
                    payment_method=f'Paystack-{payment_method.title()}',
                    checkout_id=access_code,
                    payment_reference=reference,
                    start_date=datetime.utcnow(),
                    end_date=datetime.utcnow() + timedelta(days=plan.duration_days),
                    status='pending',
                    payment_status='pending'
                )
                db.session.add(pending_sub)
                db.session.commit()
                
                logging.info(f"✓ Pending subscription created: ID={pending_sub.id}")
                
                checkout_url = checkout_response.get('authorization_url')
                if not checkout_url:
                    return {
                        'success': False,
                        'error': 'Payment service did not return checkout URL'
                    }, 502
                
                return {
                    'success': True,
                    'provider': 'paystack',
                    'payment_type': 'web_checkout',
                    'checkout_url': checkout_url,
                    'access_code': access_code,
                    'reference': reference,
                    'amount': amount,
                    'currency': currency,
                    'message': 'Redirect user to checkout_url to complete payment'
                }, 201
            
        except ValueError as e:
            logging.error(f"Validation error: {str(e)}")
            return {'success': False, 'error': str(e)}, 400
        except Exception as e:
            logging.error(f"Unexpected error: {str(e)}", exc_info=True)
            db.session.rollback()
            return {'success': False, 'error': 'An unexpected error occurred during checkout creation'}, 500


# payments.py - Updated VerifyPayment Resource Class

@api.route('/verify/<string:reference>')
class VerifyPayment(Resource):
    @api.marshal_with(payment_verification_model)
    def post(self, reference):
        """
        Verify payment and activate subscription
        Works with both JWT and credential-based authentication
        Automatically detects provider from subscription record
        """
        if DEVELOPMENT_MODE:
            logging.warning("⚠️ DEVELOPMENT MODE: Subscription checks disabled")
        
        data = request.get_json() or {}
        
        current_user = None
        
        # Try JWT authentication
        auth_header = request.headers.get('Authorization', '')
        if auth_header.startswith('Bearer '):
            try:
                from flask_jwt_extended import verify_jwt_in_request, get_jwt_identity
                verify_jwt_in_request()
                user_id = get_jwt_identity()
                
                current_user = Advertiser.query.get(user_id) or User.query.get(user_id)
                
            except Exception as e:
                logging.warning(f"JWT verification failed: {e}")
        
        # Try credential authentication as fallback
        if not current_user:
            pending_email = data.get('pending_login_email')
            pending_password = data.get('pending_login_password')
            pending_user_type = data.get('pending_login_user_type', 'advertiser')
            
            if pending_email and pending_password:
                current_user = authenticate_with_credentials(
                    pending_email,
                    pending_password,
                    pending_user_type
                )
        
        if not current_user:
            return {
                'success': False,
                'status': 'error',
                'message': 'Authentication required'
            }, 401
        
        if not isinstance(current_user, Advertiser):
            return {
                'success': False,
                'status': 'error',
                'message': 'Only advertisers can verify subscriptions'
            }, 400
        
        try:
            logging.info(f"=== VERIFYING PAYMENT ===")
            logging.info(f"Reference: {reference}")
            logging.info(f"Advertiser: {current_user.email} (ID: {current_user.id})")
            
            # Get pending subscription
            pending_sub = Subscription.query.filter_by(
                payment_reference=reference,
                user_id=current_user.id
            ).first()
            
            if not pending_sub:
                logging.error(f"Subscription not found for reference: {reference}")
                return {
                    'success': False,
                    'status': 'error',
                    'message': 'Payment record not found'
                }, 404
            
            # Check if already completed
            if pending_sub.payment_status == 'completed':
                logging.info(f"Subscription already completed: ID={pending_sub.id}")
                return {
                    'success': True,
                    'status': 'complete',
                    'subscription_id': pending_sub.id,
                    'subscription': pending_sub.to_dict(),
                    'message': 'Subscription already activated. You can now login!'
                }
            
            # Determine provider from payment method
            payment_method = pending_sub.payment_method or ''
            if 'Paystack' in payment_method:
                provider = 'paystack'
            elif 'IntaSend' in payment_method:
                provider = 'intasend'
            else:
                # Fallback: try to determine from other fields
                if pending_sub.invoice_id:
                    provider = 'intasend'
                else:
                    provider = 'paystack'
            
            logging.info(f"Detected provider: {provider}")
            
            # Initialize services
            intasend, paystack = init_payment_services()
            
            if provider == 'intasend':
                # ===== VERIFY INTASEND PAYMENT =====
                if not intasend:
                    return {
                        'success': False,
                        'status': 'error',
                        'message': 'IntaSend service not available'
                    }, 503
                
                invoice_id = pending_sub.invoice_id
                checkout_id = pending_sub.checkout_id
                
                logging.info(f"Verifying IntaSend payment: invoice_id={invoice_id}, checkout_id={checkout_id}")
                
                # Try multiple verification methods
                verification_response = None
                
                # Try 1: Verify by invoice_id
                if invoice_id:
                    try:
                        verification_response = intasend.verify_payment(invoice_id=invoice_id)
                        if 'error' not in verification_response:
                            logging.info("✓ Verification successful with invoice_id")
                    except Exception as e:
                        logging.warning(f"Verification with invoice_id failed: {e}")
                
                # Try 2: Verify by api_ref
                if not verification_response or 'error' in verification_response:
                    try:
                        verification_response = intasend.verify_payment(api_ref=reference)
                        if 'error' not in verification_response:
                            logging.info("✓ Verification successful with api_ref")
                    except Exception as e:
                        logging.warning(f"Verification with api_ref failed: {e}")
                
                # Try 3: Verify by checkout_id
                if not verification_response or 'error' in verification_response:
                    if checkout_id:
                        try:
                            verification_response = intasend.verify_payment(checkout_id=checkout_id)
                            if 'error' not in verification_response:
                                logging.info("✓ Verification successful with checkout_id")
                        except Exception as e:
                            logging.warning(f"Verification with checkout_id failed: {e}")
                
                # Check if verification succeeded
                if not verification_response or 'error' in verification_response:
                    error_msg = verification_response.get('error') if verification_response else 'Unknown error'
                    logging.error(f"All IntaSend verification attempts failed: {error_msg}")
                    return {
                        'success': False,
                        'status': 'error',
                        'message': f'Unable to verify payment: {error_msg}'
                    }
                
                # Process verification result
                payment_status = verification_response.get('state', '').upper()
                logging.info(f"IntaSend payment status: {payment_status}")
                
                if payment_status in ['COMPLETE', 'COMPLETED', 'SUCCESS']:
                    # Payment successful - activate subscription
                    pending_sub.intasend_tracking_id = verification_response.get('mpesa_reference')
                    pending_sub.amount_paid = verification_response.get('value', pending_sub.amount_paid)
                    
                    # Activate subscription with all required fields
                    if activate_subscription(pending_sub):
                        return {
                            'success': True,
                            'status': 'complete',
                            'subscription_id': pending_sub.id,
                            'subscription': pending_sub.to_dict(),
                            'message': 'Payment successful! Your subscription is now active. You can login now!'
                        }
                    else:
                        return {
                            'success': False,
                            'status': 'error',
                            'message': 'Payment verified but subscription activation failed'
                        }, 500
                
                elif payment_status == 'PENDING':
                    return {
                        'success': False,
                        'status': 'pending',
                        'message': 'Payment is still processing. Please wait and try again in a few moments.'
                    }
                
                else:
                    return {
                        'success': False,
                        'status': 'failed',
                        'message': f'Payment failed with status: {payment_status}'
                    }
            
            else:
                # ===== VERIFY PAYSTACK PAYMENT =====
                if not paystack:
                    return {
                        'success': False,
                        'status': 'error',
                        'message': 'Paystack service not available'
                    }, 503
                
                logging.info(f"Verifying Paystack payment: reference={reference}")
                
                # Verify with Paystack
                verification_response = paystack.verify_transaction(reference)
                
                if not verification_response.get('success'):
                    error_msg = verification_response.get('error', 'Unknown error')
                    logging.error(f"Paystack verification failed: {error_msg}")
                    return {
                        'success': False,
                        'status': 'error',
                        'message': f'Unable to verify payment: {error_msg}'
                    }
                
                # Process verification result
                payment_status = verification_response.get('status', '').lower()
                logging.info(f"Paystack payment status: {payment_status}")
                
                if payment_status == 'success':
                    # Payment successful - activate subscription
                    pending_sub.amount_paid = verification_response.get('amount', pending_sub.amount_paid)
                    pending_sub.currency = verification_response.get('currency', pending_sub.currency)
                    
                    # Activate subscription with all required fields
                    if activate_subscription(pending_sub):
                        return {
                            'success': True,
                            'status': 'complete',
                            'subscription_id': pending_sub.id,
                            'subscription': pending_sub.to_dict(),
                            'message': 'Payment successful! Your subscription is now active. You can login now!'
                        }
                    else:
                        return {
                            'success': False,
                            'status': 'error',
                            'message': 'Payment verified but subscription activation failed'
                        }, 500
                
                elif payment_status == 'pending':
                    return {
                        'success': False,
                        'status': 'pending',
                        'message': 'Payment is still processing. Please wait and try again in a few moments.'
                    }
                
                else:
                    return {
                        'success': False,
                        'status': 'failed',
                        'message': f'Payment failed with status: {payment_status}'
                    }
                    
        except Exception as e:
            logging.error(f"Payment verification error: {str(e)}", exc_info=True)
            return {
                'success': False,
                'status': 'error',
                'message': 'An unexpected error occurred during verification'
            }, 500


def activate_subscription(subscription):
    """
    Properly activate a subscription with all required fields
    Sets next billing date to 3rd of next month
    Enables auto-renewal
    Sends activation email
    """
    from datetime import datetime, timedelta
    
    try:
        # Set subscription as active
        subscription.payment_status = 'completed'
        subscription.status = 'active'
        subscription.updated_at = datetime.utcnow()
        
        # Calculate next billing date (3rd of next month)
        subscription.next_billing_date = subscription.calculate_next_billing_date()
        
        # Enable auto-renewal by default
        subscription.auto_renew = True
        subscription.renewal_day = 3  # Always 3rd of the month
        
        # Reset reminder flags
        subscription.reminder_7days_sent = False
        subscription.reminder_3days_sent = False
        subscription.last_reminder_sent = None
        
        # Ensure start and end dates are set
        if not subscription.start_date:
            subscription.start_date = datetime.utcnow()
        
        if not subscription.end_date:
            # Get plan details to determine duration
            try:
                plan = SubscriptionPlans.get_plan_by_id(subscription.plan_id)
                subscription.end_date = subscription.start_date + timedelta(days=plan.duration_days)
            except:
                # Default to 30 days if plan not found
                subscription.end_date = subscription.start_date + timedelta(days=30)
        
        db.session.commit()
        
        logging.info(f"✓ Subscription activated: ID={subscription.id}")
        logging.info(f"  - Start date: {subscription.start_date}")
        logging.info(f"  - End date: {subscription.end_date}")
        logging.info(f"  - Next billing: {subscription.next_billing_date}")
        logging.info(f"  - Auto-renew: {subscription.auto_renew}")
        
        # Send welcome/activation email
        try:
            from models.advertiser import Advertiser
            from services.email_service import email_service
            
            advertiser = Advertiser.query.get(subscription.user_id)
            if advertiser:
                email_service.send_renewal_success(advertiser, subscription)
                logging.info(f"✓ Activation email sent to {advertiser.email}")
        except Exception as e:
            logging.warning(f"Failed to send activation email: {e}")
        
        return True
        
    except Exception as e:
        logging.error(f"Failed to activate subscription: {e}", exc_info=True)
        db.session.rollback()
        return False
        

@api.route('/subscription-status')
class SubscriptionStatus(Resource):
    def get(self):
        """Check current subscription status for authenticated advertiser"""
        if DEVELOPMENT_MODE:
            logging.warning("⚠️  DEVELOPMENT MODE: Returning dummy active subscription")
            return {
                'has_subscription': True,
                'is_advertiser': True,
                'development_mode': True,
                'subscription': {
                    'id': 0,
                    'plan_name': 'Development Mode - No Subscription Required',
                    'status': 'active',
                    'start_date': datetime.utcnow().isoformat(),
                    'end_date': (datetime.utcnow() + timedelta(days=365)).isoformat(),
                    'days_remaining': 365,
                    'payment_status': 'dev_mode'
                },
                'message': 'Development mode active - subscription checks disabled'
            }, 200
        
        current_user = None
        
        # Try JWT authentication
        auth_header = request.headers.get('Authorization', '')
        if auth_header.startswith('Bearer '):
            try:
                from flask_jwt_extended import verify_jwt_in_request, get_jwt_identity
                verify_jwt_in_request()
                user_id = get_jwt_identity()
                current_user = Advertiser.query.get(user_id) or User.query.get(user_id)
            except Exception as e:
                logging.warning(f"JWT verification failed: {e}")
        
        if not current_user:
            return {
                'has_subscription': False,
                'message': 'Authentication required'
            }, 401
        
        try:
            # Check if user is an advertiser
            if not isinstance(current_user, Advertiser):
                return {
                    'has_subscription': False,
                    'is_advertiser': False,
                    'message': 'Subscriptions are only for advertisers'
                }, 200
            
            # Get active subscription
            subscription = Subscription.query.filter_by(
                user_id=current_user.id,
                status='active'
            ).order_by(Subscription.end_date.desc()).first()
            
            if not subscription:
                return {
                    'has_subscription': False,
                    'is_advertiser': True,
                    'message': 'No active subscription found',
                    'status': 'no_subscription'
                }, 200
            
            # Check if subscription is expired
            now = datetime.utcnow()
            if subscription.end_date and subscription.end_date < now:
                subscription.status = 'expired'
                db.session.commit()
                
                return {
                    'has_subscription': False,
                    'is_advertiser': True,
                    'message': 'Subscription has expired',
                    'expired_at': subscription.end_date.isoformat(),
                    'status': 'expired'
                }, 200
            
            # Active subscription found
            days_remaining = (subscription.end_date - now).days if subscription.end_date else None
            
            return {
                'has_subscription': True,
                'is_advertiser': True,
                'subscription': {
                    'id': subscription.id,
                    'plan_name': subscription.plan_name,
                    'plan_id': subscription.plan_id,
                    'status': subscription.status,
                    'start_date': subscription.start_date.isoformat() if subscription.start_date else None,
                    'end_date': subscription.end_date.isoformat() if subscription.end_date else None,
                    'days_remaining': days_remaining,
                    'payment_status': subscription.payment_status,
                    'amount_paid': str(subscription.amount_paid) if subscription.amount_paid else None,
                    'currency': subscription.currency,
                    'payment_method': subscription.payment_method
                }
            }, 200
            
        except Exception as e:
            logging.error(f"Error checking subscription status: {str(e)}")
            return {
                'error': 'Failed to check subscription status'
            }, 500


@api.route('/my-subscriptions')
class MySubscriptions(Resource):
    @token_required
    def get(self, current_user):
        """Get all subscriptions for the current user"""
        try:
            if not isinstance(current_user, Advertiser):
                return {
                    'subscriptions': [],
                    'message': 'Only advertisers have subscriptions'
                }, 200
            
            subscriptions = Subscription.query.filter_by(
                user_id=current_user.id
            ).order_by(Subscription.created_at.desc()).all()
            
            return {
                'subscriptions': [sub.to_dict() for sub in subscriptions],
                'count': len(subscriptions)
            }, 200
            
        except Exception as e:
            logging.error(f"Error fetching subscriptions: {str(e)}")
            return {'error': 'Failed to fetch subscriptions'}, 500


@api.route('/webhook/intasend')
class IntaSendWebhook(Resource):
    def post(self):
        """Handle IntaSend payment webhooks"""
        try:
            data = request.get_json() or {}
            
            logging.info(f"=== IntaSend Webhook Received ===")
            logging.info(f"Data: {json.dumps(data, indent=2)}")
            
            # Verify webhook signature (implement according to IntaSend docs)
            event_type = data.get('event_type')
            payment_data = data.get('data', {})
            
            if event_type == 'COMPLETE':
                # Handle successful payment
                reference = payment_data.get('api_ref') or payment_data.get('reference', '')
                invoice_id = payment_data.get('invoice_id')
                
                logging.info(f"Payment completed: Reference={reference}, Invoice={invoice_id}")
                
                # Find and update subscription
                subscription = Subscription.query.filter_by(
                    payment_reference=reference
                ).first()
                
                if subscription and subscription.payment_status == 'pending':
                    subscription.payment_status = 'completed'
                    subscription.status = 'active'
                    subscription.intasend_tracking_id = payment_data.get('mpesa_reference')
                    db.session.commit()
                    
                    logging.info(f"✓ Subscription activated via webhook: {reference}")
            
            return {'status': 'received'}, 200
            
        except Exception as e:
            logging.error(f"IntaSend webhook error: {str(e)}")
            return {'status': 'error'}, 400


@api.route('/webhook/paystack')
class PaystackWebhook(Resource):
    def post(self):
        """Handle Paystack payment webhooks"""
        try:
            data = request.get_json() or {}
            
            logging.info(f"=== Paystack Webhook Received ===")
            logging.info(f"Event: {data.get('event')}")
            
            # Verify webhook signature
            signature = request.headers.get('X-Paystack-Signature')
            # TODO: Implement signature verification with Config.PAYSTACK_SECRET_KEY
            
            event = data.get('event')
            payment_data = data.get('data', {})
            
            if event == 'charge.success':
                reference = payment_data.get('reference')
                
                logging.info(f"Payment successful: Reference={reference}")
                
                # Find and update subscription
                subscription = Subscription.query.filter_by(
                    payment_reference=reference
                ).first()
                
                if subscription and subscription.payment_status == 'pending':
                    subscription.payment_status = 'completed'
                    subscription.status = 'active'
                    subscription.amount_paid = payment_data.get('amount', 0) / 100  # Convert from cents
                    db.session.commit()
                    
                    logging.info(f"✓ Subscription activated via webhook: {reference}")
            
            return {'status': 'success'}, 200
            
        except Exception as e:
            logging.error(f"Paystack webhook error: {str(e)}")
            return {'status': 'error'}, 400


@api.route('/exchange-rates')
class ExchangeRates(Resource):
    def get(self):
        """Get current exchange rates (mock implementation)"""
        base_currency = request.args.get('base', 'KES').upper()
        
        try:
            intasend, _ = init_payment_services()
            
            if intasend:
                rates = intasend.get_exchange_rates(base_currency)
            else:
                # Fallback mock rates
                rates = {
                    'KES': {
                        'USD': 0.0067,
                        'EUR': 0.0062,
                        'GBP': 0.0053,
                        'NGN': 11.5,
                        'GHS': 0.089,
                        'ZAR': 0.13,
                    },
                    'USD': {
                        'KES': 149.50,
                        'EUR': 0.92,
                        'GBP': 0.79,
                        'NGN': 1715.0,
                        'GHS': 13.2,
                        'ZAR': 19.3,
                    }
                }
                rates = rates.get(base_currency, {})
            
            return {
                'base_currency': base_currency,
                'rates': rates,
                'timestamp': datetime.utcnow().isoformat(),
                'note': 'Exchange rates are approximate and for reference only'
            }
        except Exception as e:
            logging.error(f"Exchange rate error: {str(e)}")
            return {'error': 'Failed to fetch exchange rates'}, 500


@api.route('/cancel-subscription/<int:subscription_id>')
class CancelSubscription(Resource):
    @token_required
    def post(self, current_user, subscription_id):
        """Cancel an active subscription"""
        try:
            subscription = Subscription.query.get(subscription_id)
            
            if not subscription:
                return {'error': 'Subscription not found'}, 404
            
            if subscription.user_id != current_user.id:
                return {'error': 'Not authorized to cancel this subscription'}, 403
            
            if subscription.status != 'active':
                return {'error': f'Cannot cancel subscription with status: {subscription.status}'}, 400
            
            # Cancel subscription
            subscription.status = 'cancelled'
            subscription.updated_at = datetime.utcnow()
            db.session.commit()
            
            logging.info(f"Subscription cancelled: ID={subscription_id}, User={current_user.id}")
            
            return {
                'success': True,
                'message': 'Subscription cancelled successfully',
                'subscription': subscription.to_dict()
            }, 200
            
        except Exception as e:
            logging.error(f"Error cancelling subscription: {str(e)}")
            return {'error': 'Failed to cancel subscription'}, 500


@api.route('/payment-methods')
class PaymentMethods(Resource):
    def get(self):
        """Get available payment methods for a specific currency"""
        currency = request.args.get('currency', 'KES').upper()
        
        methods = []
        
        # M-Pesa available for KES only
        if currency == 'KES':
            methods.append({
                'id': 'mpesa',
                'name': 'M-Pesa',
                'provider': 'intasend',
                'description': 'Pay with M-Pesa mobile money',
                'icon': 'phone',
                'requires_phone': True
            })
        
        # Card payment available for all currencies via Paystack
        if currency in ['KES', 'NGN', 'GHS', 'ZAR', 'USD']:
            methods.append({
                'id': 'card',
                'name': 'Debit/Credit Card',
                'provider': 'paystack',
                'description': 'Pay with Visa, Mastercard, or Verve',
                'icon': 'credit-card',
                'requires_phone': False
            })
        
        # Bank transfer available for supported currencies
        if currency in ['KES', 'NGN', 'GHS', 'ZAR']:
            methods.append({
                'id': 'bank_transfer',
                'name': 'Bank Transfer',
                'provider': 'paystack',
                'description': 'Transfer directly from your bank account',
                'icon': 'bank',
                'requires_phone': False
            })
        
        return {
            'currency': currency,
            'methods': methods,
            'count': len(methods)
        }


# Initialize payment services on module load
try:
    init_payment_services()
except Exception as e:
    logging.error(f"Failed to initialize payment services on startup: {e}")