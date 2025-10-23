# intasend_service.py - Fixed with country field for card payments
import requests
import json
from datetime import datetime
from typing import Dict, Any, Optional, List
from dataclasses import dataclass
from config import Config

@dataclass
class SubscriptionPlan:
    id: str
    name: str
    description: str
    price_kes: float
    price_usd: float
    price_eur: float
    duration_days: int
    features: List[str]
    is_popular: bool = False

class SubscriptionPlans:
    """Subscription plans management"""
    
    _plans = [
        SubscriptionPlan(
            id="basic",
            name="Basic Plan",
            description="Essential features for small businesses",
            price_kes=1.0,
            price_usd=1.00,
            price_eur=13.0,
            duration_days=30,
            features=[
                "Up to 10 posts per month",
                "Basic profile visibility",
                "Standard support",
                "Mobile app access",
                "Basic analytics"
            ]
        ),
        SubscriptionPlan(
            id="premium",
            name="Premium Plan",
            description="Most popular choice for professionals",
            price_kes=3500.0,
            price_usd=35.0,
            price_eur=30.0,
            duration_days=30,
            features=[
                "Unlimited posts",
                "Priority profile placement",
                "Verified badge",
                "Priority support",
                "Advanced analytics",
                "Featured in search results",
                "Premium visibility boost",
                "Direct messaging features"
            ],
            is_popular=True
        )
    ]
    
    @classmethod
    def get_plans(cls) -> List[SubscriptionPlan]:
        return cls._plans.copy()
    
    @classmethod
    def get_plan_by_id(cls, plan_id: str) -> SubscriptionPlan:
        for plan in cls._plans:
            if plan.id == plan_id:
                return plan
        raise ValueError(f"Plan with ID '{plan_id}' not found")
    
    @classmethod
    def get_plan_price(cls, plan_id: str, currency: str) -> float:
        plan = cls.get_plan_by_id(plan_id)
        currency = currency.upper()
        
        price_map = {
            'KES': plan.price_kes,
            'USD': plan.price_usd,
            'EUR': plan.price_eur,
        }
        
        if currency not in price_map:
            raise ValueError(f"Currency '{currency}' not supported")
        
        return price_map[currency]

