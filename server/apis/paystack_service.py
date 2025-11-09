# paystack_service.py - Paystack integration for card payments and bank transfers
import requests
import json
from datetime import datetime
from typing import Dict, Any, Optional
import logging
from config import Config

class PaystackService:
    """
    Paystack service for card payments and bank transfers
    Supports: Cards, Bank Transfers, Mobile Money
    """
    
    def __init__(self, secret_key: str, is_test: bool = True):
        self.secret_key = secret_key
        self.is_test = is_test
        self.base_url = "https://api.paystack.co"
        
    def _get_headers(self) -> Dict[str, str]:
        """Get headers with Paystack authentication"""
        return {
            'Authorization': f'Bearer {self.secret_key}',
            'Content-Type': 'application/json',
        }
    
    def initialize_transaction(self,
                             email: str,
                             amount: float,
                             currency: str = 'KES',
                             reference: str = None,
                             callback_url: str = None,
                             metadata: dict = None,
                             channels: list = None) -> Dict[str, Any]:
        """
        Initialize a Paystack transaction
        
        Args:
            email: Customer email
            amount: Amount in smallest currency unit (kobo for NGN, cents for others)
            currency: Currency code (NGN, GHS, ZAR, KES, USD)
            reference: Unique transaction reference
            callback_url: URL to redirect after payment
            metadata: Additional data to store with transaction
            channels: Payment channels to enable ['card', 'bank', 'ussd', 'mobile_money']
        """
        url = f"{self.base_url}/transaction/initialize"
        
        # Convert amount to smallest unit (cents/kobo)
        # Paystack expects amount in kobo/cents (multiply by 100)
        amount_in_cents = int(float(amount) * 100)
        
        payload = {
            "email": email,
            "amount": amount_in_cents,
            "currency": currency.upper(),
        }
        
        if reference:
            payload["reference"] = reference
        
        if callback_url:
            payload["callback_url"] = callback_url
        
        if metadata:
            payload["metadata"] = metadata
        
        # Default channels: card and bank transfer
        if channels:
            payload["channels"] = channels
        else:
            payload["channels"] = ["card", "bank", "bank_transfer"]
        
        try:
            logging.info(f"=== Initializing Paystack Transaction ===")
            logging.info(f"Email: {email}")
            logging.info(f"Amount: {amount} {currency} ({amount_in_cents} cents)")
            logging.info(f"Reference: {reference}")
            
            response = requests.post(
                url,
                json=payload,
                headers=self._get_headers(),
                timeout=30
            )
            
            logging.info(f"Paystack Response Status: {response.status_code}")
            logging.info(f"Paystack Response: {response.text[:500]}")
            
            response.raise_for_status()
            result = response.json()
            
            if result.get('status'):
                data = result.get('data', {})
                return {
                    "success": True,
                    "authorization_url": data.get('authorization_url'),
                    "access_code": data.get('access_code'),
                    "reference": data.get('reference'),
                    "raw_response": result
                }
            else:
                return {
                    "success": False,
                    "error": result.get('message', 'Transaction initialization failed')
                }
                
        except requests.exceptions.HTTPError as e:
            error_message = f"HTTP Error {e.response.status_code}"
            try:
                error_data = e.response.json()
                error_message = error_data.get('message', str(error_data))
            except:
                error_message = e.response.text
            
            logging.error(f"Paystack HTTP Error: {error_message}")
            return {"success": False, "error": error_message}
            
        except Exception as e:
            logging.error(f"Paystack Error: {str(e)}")
            return {"success": False, "error": str(e)}
    
    def verify_transaction(self, reference: str) -> Dict[str, Any]:
        """
        Verify a Paystack transaction
        
        Args:
            reference: Transaction reference to verify
        """
        url = f"{self.base_url}/transaction/verify/{reference}"
        
        try:
            logging.info(f"=== Verifying Paystack Transaction ===")
            logging.info(f"Reference: {reference}")
            
            response = requests.get(
                url,
                headers=self._get_headers(),
                timeout=30
            )
            
            logging.info(f"Verification Status: {response.status_code}")
            logging.info(f"Verification Response: {response.text[:500]}")
            
            response.raise_for_status()
            result = response.json()
            
            if result.get('status'):
                data = result.get('data', {})
                status = data.get('status', '').lower()
                
                return {
                    "success": status == 'success',
                    "status": status,
                    "reference": data.get('reference'),
                    "amount": data.get('amount', 0) / 100,  # Convert back from cents
                    "currency": data.get('currency'),
                    "customer_email": data.get('customer', {}).get('email'),
                    "paid_at": data.get('paid_at'),
                    "channel": data.get('channel'),
                    "metadata": data.get('metadata', {}),
                    "raw_response": result
                }
            else:
                return {
                    "success": False,
                    "error": result.get('message', 'Verification failed')
                }
                
        except requests.exceptions.HTTPError as e:
            error_message = f"HTTP Error {e.response.status_code}"
            try:
                error_data = e.response.json()
                error_message = error_data.get('message', str(error_data))
            except:
                error_message = e.response.text
            
            logging.error(f"Verification Error: {error_message}")
            return {"success": False, "error": error_message}
            
        except Exception as e:
            logging.error(f"Verification Error: {str(e)}")
            return {"success": False, "error": str(e)}
    
    def charge_card(self,
                   email: str,
                   amount: float,
                   card_number: str,
                   cvv: str,
                   expiry_month: str,
                   expiry_year: str,
                   currency: str = 'KES',
                   reference: str = None,
                   metadata: dict = None) -> Dict[str, Any]:
        """
        Charge a card directly (alternative to hosted page)
        Note: This requires PCI compliance
        """
        url = f"{self.base_url}/charge"
        
        amount_in_cents = int(float(amount) * 100)
        
        payload = {
            "email": email,
            "amount": amount_in_cents,
            "currency": currency.upper(),
            "card": {
                "number": card_number.replace(' ', ''),
                "cvv": cvv,
                "expiry_month": expiry_month,
                "expiry_year": expiry_year,
            }
        }
        
        if reference:
            payload["reference"] = reference
        
        if metadata:
            payload["metadata"] = metadata
        
        try:
            response = requests.post(
                url,
                json=payload,
                headers=self._get_headers(),
                timeout=30
            )
            
            response.raise_for_status()
            result = response.json()
            
            if result.get('status'):
                data = result.get('data', {})
                return {
                    "success": True,
                    "status": data.get('status'),
                    "reference": data.get('reference'),
                    "display_text": data.get('display_text'),
                    "raw_response": result
                }
            else:
                return {
                    "success": False,
                    "error": result.get('message', 'Card charge failed')
                }
                
        except Exception as e:
            logging.error(f"Card Charge Error: {str(e)}")
            return {"success": False, "error": str(e)}
    
    def get_supported_currencies(self) -> list:
        """Get currencies supported by Paystack"""
        return [
            {"code": "NGN", "name": "Nigerian Naira", "symbol": "₦"},
            {"code": "GHS", "name": "Ghanaian Cedi", "symbol": "GH₵"},
            {"code": "ZAR", "name": "South African Rand", "symbol": "R"},
            {"code": "KES", "name": "Kenyan Shilling", "symbol": "KSh"},
            {"code": "USD", "name": "US Dollar", "symbol": "$"},
        ]
    
    def list_banks(self, country: str = 'kenya') -> Dict[str, Any]:
        """
        List banks available for bank transfer
        
        Args:
            country: Country code (nigeria, ghana, kenya, south-africa)
        """
        url = f"{self.base_url}/bank"
        params = {"country": country}
        
        try:
            response = requests.get(
                url,
                params=params,
                headers=self._get_headers(),
                timeout=30
            )
            
            response.raise_for_status()
            result = response.json()
            
            if result.get('status'):
                return {
                    "success": True,
                    "banks": result.get('data', [])
                }
            else:
                return {
                    "success": False,
                    "error": result.get('message', 'Failed to fetch banks')
                }
                
        except Exception as e:
            logging.error(f"List Banks Error: {str(e)}")
            return {"success": False, "error": str(e)}


# Utility function to determine payment provider
def get_payment_provider(currency: str, payment_method: str, phone_number: str = None) -> str:
    """
    Determine which payment provider to use based on currency and method
    
    Returns: 'intasend' or 'paystack'
    """
    currency = currency.upper()
    
    # M-Pesa payments always use IntaSend
    if payment_method == 'M-PESA' or (currency == 'KES' and phone_number):
        return 'intasend'
    
    # Card payments and bank transfers use Paystack
    if payment_method in ['CARD-PAYMENT', 'BANK-TRANSFER', 'card', 'bank']:
        return 'paystack'
    
    # Default based on currency
    if currency == 'KES':
        # For KES without phone, prefer Paystack for cards
        return 'paystack'
    
    # Other currencies use Paystack
    return 'paystack'