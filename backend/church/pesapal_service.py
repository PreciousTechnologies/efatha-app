"""
Pesapal Payment Service - Backend Integration
Handles Pesapal API calls from Django backend
"""

import requests
import json
from datetime import datetime, timedelta
from .pesapal_config import (
    PESAPAL_CONSUMER_KEY,
    PESAPAL_CONSUMER_SECRET,
    PESAPAL_AUTH_URL,
    PESAPAL_SUBMIT_ORDER_URL,
    PESAPAL_TRANSACTION_STATUS_URL,
    PESAPAL_REGISTER_IPN_URL,
    PESAPAL_CALLBACK_URL,
    PESAPAL_IPN_ID,
)


class PesapalService:
    """Pesapal Payment Gateway Service"""
    
    def __init__(self):
        self.consumer_key = PESAPAL_CONSUMER_KEY
        self.consumer_secret = PESAPAL_CONSUMER_SECRET
        self.access_token = None
        self.token_expiry = None
    
    def get_access_token(self):
        """Get or refresh Pesapal access token"""
        # Check if token is still valid
        if self.access_token and self.token_expiry:
            if datetime.now() < self.token_expiry:
                return self.access_token
        
        # Request new token
        try:
            response = requests.post(
                PESAPAL_AUTH_URL,
                headers={
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                },
                json={
                    'consumer_key': self.consumer_key,
                    'consumer_secret': self.consumer_secret,
                }
            )
            
            if response.status_code == 200:
                data = response.json()
                self.access_token = data.get('token')
                # Tokens expire in 5 minutes, refresh after 4
                self.token_expiry = datetime.now() + timedelta(minutes=4)
                return self.access_token
            else:
                print(f"Pesapal auth error: {response.text}")
                return None
                
        except Exception as e:
            print(f"Error getting Pesapal token: {e}")
            return None
    
    def submit_order(self, amount, currency, description, email, phone, 
                     first_name, last_name, merchant_reference):
        """Submit payment order to Pesapal"""
        token = self.get_access_token()
        if not token:
            return {'error': 'Failed to authenticate with Pesapal'}

        # Derive Pesapal country code from phone prefix (default TZ)
        digits = ''.join(c for c in str(phone or '') if c.isdigit())
        if digits.startswith('254'):
            country_code = 'KE'
        elif digits.startswith('256'):
            country_code = 'UG'
        elif digits.startswith('250'):
            country_code = 'RW'
        else:
            country_code = 'TZ'

        order_data = {
            'id': merchant_reference,
            'currency': currency,
            'amount': float(amount),
            'description': description,
            'callback_url': PESAPAL_CALLBACK_URL,
            'notification_id': PESAPAL_IPN_ID or '',
            'billing_address': {
                'email_address': email,
                'phone_number': phone,
                'country_code': country_code,
                'first_name': first_name,
                'last_name': last_name,
            }
        }
        
        try:
            response = requests.post(
                PESAPAL_SUBMIT_ORDER_URL,
                headers={
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'Authorization': f'Bearer {token}',
                },
                json=order_data
            )
            
            if response.status_code == 200:
                data = response.json()
                return {
                    'success': True,
                    'order_tracking_id': data.get('order_tracking_id'),
                    'merchant_reference': data.get('merchant_reference'),
                    'redirect_url': data.get('redirect_url'),
                    'error': data.get('error'),
                    'status': data.get('status'),
                }
            else:
                return {
                    'error': f'Payment initiation failed: {response.text}',
                    'status_code': response.status_code,
                }
                
        except Exception as e:
            return {
                'error': f'Error submitting order: {str(e)}',
            }
    
    def get_transaction_status(self, order_tracking_id):
        """Get transaction status from Pesapal"""
        token = self.get_access_token()
        if not token:
            return {'error': 'Failed to authenticate with Pesapal'}
        
        try:
            response = requests.get(
                f'{PESAPAL_TRANSACTION_STATUS_URL}?orderTrackingId={order_tracking_id}',
                headers={
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'Authorization': f'Bearer {token}',
                }
            )
            
            if response.status_code == 200:
                data = response.json()
                return {
                    'payment_method': data.get('payment_method'),
                    'amount': data.get('amount'),
                    'created_date': data.get('created_date'),
                    'confirmation_code': data.get('confirmation_code'),
                    'payment_status_description': data.get('payment_status_description'),
                    'description': data.get('description'),
                    'message': data.get('message'),
                    'payment_account': data.get('payment_account'),
                    'status_code': data.get('status_code'),
                    'merchant_reference': data.get('merchant_reference'),
                    'currency': data.get('currency'),
                    'error': data.get('error'),
                    'status': data.get('status'),
                }
            else:
                return {
                    'error': f'Failed to get transaction status: {response.text}',
                }
                
        except Exception as e:
            return {
                'error': f'Error checking transaction: {str(e)}',
            }
    
    def register_ipn(self, ipn_url):
        """Register IPN URL with Pesapal"""
        token = self.get_access_token()
        if not token:
            return None
        
        try:
            response = requests.post(
                PESAPAL_REGISTER_IPN_URL,
                headers={
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'Authorization': f'Bearer {token}',
                },
                json={
                    'url': ipn_url,
                    'ipn_notification_type': 'GET',
                }
            )
            
            if response.status_code == 200:
                data = response.json()
                ipn_id = data.get('ipn_id')
                print(f"IPN registered successfully. IPN ID: {ipn_id}")
                print(f"Update PESAPAL_IPN_ID in pesapal_config.py with: '{ipn_id}'")
                return ipn_id
            else:
                print(f"Failed to register IPN: {response.text}")
                return None
                
        except Exception as e:
            print(f"Error registering IPN: {e}")
            return None


# Singleton instance
pesapal_service = PesapalService()