class IntaSendService:
    def __init__(self, publishable_key: str, secret_key: str, is_test: bool = True):
        self.publishable_key = publishable_key
        self.secret_key = secret_key
        self.is_test = is_test
        
        if is_test:
            self.base_url = "https://sandbox.intasend.com"
        else:
            self.base_url = "https://payment.intasend.com"
        
    def _get_headers(self) -> Dict[str, str]:
        """Get headers with proper authentication"""
        return {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': f'Bearer {self.secret_key}',
        }
    
    def _determine_payment_method(self, currency: str, phone_number: Optional[str], 
                                  has_card_details: bool = False) -> str:
        """
        Determine appropriate payment method
        - M-PESA: For KES with phone number (STK Push)
        - CARD-PAYMENT: For international cards or when card details provided
        """
        currency = currency.upper()
        
        # If card details are provided, use card payment
        if has_card_details:
            return 'CARD-PAYMENT'
        
        # For KES currency with phone, use M-PESA
        if currency == 'KES' and phone_number and phone_number.strip():
            return 'M-PESA'
        
        # Default to card payment for international currencies
        return 'CARD-PAYMENT'
    
    def _get_country_from_currency(self, currency: str) -> str:
        """Get country code from currency"""
        currency_country_map = {
            'KES': 'KE',  # Kenya
            'USD': 'US',  # United States
            'EUR': 'DE',  # Germany (default for EUR)
            'GBP': 'GB',  # United Kingdom
        }
        return currency_country_map.get(currency.upper(), 'US')

    def create_checkout_session(self, 
                            amount: float, 
                            currency: str,
                            email: str,
                            phone_number: str = None,
                            first_name: str = None,
                            last_name: str = None,
                            redirect_url: str = None,
                            webhook_url: str = None,
                            reference: str = None,
                            payment_method: str = None,
                            # Card payment fields
                            card_number: str = None,
                            card_expiry: str = None,
                            card_cvc: str = None,
                            card_holder_name: str = None,
                            country: str = None) -> Dict[str, Any]:
        """
        Create a checkout session for payment using IntaSend API
        Supports both M-Pesa and Card payments
        """
        url = f"{self.base_url}/api/v1/payment/collection/"
        
        # Check if card details are provided
        has_card_details = all([card_number, card_expiry, card_cvc])
        
        # Determine payment method if not provided
        if not payment_method:
            payment_method = self._determine_payment_method(currency, phone_number, has_card_details)
        
        # CRITICAL: Round amount to 2 decimal places for IntaSend
        amount = round(float(amount), 2)
        
        # Determine country if not provided
        if not country:
            country = self._get_country_from_currency(currency)
        
        # Build payload
        payload = {
            "public_key": self.publishable_key,
            "amount": amount,
            "currency": currency.upper(),
            "email": email,
            "method": payment_method,
            "api_ref": reference or f"order_{int(datetime.utcnow().timestamp())}",
        }
        
        # Add card details if provided and using card payment
        if payment_method == 'CARD-PAYMENT' and has_card_details:
            payload["card_number"] = card_number.replace(' ', '')
            
            # Format expiry to MM/YY (IntaSend expects slash format)
            expiry_cleaned = card_expiry.replace('/', '').replace(' ', '')
            if len(expiry_cleaned) == 4:
                # Convert MMYY to MM/YY
                payload["expiry"] = f"{expiry_cleaned[:2]}/{expiry_cleaned[2:]}"
            else:
                # Already has slash or is in correct format
                payload["expiry"] = card_expiry.strip()
            
            payload["cvc"] = card_cvc
            
            # CRITICAL: Add country for card payments
            payload["country"] = country.upper()
            
            if card_holder_name:
                # Split name for first and last name
                name_parts = card_holder_name.strip().split(' ', 1)
                payload["first_name"] = name_parts[0] if name_parts else first_name or ''
                payload["last_name"] = name_parts[1] if len(name_parts) > 1 else last_name or ''
            else:
                if first_name:
                    payload["first_name"] = first_name
                if last_name:
                    payload["last_name"] = last_name
        else:
            # For M-Pesa or card without details (checkout page)
            if phone_number:
                formatted_phone = self._format_phone_number(phone_number, currency)
                if formatted_phone:
                    payload["phone_number"] = formatted_phone
            
            if first_name:
                payload["first_name"] = first_name
            if last_name:
                payload["last_name"] = last_name
        
        if redirect_url:
            payload["redirect_url"] = redirect_url
        
        # Add metadata
        payload["metadata"] = {
            "reference": reference,
            "created_at": datetime.utcnow().isoformat()
        }
        
        try:
            print(f"Creating IntaSend checkout: {url}")
            print(f"Method: {payment_method}")
            print(f"Country: {country}")
            print(f"Has card details: {has_card_details}")
            
            # Log payload without sensitive card info
            safe_payload = payload.copy()
            if 'card_number' in safe_payload:
                safe_payload['card_number'] = f"{safe_payload['card_number'][:4]}...{safe_payload['card_number'][-4:]}"
            if 'cvc' in safe_payload:
                safe_payload['cvc'] = '***'
            print(f"Payload: {json.dumps(safe_payload, indent=2)}")
            
            response = requests.post(
                url, 
                json=payload, 
                headers=self._get_headers(),
                timeout=30
            )
            
            print(f"Response Status: {response.status_code}")
            print(f"Response Body: {response.text}")
            
            response.raise_for_status()
            
            result = response.json()
            invoice = result.get('invoice', {})
            
            # Check if this is M-Pesa STK Push
            is_mpesa_stk = payment_method == 'M-PESA' and not result.get('url')
            
            if is_mpesa_stk:
                return {
                    "success": True,
                    "payment_type": "mpesa_stk_push",
                    "checkout_url": None,
                    "checkout_id": result.get("id"),
                    "invoice_id": invoice.get("invoice_id"),
                    "state": invoice.get("state"),
                    "api_ref": invoice.get("api_ref"),
                    "method": payment_method,
                    "phone_number": invoice.get("account"),
                    "message": "STK Push sent to phone. Please enter M-Pesa PIN to complete payment.",
                    "raw_response": result
                }
            else:
                # Card payment - might be direct or checkout page
                checkout_url = result.get("url") or result.get("payment_link")
                
                # If card details were provided, it might process immediately
                state = invoice.get("state", "").upper()
                if state in ['COMPLETE', 'COMPLETED', 'SUCCESS']:
                    return {
                        "success": True,
                        "payment_type": "card_direct",
                        "checkout_url": None,
                        "checkout_id": result.get("id"),
                        "invoice_id": invoice.get("invoice_id"),
                        "state": state,
                        "api_ref": invoice.get("api_ref"),
                        "method": payment_method,
                        "message": "Card payment processed successfully",
                        "raw_response": result
                    }
                elif checkout_url:
                    # Redirect to checkout page
                    return {
                        "success": True,
                        "payment_type": "web_checkout",
                        "checkout_url": checkout_url,
                        "checkout_id": result.get("id"),
                        "invoice_id": invoice.get("invoice_id"),
                        "state": invoice.get("state"),
                        "api_ref": invoice.get("api_ref"),
                        "method": payment_method,
                        "raw_response": result
                    }
                else:
                    return {
                        "error": "Payment initiated but no checkout URL or completion status returned."
                    }
            
        except requests.exceptions.HTTPError as e:
            error_message = f"HTTP Error {e.response.status_code}"
            try:
                error_data = e.response.json()
                if error_data.get('type') == 'validation_error':
                    errors = error_data.get('errors', [])
                    error_details = [f"{err.get('attr')}: {err.get('detail')}" for err in errors]
                    error_message = f"Validation error: {', '.join(error_details)}"
                else:
                    error_message = error_data.get('detail') or error_data.get('error') or str(error_data)
            except:
                error_message = e.response.text
            
            print(f"IntaSend API Error: {error_message}")
            return {"error": error_message}
            
        except requests.exceptions.RequestException as e:
            error_message = f"Request failed: {str(e)}"
            print(f"Request Error: {error_message}")
            return {"error": error_message}
            
        except json.JSONDecodeError as e:
            error_message = "Invalid JSON response from IntaSend"
            print(f"JSON Error: {error_message}")
            return {"error": error_message}
        
    def _format_phone_number(self, phone: str, currency: str) -> Optional[str]:
        """Format phone number for IntaSend API"""
        if not phone:
            return None
        
        cleaned = ''.join(filter(str.isdigit, phone))
        
        if currency.upper() != 'KES':
            return None
        
        if cleaned.startswith('254') and len(cleaned) == 12:
            return cleaned
        elif cleaned.startswith('0') and len(cleaned) == 10:
            return f"254{cleaned[1:]}"
        elif len(cleaned) == 9:
            return f"254{cleaned}"
        
        return cleaned if len(cleaned) >= 9 else None
    
    def verify_payment(self, checkout_id: str = None, invoice_id: str = None, 
                      api_ref: str = None) -> Dict[str, Any]:
        """Verify payment status"""
        params = {}
        
        if invoice_id:
            url = f"{self.base_url}/api/v1/payment/status/"
            params = {"invoice_id": invoice_id}
            identifier = f"invoice_id={invoice_id}"
        elif api_ref:
            url = f"{self.base_url}/api/v1/payment/status/"
            params = {"api_ref": api_ref}
            identifier = f"api_ref={api_ref}"
        elif checkout_id:
            url = f"{self.base_url}/api/v1/payment/collection/{checkout_id}/"
            params = {}
            identifier = f"checkout_id={checkout_id}"
        else:
            return {"error": "Must provide checkout_id, invoice_id, or api_ref"}
        
        try:
            print(f"=== Verifying payment ===")
            print(f"URL: {url}")
            print(f"Identifier: {identifier}")
            
            response = requests.get(
                url,
                params=params,
                headers=self._get_headers(),
                timeout=30
            )
            
            print(f"Verification Response Status: {response.status_code}")
            print(f"Verification Response: {response.text[:500]}")
            
            if response.status_code == 404:
                print("Payment not found (404)")
                return {
                    "success": False,
                    "state": "PENDING",
                    "message": "Payment not found. It may still be processing."
                }
            
            response.raise_for_status()
            
            result = response.json()
            invoice = result.get('invoice', result)
            state = invoice.get('state', '').upper()
            
            is_complete = state in ['COMPLETE', 'COMPLETED', 'SUCCESS', 'PAID']
            
            return {
                "success": is_complete,
                "state": state,
                "invoice_id": invoice.get('invoice_id'),
                "api_ref": invoice.get('api_ref'),
                "value": invoice.get('value') or invoice.get('amount'),
                "currency": invoice.get('currency'),
                "reference": invoice.get('api_ref'),
                "mpesa_reference": invoice.get('mpesa_reference'),
                "account": invoice.get('account'),
                "charges": invoice.get('charges', 0),
                "net_amount": invoice.get('net_amount'),
                "raw_response": result
            }
            
        except requests.exceptions.HTTPError as e:
            error_message = f"HTTP {e.response.status_code}"
            try:
                error_data = e.response.json()
                error_message = error_data.get('detail') or error_data.get('error') or str(error_data)
            except:
                error_message = e.response.text
            
            print(f"Verification HTTP Error: {error_message}")
            return {"error": f"Verification failed: {error_message}"}
            
        except Exception as e:
            print(f"Verification Error: {str(e)}")
            return {"error": str(e)}
    
    def get_supported_currencies(self) -> list:
        """Get list of supported currencies"""
        return [
            {"code": "KES", "name": "Kenyan Shilling", "symbol": "KSh"},
            {"code": "USD", "name": "US Dollar", "symbol": "$"},
            {"code": "EUR", "name": "Euro", "symbol": "€"},
            {"code": "GBP", "name": "British Pound", "symbol": "£"},
        ]
    
    def get_exchange_rates(self, base_currency: str = "KES") -> Dict[str, Any]:
        """Get current exchange rates (mock implementation)"""
        mock_rates = {
            "KES": {
                "USD": 0.0067,
                "EUR": 0.0062,
                "GBP": 0.0053,
            },
            "USD": {
                "KES": 149.50,
                "EUR": 0.92,
                "GBP": 0.79,
            },
            "EUR": {
                "KES": 162.90,
                "USD": 1.09,
                "GBP": 0.86,
            }
        }
        return mock_rates.get(base_currency.upper(), {})