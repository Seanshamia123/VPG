# payments.py - Complete fixed payment endpoints with full subscription flow
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
DEVELOPMENT_MODE = True  # Set to False to re-enable subscription checks
# ============================================

# Import IntaSend service with error handling
try:
    from .intasend_service import IntaSendService, SubscriptionPlans
except ImportError as e:
    logging.error(f"Failed to import IntaSend service: {e}")
    # Create a dummy class to prevent startup errors during development
    class IntaSendService:
        def __init__(self, *args, **kwargs):
            pass
        def create_checkout_session(self, *args, **kwargs):
            return {"error": "IntaSend service not configured"}
        def verify_payment(self, *args, **kwargs):
            return {"error": "IntaSend service not configured"}
        def get_supported_currencies(self):
            return []
        def get_exchange_rates(self, base_currency="KES"):
            return {}
    
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

api = Namespace('payment', description='Payment management with IntaSend')

# Initialize IntaSend service once at module level
intasend_service = None

def init_intasend_service():
    """Initialize IntaSend service with config"""
    global intasend_service
    if intasend_service is None:
        try:
            intasend_service = IntaSendService(
                publishable_key=Config.INTASEND_PUBLISHABLE_KEY,
                secret_key=Config.INTASEND_SECRET_KEY,
                is_test=Config.INTASEND_IS_TEST
            )
            logging.info("=== IntaSend Service Initialized ===")
            logging.info(f"Publishable Key: {Config.INTASEND_PUBLISHABLE_KEY[:20]}...")
            logging.info(f"Secret Key: {Config.INTASEND_SECRET_KEY[:20]}...")
            logging.info(f"Is Test: {Config.INTASEND_IS_TEST}")
        except Exception as e:
            logging.error(f"Failed to initialize IntaSend service: {e}")
    return intasend_service


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
    'plan_id': fields.String(required=True, description='Subscription plan ID'),
    'currency': fields.String(required=True, description='Payment currency (KES, USD, EUR)'),
    'phone_number': fields.String(required=False, description='Phone number for M-Pesa payments'),
    'redirect_url': fields.String(required=False, description='URL to redirect after payment'),
    'card_number': fields.String(required=False, description='Card number for card payments'),
    'card_expiry': fields.String(required=False, description='Card expiry (MMYY)'),
    'card_cvc': fields.String(required=False, description='Card CVC'),
    'card_holder_name': fields.String(required=False, description='Name on card'),
    'country': fields.String(required=False, description='Country code'),
    'email': fields.String(required=False, description='Email address'),
    'pending_login_email': fields.String(required=False, description='Email for credential auth'),
    'pending_login_password': fields.String(required=False, description='Password for credential auth'),
    'pending_login_user_type': fields.String(required=False, description='User type for credential auth'),
})

