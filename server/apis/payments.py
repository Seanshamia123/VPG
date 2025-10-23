# payments.py - Complete fixed payment endpoints with card payment support
import sys
import os
from flask import request, jsonify, current_app
from flask_restx import Namespace, Resource, fields
from datetime import datetime, timedelta
import uuid
import logging

# Add the parent directory to the Python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from models import Subscription, User, db
from .decorators import token_required
from config import Config  # Import Config directly

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

api = Namespace('payments', description='Payment management with IntaSend')

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
})

checkout_response_model = api.model('CheckoutResponse', {
    'success': fields.Boolean(description='Success status'),
    'checkout_url': fields.String(description='IntaSend checkout URL'),
    'checkout_id': fields.String(description='Checkout session ID'),
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

# payments.py - Fixed payment endpoints with country support
# Update only the CreateCheckout resource's post method

# ... (keep all your existing imports and setup code) ...

@api.route('/create-checkout')
class CreateCheckout(Resource):
    @api.expect(payment_request_model)
    @token_required
    def post(self, current_user):
        """Create IntaSend checkout session for subscription payment"""
        data = request.get_json() or {}
        
        # Validate required fields
        plan_id = data.get('plan_id')
        currency = data.get('currency', 'KES').upper()
        phone_number = data.get('phone_number')
        redirect_url = data.get('redirect_url')
        
        # Extract card details from request
        card_number = data.get('card_number')
        card_expiry = data.get('card_expiry')  # Should be MMYY format
        card_cvc = data.get('card_cvc')
        card_holder_name = data.get('card_holder_name')
        
        # Extract country (optional, will be auto-determined if not provided)
        country = data.get('country')
        
        if not plan_id:
            return {'error': 'Plan ID is required'}, 400
        
        try:
            # Get plan details
            plan = SubscriptionPlans.get_plan_by_id(plan_id)
            amount = SubscriptionPlans.get_plan_price(plan_id, currency)
            
            # CRITICAL FIX: Round amount to 2 decimal places
            amount = round(float(amount), 2)
            
            # Generate unique reference
            reference = f"SUB_{current_user.id}_{plan_id}_{uuid.uuid4().hex[:8].upper()}"
            
            # Get IntaSend service
            service = init_intasend_service()
            if not service:
                return {'error': 'Payment service not available'}, 503
            
            logging.info(f"=== Creating Checkout ===")
            logging.info(f"Amount: {amount} {currency}")
            logging.info(f"User: {current_user.email}")
            logging.info(f"Reference: {reference}")
            logging.info(f"Phone: {phone_number}")
            logging.info(f"Country: {country}")
            logging.info(f"Has card details: {bool(card_number and card_expiry and card_cvc)}")
            
            # Prepare customer info
            customer_name = getattr(current_user, 'name', '').split(' ', 1)
            first_name = customer_name[0] if customer_name else ''
            last_name = customer_name[1] if len(customer_name) > 1 else ''
            
            # Create checkout session with card details and country if provided
            checkout_response = service.create_checkout_session(
                amount=amount,
                currency=currency,
                email=current_user.email,
                phone_number=phone_number,
                first_name=first_name,
                last_name=last_name,
                redirect_url=redirect_url or f"{Config.BASE_URL}/payment-success",
                webhook_url=f"{Config.BASE_URL}/api/payment/webhook",
                reference=reference,
                # Pass card details to IntaSend service
                card_number=card_number,
                card_expiry=card_expiry,
                card_cvc=card_cvc,
                card_holder_name=card_holder_name,
                country=country  # Pass country (will be auto-determined if None)
            )
            
            # Check for errors in response
            if 'error' in checkout_response:
                logging.error(f"IntaSend checkout creation failed: {checkout_response['error']}")
                return {
                    'success': False,
                    'error': f"Payment creation failed: {checkout_response['error']}"
                }, 400
            
            # Handle different payment types
            payment_type = checkout_response.get('payment_type', 'web_checkout')
            
            if payment_type == 'mpesa_stk_push':
                # M-Pesa STK Push - no URL needed
                return {
                    'success': True,
                    'payment_type': 'mpesa_stk_push',
                    'checkout_url': None,
                    'checkout_id': checkout_response.get('checkout_id'),
                    'invoice_id': checkout_response.get('invoice_id'),
                    'amount': amount,
                    'currency': currency,
                    'reference': reference,
                    'phone_number': checkout_response.get('phone_number'),
                    'message': checkout_response.get('message', 'Please check your phone for M-Pesa prompt'),
                    'state': checkout_response.get('state', 'PENDING')
                }, 201
            elif payment_type == 'card_direct':
                # Card payment processed directly
                return {
                    'success': True,
                    'payment_type': 'card_direct',
                    'checkout_url': None,
                    'checkout_id': checkout_response.get('checkout_id'),
                    'invoice_id': checkout_response.get('invoice_id'),
                    'amount': amount,
                    'currency': currency,
                    'reference': reference,
                    'state': checkout_response.get('state', 'COMPLETE'),
                    'message': checkout_response.get('message', 'Card payment processed successfully')
                }, 201
            else:
                # Web checkout (card payment via hosted page)
                checkout_url = checkout_response.get('checkout_url')
                if not checkout_url:
                    logging.error(f"IntaSend response missing URL: {checkout_response}")
                    return {
                        'success': False,
                        'error': 'Payment service did not return checkout URL'
                    }, 502
                
                return {
                    'success': True,
                    'payment_type': 'web_checkout',
                    'checkout_url': checkout_url,
                    'checkout_id': checkout_response.get('checkout_id'),
                    'invoice_id': checkout_response.get('invoice_id'),
                    'amount': amount,
                    'currency': currency,
                    'reference': reference,
                }, 201
            
        except ValueError as e:
            logging.error(f"Validation error in payment creation: {str(e)}")
            return {'error': str(e)}, 400
        except Exception as e:
            logging.error(f"Unexpected error in payment creation: {str(e)}", exc_info=True)
            return {'error': 'An unexpected error occurred while creating payment'}, 500
@api.route('/verify/<string:checkout_id>')
class VerifyPayment(Resource):
    @api.marshal_with(payment_verification_model)
    @token_required
    def post(self, current_user, checkout_id):
        """Verify payment and create subscription if successful"""
        try:
            # Get IntaSend service
            service = init_intasend_service()
            if not service:
                return {
                    'success': False,
                    'status': 'error',
                    'message': 'Payment service not available'
                }, 503
            
            logging.info(f"=== VERIFYING PAYMENT ===")
            logging.info(f"Checkout ID: {checkout_id}")
            logging.info(f"User ID: {current_user.id}")
            
            # For M-Pesa payments, we need to check using invoice_id or api_ref
            # First, try to find any pending subscription for this user with this checkout_id
            pending_subscription = Subscription.query.filter_by(
                user_id=current_user.id,
                checkout_id=checkout_id,
                payment_status='pending'
            ).first()
            
            # Extract invoice_id or api_ref if we have it from the pending subscription
            invoice_id = None
            api_ref = None
            
            if pending_subscription:
                invoice_id = pending_subscription.invoice_id
                api_ref = pending_subscription.payment_reference
                logging.info(f"Found pending subscription: invoice_id={invoice_id}, api_ref={api_ref}")
            
            # Try verification with different identifiers
            verification_response = None
            verification_error = None
            
            # Try 1: Verify by invoice_id if available
            if invoice_id:
                try:
                    logging.info(f"Attempting verification with invoice_id: {invoice_id}")
                    verification_response = service.verify_payment(invoice_id=invoice_id)
                    if 'error' not in verification_response:
                        logging.info("Verification successful with invoice_id")
                except Exception as e:
                    logging.warning(f"Verification with invoice_id failed: {e}")
                    verification_error = str(e)
            
            # Try 2: Verify by api_ref if invoice_id didn't work
            if not verification_response or 'error' in verification_response:
                if api_ref:
                    try:
                        logging.info(f"Attempting verification with api_ref: {api_ref}")
                        verification_response = service.verify_payment(api_ref=api_ref)
                        if 'error' not in verification_response:
                            logging.info("Verification successful with api_ref")
                    except Exception as e:
                        logging.warning(f"Verification with api_ref failed: {e}")
                        verification_error = str(e)
            
            # Try 3: Last resort - try with checkout_id (may not work for M-Pesa)
            if not verification_response or 'error' in verification_response:
                try:
                    logging.info(f"Attempting verification with checkout_id: {checkout_id}")
                    verification_response = service.verify_payment(checkout_id=checkout_id)
                    if 'error' not in verification_response:
                        logging.info("Verification successful with checkout_id")
                except Exception as e:
                    logging.warning(f"Verification with checkout_id failed: {e}")
                    verification_error = str(e)
            
            # If all verification attempts failed
            if not verification_response or 'error' in verification_response:
                error_msg = verification_response.get('error') if verification_response else verification_error
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
                                'message': 'Subscription already activated'
                            }
                        
                        # Create or update subscription
                        if pending_subscription:
                            # Update existing pending subscription
                            subscription = pending_subscription
                            subscription.payment_status = 'completed'
                            subscription.status = 'active'
                            subscription.amount_paid = amount
                            subscription.currency = currency
                            subscription.intasend_tracking_id = mpesa_ref
                            subscription.invoice_id = invoice_id_from_response or invoice_id
                            subscription.updated_at = datetime.utcnow()
                            logging.info(f"Updated pending subscription: ID={subscription.id}")
                        else:
                            # Create new subscription
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
                            logging.info(f"Created new subscription for user {current_user.id}")
                        
                        db.session.commit()
                        
                        logging.info(f"✓ Subscription saved: ID={subscription.id}, User={current_user.id}, Plan={plan.name}")
                        
                        return {
                            'success': True,
                            'status': 'complete',
                            'subscription_id': subscription.id,
                            'message': 'Payment successful and subscription activated'
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
               
@api.route('/webhook')
class PaymentWebhook(Resource):
    def post(self):
        """Handle IntaSend payment webhooks"""
        try:
            data = request.get_json() or {}
            
            # Verify webhook signature (implement according to IntaSend docs)
            # This is a simplified version - add proper signature verification
            
            event_type = data.get('event_type')
            payment_data = data.get('data', {})
            
            if event_type == 'COMPLETE':
                # Handle successful payment
                reference = payment_data.get('reference', '')
                checkout_id = payment_data.get('id')
                
                # Process the payment asynchronously
                # You might want to use Celery or similar for background processing
                
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