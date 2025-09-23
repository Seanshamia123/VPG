# intasend_service.py - IntaSend integration service
import requests
import json
from datetime import datetime
from typing import Dict, Any, Optional, List
from dataclasses import dataclass

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
            price_kes=2000.0,
            price_usd=15.0,
            price_eur=13.0,
            duration_days=30,
            features=[
                "Up to 100 video generations per month",
                "Basic templates",
                "Email support",
                "720p video quality"
            ]
        ),
        SubscriptionPlan(
            id="pro",
            name="Pro Plan",
            description="Advanced features for growing businesses",
            price_kes=5000.0,
            price_usd=35.0,
            price_eur=30.0,
            duration_days=30,
            features=[
                "Up to 500 video generations per month",
                "Premium templates",
                "Priority support",
                "1080p video quality",
                "Custom branding",
                "Analytics dashboard"
            ],
            is_popular=True
        ),
        SubscriptionPlan(
            id="enterprise",
            name="Enterprise Plan",
            description="Full-featured solution for large organizations",
            price_kes=10000.0,
            price_usd=75.0,
            price_eur=65.0,
            duration_days=30,
            features=[
                "Unlimited video generations",
                "All templates and premium content",
                "24/7 support",
                "4K video quality",
                "Custom branding",
                "Advanced analytics",
                "API access",
                "Dedicated account manager"
            ]
        ),
        SubscriptionPlan(
            id="yearly_pro",
            name="Pro Plan (Yearly)",
            description="Pro features with yearly discount",
            price_kes=50000.0,  # ~2 months free
            price_usd=350.0,
            price_eur=300.0,
            duration_days=365,
            features=[
                "Up to 500 video generations per month",
                "Premium templates",
                "Priority support",
                "1080p video quality",
                "Custom branding",
                "Analytics dashboard",
                "2 months free (yearly discount)"
            ]
        )
    ]
    
    @classmethod
    def get_plans(cls) -> List[SubscriptionPlan]:
        """Get all available subscription plans"""
        return cls._plans.copy()
    
    @classmethod
    def get_plan_by_id(cls, plan_id: str) -> SubscriptionPlan:
        """Get a specific plan by ID"""
        for plan in cls._plans:
            if plan.id == plan_id:
                return plan
        raise ValueError(f"Plan with ID '{plan_id}' not found")
    
    @classmethod
    def get_plan_price(cls, plan_id: str, currency: str) -> float:
        """Get plan price in specified currency"""
        plan = cls.get_plan_by_id(plan_id)
        currency = currency.upper()
        
        price_map = {
            'KES': plan.price_kes,
            'USD': plan.price_usd,
            'EUR': plan.price_eur,
        }
        
        if currency not in price_map:
            raise ValueError(f"Currency '{currency}' not supported for plan '{plan_id}'")
        
        return price_map[currency]
    
    @classmethod
    def get_popular_plans(cls) -> List[SubscriptionPlan]:
        """Get popular subscription plans"""
        return [plan for plan in cls._plans if plan.is_popular]

class IntaSendService:
    def __init__(self, publishable_key: str, secret_key: str, is_test: bool = True):
        self.publishable_key = publishable_key
        self.secret_key = secret_key
        self.is_test = is_test
        self.base_url = "https://sandbox.intasend.com" if is_test else "https://payment.intasend.com"
        
    def _get_headers(self) -> Dict[str, str]:
        return {
            'Content-Type': 'application/json',
            'X-IntaSend-Public-Key-Test' if self.is_test else 'X-IntaSend-Public-Key-Live': self.publishable_key,
            'X-IntaSend-Secret-Key-Test' if self.is_test else 'X-IntaSend-Secret-Key-Live': self.secret_key,
        }
    
    def create_checkout_session(self, 
                              amount: float, 
                              currency: str,
                              email: str,
                              phone_number: str = None,
                              first_name: str = None,
                              last_name: str = None,
                              redirect_url: str = None,
                              webhook_url: str = None,
                              reference: str = None) -> Dict[str, Any]:
        """
        Create a checkout session for payment
        
        Args:
            amount: Payment amount
            currency: Currency code (KES, USD, EUR, etc.)
            email: Customer email
            phone_number: Customer phone number (required for M-Pesa)
            first_name: Customer first name
            last_name: Customer last name
            redirect_url: URL to redirect after payment
            webhook_url: URL for payment webhooks
            reference: Unique reference for the transaction
        """
        url = f"{self.base_url}/api/v1/checkout/"
        
        payload = {
            "public_key": self.publishable_key,
            "amount": amount,
            "currency": currency.upper(),
            "email": email,
            "method": "CARD-PAYMENT,MPESA-PAYMENT,BANK-PAYMENT",
        }
        
        if phone_number:
            payload["phone_number"] = phone_number
        if first_name:
            payload["first_name"] = first_name
        if last_name:
            payload["last_name"] = last_name
        if redirect_url:
            payload["redirect_url"] = redirect_url
        if webhook_url:
            payload["webhook_url"] = webhook_url
        if reference:
            payload["reference"] = reference
            
        try:
            response = requests.post(url, json=payload, headers=self._get_headers())
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            return {"error": f"Request failed: {str(e)}"}
        except json.JSONDecodeError:
            return {"error": "Invalid JSON response"}
    
    def verify_payment(self, checkout_id: str) -> Dict[str, Any]:
        """Verify payment status"""
        url = f"{self.base_url}/api/v1/checkout/{checkout_id}/"
        
        try:
            response = requests.get(url, headers=self._get_headers())
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            return {"error": f"Verification failed: {str(e)}"}
    
    def get_supported_currencies(self) -> list:
        """Get list of supported currencies"""
        return [
            {"code": "KES", "name": "Kenyan Shilling", "symbol": "KSh"},
            {"code": "USD", "name": "US Dollar", "symbol": "$"},
            {"code": "EUR", "name": "Euro", "symbol": "€"},
            {"code": "GBP", "name": "British Pound", "symbol": "£"},
            {"code": "UGX", "name": "Ugandan Shilling", "symbol": "USh"},
            {"code": "TZS", "name": "Tanzanian Shilling", "symbol": "TSh"},
        ]
    
    def get_exchange_rates(self, base_currency: str = "KES") -> Dict[str, Any]:
        """Get current exchange rates (mock implementation - replace with actual API)"""
        # This is a mock implementation. In production, you should use a real exchange rate API
        mock_rates = {
            "KES": {
                "USD": 0.0067,  # 1 KES = 0.0067 USD
                "EUR": 0.0062,  # 1 KES = 0.0062 EUR
                "GBP": 0.0053,  # 1 KES = 0.0053 GBP
            },
            "USD": {
                "KES": 149.50,  # 1 USD = 149.50 KES
                "EUR": 0.92,    # 1 USD = 0.92 EUR
                "GBP": 0.79,    # 1 USD = 0.79 GBP
            },
            "EUR": {
                "KES": 162.90,  # 1 EUR = 162.90 KES
                "USD": 1.09,    # 1 EUR = 1.09 USD
                "GBP": 0.86,    # 1 EUR = 0.86 GBP
            }
        }
        return mock_rates.get(base_currency.upper(), {})