checkout_response_model = api.model('CheckoutResponse', {
    'success': fields.Boolean(description='Success status'),
    'payment_type': fields.String(description='Type of payment (mpesa_stk_push, card_direct, web_checkout)'),
    'checkout_url': fields.String(description='IntaSend checkout URL'),
    'checkout_id': fields.String(description='Checkout session ID'),
    'invoice_id': fields.String(description='Invoice ID'),
    'amount': fields.Float(description='Payment amount'),
    'currency': fields.String(description='Payment currency'),
    'reference': fields.String(description='Payment reference'),
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
    'status': fields.String(description='Payment status'),
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
        """Get supported currencies for payments"""
        service = init_intasend_service()
        if not service:
            api.abort(500, "Payment service not available")
        
        currencies = service.get_supported_currencies()
        return {'currencies': currencies}


@api.route('/create-checkout')
class CreateCheckout(Resource):
    @api.expect(payment_request_model)
    def post(self):
        """
        CRITICAL FIX: Create checkout session
        Supports both:
        1. JWT authenticated users (normal flow)
        2. Users with credentials during subscription signup
        """
        if DEVELOPMENT_MODE:
            logging.warning("⚠️  DEVELOPMENT MODE: Subscription checks disabled")
        
        data = request.get_json() or {}
        
        print("\n=== CREATE CHECKOUT REQUEST ===")
        print(f"Headers: {dict(request.headers)}")
        print(f"Body keys: {data.keys()}")
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
                'error': 'Authentication required'
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
        phone_number = data.get('phone_number')
        redirect_url = data.get('redirect_url')
        
        # Card details
        card_number = data.get('card_number')
        card_expiry = data.get('card_expiry')
        card_cvc = data.get('card_cvc')
        card_holder_name = data.get('card_holder_name')
        country = data.get('country')
        
        email = data.get('email') or current_user.email
        
        if not plan_id:
            return {'success': False, 'error': 'Plan ID is required'}, 400
        
        try:
            # Get plan details
            plan = SubscriptionPlans.get_plan_by_id(plan_id)
            amount = SubscriptionPlans.get_plan_price(plan_id, currency)
            amount = round(float(amount), 2)
            
            # Generate unique reference
            reference = f"SUB_{current_user.id}_{plan_id}_{uuid.uuid4().hex[:8].upper()}"
            
            # Initialize IntaSend service
            service = init_intasend_service()
            if not service:
                return {'success': False, 'error': 'Payment service not available'}, 503
            
            logging.info(f"\n=== CREATING INTASEND CHECKOUT ===")
            logging.info(f"Advertiser: {current_user.email} (ID: {current_user.id})")
            logging.info(f"Amount: {amount} {currency}")
            logging.info(f"Reference: {reference}")
            logging.info(f"Is Pending Login: {is_pending_login}")
            logging.info(f"Phone: {phone_number}")
            logging.info(f"Country: {country}")
            
            # Get customer name
            customer_name = (current_user.name or '').split(' ', 1)
            first_name = customer_name[0] if customer_name else ''
            last_name = customer_name[1] if len(customer_name) > 1 else ''
            
            # Create checkout session
            checkout_response = service.create_checkout_session(
                amount=amount,
                currency=currency,
                email=email,
                phone_number=phone_number,
                first_name=first_name,
                last_name=last_name,
                redirect_url=redirect_url or f"{Config.BASE_URL}/payment-success",
                webhook_url=f"{Config.BASE_URL}/api/payment/webhook",
                reference=reference,
                card_number=card_number,
                card_expiry=card_expiry,
                card_cvc=card_cvc,
                card_holder_name=card_holder_name,
                country=country
            )
            
            if 'error' in checkout_response:
                logging.error(f"IntaSend error: {checkout_response['error']}")
                return {
                    'success': False,
                    'error': f"Payment creation failed: {checkout_response['error']}"
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
                payment_method='IntaSend',
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
            
            # Prepare response based on payment type
            payment_type = checkout_response.get('payment_type', 'web_checkout')
            
            response_data = {
                'success': True,
                'payment_type': payment_type,
                'checkout_id': checkout_id,
                'invoice_id': invoice_id,
                'amount': amount,
                'currency': currency,
                'reference': reference,
            }
            
            if payment_type == 'mpesa_stk_push':
                response_data.update({
                    'checkout_url': None,
                    'phone_number': checkout_response.get('phone_number'),
                    'message': checkout_response.get('message', 'Check your phone for M-Pesa prompt'),
                    'state': checkout_response.get('state', 'PENDING')
                })
            elif payment_type == 'card_direct':
                response_data.update({
                    'checkout_url': None,
                    'state': checkout_response.get('state', 'COMPLETE'),
                    'message': checkout_response.get('message')
                })
            else:
                checkout_url = checkout_response.get('checkout_url')
                if not checkout_url:
                    return {
                        'success': False,
                        'error': 'Payment service did not return checkout URL'
                    }, 502
                response_data['checkout_url'] = checkout_url
            
            logging.info(f"✓ Checkout response prepared")
            return response_data, 201
            
        except ValueError as e:
            logging.error(f"Validation error: {str(e)}")
            return {'success': False, 'error': str(e)}, 400
        except Exception as e:
            logging.error(f"Unexpected error: {str(e)}", exc_info=True)
            db.session.rollback()
            return {'success': False, 'error': 'An unexpected error occurred'}, 500


@api.route('/verify/<string:checkout_id>')
class VerifyPayment(Resource):
    def post(self, checkout_id):
        """
        Verify payment and create subscription
        CRITICAL: Can work with or without JWT token
        """
        if DEVELOPMENT_MODE:
            logging.warning("⚠️  DEVELOPMENT MODE: Subscription checks disabled")
        
        data = request.get_json() or {}
        
        current_user = None
        
        # Try JWT auth
        auth_header = request.headers.get('Authorization', '')
        if auth_header.startswith('Bearer '):
            try:
                from flask_jwt_extended import verify_jwt_in_request, get_jwt_identity
                verify_jwt_in_request()
                user_id = get_jwt_identity()
                
                current_user = Advertiser.query.get(user_id) or User.query.get(user_id)
                
            except Exception as e:
                logging.warning(f"JWT verification failed: {e}")
        
        # Try credential auth as fallback
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
            service = init_intasend_service()
            if not service:
                return {
                    'success': False,
                    'status': 'error',
                    'message': 'Payment service not available'
                }, 503
            
            logging.info(f"=== VERIFYING PAYMENT ===")
            logging.info(f"Checkout ID: {checkout_id}")
            logging.info(f"Advertiser: {current_user.email}")
            
            # Get pending subscription
            pending_sub = Subscription.query.filter_by(
                user_id=current_user.id,
                checkout_id=checkout_id,
                payment_status='pending'
            ).first()
            
            invoice_id = None
            api_ref = None
            
            if pending_sub:
                invoice_id = pending_sub.invoice_id
                api_ref = pending_sub.payment_reference
                logging.info(f"Found pending subscription: invoice_id={invoice_id}, api_ref={api_ref}")
            
            # Try verification with different identifiers
            verification_response = None
            
            # Try 1: Verify by invoice_id
            if invoice_id:
                try:
                    logging.info(f"Attempting verification with invoice_id: {invoice_id}")
                    verification_response = service.verify_payment(invoice_id=invoice_id)
                    if 'error' not in verification_response:
                        logging.info("Verification successful with invoice_id")
                except Exception as e:
                    logging.warning(f"Verification with invoice_id failed: {e}")
            
            # Try 2: Verify by api_ref
            if not verification_response or 'error' in verification_response:
                if api_ref:
                    try:
                        logging.info(f"Attempting verification with api_ref: {api_ref}")
                        verification_response = service.verify_payment(api_ref=api_ref)
                        if 'error' not in verification_response:
                            logging.info("Verification successful with api_ref")
                    except Exception as e:
                        logging.warning(f"Verification with api_ref failed: {e}")
            
            # Try 3: Verify by checkout_id
            if not verification_response or 'error' in verification_response:
                try:
                    logging.info(f"Attempting verification with checkout_id: {checkout_id}")
                    verification_response = service.verify_payment(checkout_id=checkout_id)
                    if 'error' not in verification_response:
                        logging.info("Verification successful with checkout_id")
                except Exception as e:
                    logging.warning(f"Verification with checkout_id failed: {e}")
            
            # If all verification attempts failed
            if not verification_response or 'error' in verification_response:
                error_msg = verification_response.get('error') if verification_response else 'Unknown error'
                logging.error(f"All verification attempts failed: {error_msg}")
                return {
                    'success': False,
                    'status': 'error',
                    'message': f"Unable to verify payment. Please contact support with reference: {checkout_id}"
                }
            
            # Process verification response
            payment_status = verification_response.get('state', '').upper()
            logging.info(f"Payment status: {payment_status}")
            
            if payment_status in ['COMPLETE', 'COMPLETED', 'SUCCESS']:
                # Extract payment details
                reference = verification_response.get('reference', '')
                api_ref = verification_response.get('api_ref', reference)
                amount = verification_response.get('value', 0)
                currency = verification_response.get('currency', 'KES')
                mpesa_ref = verification_response.get('mpesa_reference')
                invoice_id_from_response = verification_response.get('invoice_id')
                
                logging.info(f"Payment completed - Amount: {amount} {currency}, Reference: {api_ref}")
                
                # Extract plan ID from reference (format: SUB_{user_id}_{plan_id}_{uuid})
                try:
                    ref_parts = api_ref.split('_')
                    if len(ref_parts) >= 3 and ref_parts[0] == 'SUB':
                        plan_id = ref_parts[2]
                        plan = SubscriptionPlans.get_plan_by_id(plan_id)
                        
                        # Check if subscription already exists
                        existing_sub = Subscription.query.filter_by(
                            user_id=current_user.id,
                            payment_reference=api_ref,
                            payment_status='completed'
                        ).first()
                        
                        if existing_sub:
                            logging.info(f"Subscription already exists: ID={existing_sub.id}")
                            return {
                                'success': True,
                                'status': 'complete',
                                'subscription_id': existing_sub.id,
                                'message': 'Subscription already activated. You can now login!'
                            }
                        
                        # Create or update subscription
                        if pending_sub:
                            subscription = pending_sub
                            subscription.payment_status = 'completed'
                            subscription.status = 'active'
                            subscription.amount_paid = amount
                            subscription.currency = currency
                            subscription.intasend_tracking_id = mpesa_ref
                            subscription.invoice_id = invoice_id_from_response or invoice_id
                            subscription.updated_at = datetime.utcnow()
                            logging.info(f"Updated pending subscription: ID={subscription.id}")
                        else:
                            start_date = datetime.utcnow()
                            end_date = start_date + timedelta(days=plan.duration_days)
                            
                            subscription = Subscription(
                                user_id=current_user.id,
                                plan_id=plan.id,
                                plan_name=plan.name,
                                amount_paid=amount,
                                currency=currency,
                                payment_method='IntaSend',
                                checkout_id=checkout_id,
                                payment_reference=api_ref,
                                intasend_tracking_id=mpesa_ref,
                                invoice_id=invoice_id_from_response,
                                start_date=start_date,
                                end_date=end_date,
                                status='active',
                                payment_status='completed'
                            )
                            db.session.add(subscription)
                            logging.info(f"Created new subscription for advertiser {current_user.id}")
                        
                        db.session.commit()
                        
                        logging.info(f"✓ Subscription saved: ID={subscription.id}, Advertiser={current_user.id}, Plan={plan.name}")
                        
                        return {
                            'success': True,
                            'status': 'complete',
                            'subscription_id': subscription.id,
                            'message': 'Payment successful! Your advertiser account is now active. You can login now!'
                        }
                    else:
                        logging.error(f"Invalid reference format: {api_ref}")
                        return {
                            'success': False,
                            'status': 'error',
                            'message': 'Invalid payment reference format'
                        }
                except Exception as e:
                    logging.error(f"Subscription creation error: {str(e)}", exc_info=True)
                    db.session.rollback()
                    return {
                        'success': False,
                        'status': 'error',
                        'message': f'Failed to create subscription: {str(e)}'
                    }
            
            elif payment_status == 'PENDING':
                return {
                    'success': False,
                    'status': 'pending',
                    'message': 'Payment is still processing. Please wait and try again.'
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


@api.route('/subscription-status')
class SubscriptionStatus(Resource):
    def get(self):
        """Check current subscription status for advertiser"""
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
        
        # Try JWT auth
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
            
            # Active subscription
            days_remaining = (subscription.end_date - now).days if subscription.end_date else None
            
            return {
                'has_subscription': True,
                'is_advertiser': True,
                'subscription': {
                    'id': subscription.id,
                    'plan_name': subscription.plan_name,
                    'status': subscription.status,
                    'start_date': subscription.start_date.isoformat() if subscription.start_date else None,
                    'end_date': subscription.end_date.isoformat() if subscription.end_date else None,
                    'days_remaining': days_remaining,
                    'payment_status': subscription.payment_status
                }
            }, 200
            
        except Exception as e:
            logging.error(f"Error checking subscription status: {str(e)}")
            return {
                'error': 'Failed to check subscription status'
            }, 500


@api.route('/webhook')
class PaymentWebhook(Resource):
    def post(self):
        """Handle IntaSend payment webhooks"""
        try:
            data = request.get_json() or {}
            
            # Verify webhook signature (implement according to IntaSend docs)
            event_type = data.get('event_type')
            payment_data = data.get('data', {})
            
            if event_type == 'COMPLETE':
                # Handle successful payment
                reference = payment_data.get('reference', '')
                checkout_id = payment_data.get('id')
                
                logging.info(f"Payment completed: {checkout_id}, Reference: {reference}")
            
            return {'status': 'received'}, 200
            
        except Exception as e:
            logging.error(f"Webhook processing error: {str(e)}")
            return {'status': 'error'}, 400


@api.route('/exchange-rates')
class ExchangeRates(Resource):
    def get(self):
        """Get current exchange rates"""
        base_currency = request.args.get('base', 'KES').upper()
        
        try:
            service = init_intasend_service()
            if not service:
                return {'error': 'Payment service not available'}, 503
            
            rates = service.get_exchange_rates(base_currency)
            
            return {
                'base_currency': base_currency,
                'rates': rates,
                'timestamp': datetime.utcnow().isoformat()
            }
        except Exception as e:
            logging.error(f"Exchange rate error: {str(e)}")
            return {'error': 'Failed to fetch exchange rates'}, 500