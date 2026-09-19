"""
Pesapal Configuration
Store your Pesapal API credentials here
Primary Market: Tanzania (supports TZS, KES, UGX and other currencies)
"""

# Pesapal API Credentials
# LIVE CREDENTIALS (Production)
PESAPAL_CONSUMER_KEY_LIVE = '84tMkwKOsyp8MQBLLltdolXcvoF2T9h+'
PESAPAL_CONSUMER_SECRET_LIVE = 'I7RVFHfvANb4/559uM2UUNdXpd4='

# SANDBOX CREDENTIALS (Testing - has all payment methods)
PESAPAL_CONSUMER_KEY_SANDBOX = 'qkio1BGGYAXTu2JOfm7XSXNruoZsrqEW'
PESAPAL_CONSUMER_SECRET_SANDBOX = 'osGQ364R49cXKeOYSpaOnT++rHs='

# Environment: 'live' or 'sandbox'
# Live is active (M-Pesa enabled). Switch to 'sandbox' only for testing.
PESAPAL_ENVIRONMENT = 'live'

# Use appropriate credentials based on environment
PESAPAL_CONSUMER_KEY = PESAPAL_CONSUMER_KEY_SANDBOX if PESAPAL_ENVIRONMENT == 'sandbox' else PESAPAL_CONSUMER_KEY_LIVE
PESAPAL_CONSUMER_SECRET = PESAPAL_CONSUMER_SECRET_SANDBOX if PESAPAL_ENVIRONMENT == 'sandbox' else PESAPAL_CONSUMER_SECRET_LIVE

# Pesapal API URLs
PESAPAL_API_URL = 'https://cybqa.pesapal.com/pesapalv3' if PESAPAL_ENVIRONMENT == 'sandbox' else 'https://pay.pesapal.com/v3'
PESAPAL_AUTH_URL = f'{PESAPAL_API_URL}/api/Auth/RequestToken'
PESAPAL_REGISTER_IPN_URL = f'{PESAPAL_API_URL}/api/URLSetup/RegisterIPN'
PESAPAL_SUBMIT_ORDER_URL = f'{PESAPAL_API_URL}/api/Transactions/SubmitOrderRequest'
PESAPAL_TRANSACTION_STATUS_URL = f'{PESAPAL_API_URL}/api/Transactions/GetTransactionStatus'

# Callback URLs (update with your actual domain in production)
PESAPAL_CALLBACK_URL = 'https://your-domain.com/api/payments/pesapal/callback'
PESAPAL_IPN_URL = 'https://your-domain.com/api/payments/pesapal/ipn'

# Supported Payment Methods by Currency
# TZS (Tanzania): M-Pesa, Airtel Money, Tigo Pesa, Cards, Bank Transfer
# KES (Kenya): M-Pesa, Airtel Money, Cards, Bank Transfer  
# UGX (Uganda): MTN Money, Airtel Money, Cards, Bank Transfer
# USD/EUR/GBP: Cards, Bank Transfer

# IPN ID (will be generated when you register IPN)
PESAPAL_IPN_ID = '8b99613b-9b9f-4438-9ba3-db28d8f038a1'  # Registered on Pesapal
