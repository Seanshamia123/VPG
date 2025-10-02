# payments.py - Fixed payment endpoints
import sys
import os
from flask import request, jsonify, current_app
from flask_restx import Namespace, Resource, fields
from datetime import datetime, timedelta
import uuid
import logging
# from intasend_service import IntaSendService
# Add the parent directory to the Python path to find intasend_service
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from models import Subscription, User, db
from .decorators import token_required

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

# Models for API documentation
payment_request_model = api.model('PaymentRequest', {
    'plan_id': fields.String(required=True, description='Subscription plan ID'),
    'currency': fields.String(required=True, description='Payment currency (KES, USD, EUR)'),
    'phone_number': fields.String(required=False, description='Phone number for M-Pesa payments'),
    'redirect_url': fields.String(required=False, description='URL to redirect after payment'),
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

def get_intasend_service():
    """Get configured IntaSend service instance"""
    try:
        return IntaSendService(
            publishable_key=current_app.config.get('INTASEND_PUBLISHABLE_KEY', ''),
            secret_key=current_app.config.get('INTASEND_SECRET_KEY', ''),
            is_test=current_app.config.get('INTASEND_IS_TEST')
        )
    except Exception as e:
        logging.error(f"Failed to initialize IntaSend service: {e}")
        return None

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
        intasend = get_intasend_service()
        if not intasend:
            api.abort(500, "Payment service not available")
        
        currencies = intasend.get_supported_currencies()
        return {'currencies': currencies}

@api.route('/create-checkout')
class CreateCheckout(Resource):
    @api.expect(payment_request_model)
    @api.marshal_with(checkout_response_model, code=201)
    @token_required
    def post(self, current_user):
        """Create IntaSend checkout session for subscription payment"""
        data = request.get_json() or {}
        
        # Validate required fields
        plan_id = data.get('plan_id')
        currency = data.get('currency', 'KES').upper()
        phone_number = data.get('phone_number')
        redirect_url = data.get('redirect_url')
        
        if not plan_id:
            return {'error': 'Plan ID is required'}, 400
        
        try:
            # Get plan details
            plan = SubscriptionPlans.get_plan_by_id(plan_id)
            amount = SubscriptionPlans.get_plan_price(plan_id, currency)
            
            # Generate unique reference
            reference = f"SUB_{current_user.id}_{plan_id}_{uuid.uuid4().hex[:8].upper()}"
            
            # Get IntaSend service
            intasend = get_intasend_service()
            if not intasend:
                return {'error': 'Payment service not available'}, 503
            
            # Prepare customer info
            customer_name = getattr(current_user, 'name', '').split(' ', 1)
            first_name = customer_name[0] if customer_name else ''
            last_name = customer_name[1] if len(customer_name) > 1 else ''
            
            # Create checkout session
            checkout_response = intasend.create_checkout_session(
                amount=amount,
                currency=currency,
                email=current_user.email,
                phone_number=phone_number,
                first_name=first_name,
                last_name=last_name,
                redirect_url=redirect_url or f"{current_app.config.get('BASE_URL', '')}/payment-success",
                webhook_url=f"{current_app.config.get('BASE_URL', '')}/api/payments/webhook",
                reference=reference
            )
            
            # Check for errors in response
            if 'error' in checkout_response:
                logging.error(f"IntaSend checkout creation failed: {checkout_response['error']}")
                return {
                    'success': False,
                    'error': f"Payment creation failed: {checkout_response['error']}"
                }, 400
            
            # Validate required fields in response
            if not checkout_response.get('url') and not checkout_response.get('checkout_url'):
                logging.error(f"IntaSend response missing URL: {checkout_response}")
                return {
                    'success': False,
                    'error': 'Payment service did not return checkout URL'
                }, 502
            
            # Store payment reference for later verification
            # You might want to create a PendingPayment model to track this
            
            return {
                'success': True,
                'checkout_url': checkout_response.get('url') or checkout_response.get('checkout_url'),
                'checkout_id': checkout_response.get('id') or checkout_response.get('checkout_id'),
                'amount': amount,
                'currency': currency,
                'reference': reference,
            }, 201
            
        except ValueError as e:
            logging.error(f"Validation error in payment creation: {str(e)}")
            return {'error': str(e)}, 400
        except Exception as e:
            logging.error(f"Unexpected error in payment creation: {str(e)}")
            return {'error': 'An unexpected error occurred while creating payment'}, 500

@api.route('/verify/<string:checkout_id>')
class VerifyPayment(Resource):
    @api.marshal_with(payment_verification_model)
    @token_required
    def post(self, current_user, checkout_id):
        """Verify payment and create subscription if successful"""
        try:
            # Get IntaSend service
            intasend = get_intasend_service()
            if not intasend:
                return {
                    'success': False,
                    'status': 'error',
                    'message': 'Payment service not available'
                }, 503
            
            # Verify payment with IntaSend
            verification_response = intasend.verify_payment(checkout_id)
            
            if 'error' in verification_response:
                logging.error(f"Payment verification failed: {verification_response['error']}")
                return {
                    'success': False,
                    'status': 'error',
                    'message': f"Verification failed: {verification_response['error']}"
                }
            
            payment_status = verification_response.get('state', '').upper()
            
            if payment_status == 'COMPLETE':
                # Extract payment details
                reference = verification_response.get('reference', '')
                amount = verification_response.get('value', 0)
                currency = verification_response.get('currency', 'KES')
                
                # Extract plan ID from reference (format: SUB_{user_id}_{plan_id}_{uuid})
                try:
                    ref_parts = reference.split('_')
                    if len(ref_parts) >= 3 and ref_parts[0] == 'SUB':
                        plan_id = ref_parts[2]
                        plan = SubscriptionPlans.get_plan_by_id(plan_id)
                        
                        # Create subscription
                        start_date = datetime.utcnow()
                        end_date = start_date + timedelta(days=plan.duration_days)
                        
                        subscription = Subscription(
                            user_id=current_user.id,
                            amount_paid=amount,
                            payment_method='IntaSend',
                            start_date=start_date,
                            end_date=end_date,
                            status='active'
                        )
                        
                        db.session.add(subscription)
                        db.session.commit()
                        
                        return {
                            'success': True,
                            'status': 'complete',
                            'subscription_id': subscription.id,
                            'message': 'Payment successful and subscription activated'
                        }
                    else:
                        logging.error(f"Invalid reference format: {reference}")
                        return {
                            'success': False,
                            'status': 'error',
                            'message': 'Invalid payment reference format'
                        }
                except Exception as e:
                    logging.error(f"Subscription creation error: {str(e)}")
                    return {
                        'success': False,
                        'status': 'error',
                        'message': 'Failed to create subscription'
                    }
            
            elif payment_status == 'PENDING':
                return {
                    'success': False,
                    'status': 'pending',
                    'message': 'Payment is still processing'
                }
            else:
                return {
                    'success': False,
                    'status': 'failed',
                    'message': f'Payment failed with status: {payment_status}'
                }
                
        except Exception as e:
            logging.error(f"Payment verification error: {str(e)}")
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
            intasend = get_intasend_service()
            if not intasend:
                return {'error': 'Payment service not available'}, 503
            
            rates = intasend.get_exchange_rates(base_currency)
            
            return {
                'base_currency': base_currency,
                'rates': rates,
                'timestamp': datetime.utcnow().isoformat()
            }
        except Exception as e:
            logging.error(f"Exchange rate error: {str(e)}")
            return {'error': 'Failed to fetch exchange rates'}, 500