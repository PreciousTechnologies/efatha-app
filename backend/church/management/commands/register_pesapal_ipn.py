"""
Django Management Command to Register Pesapal IPN
Run this command to register your IPN URL with Pesapal
"""

from django.core.management.base import BaseCommand
from church.pesapal_service import pesapal_service
from church.pesapal_config import PESAPAL_IPN_URL


class Command(BaseCommand):
    help = 'Register IPN URL with Pesapal'

    def add_arguments(self, parser):
        parser.add_argument(
            '--url',
            type=str,
            help='IPN URL to register (default from config)',
            default=PESAPAL_IPN_URL,
        )

    def handle(self, *args, **options):
        ipn_url = options['url']
        
        self.stdout.write(self.style.WARNING(f'Registering IPN URL: {ipn_url}'))
        self.stdout.write(self.style.WARNING('Connecting to Pesapal...'))
        
        # Register IPN
        ipn_id = pesapal_service.register_ipn(ipn_url)
        
        if ipn_id:
            self.stdout.write(self.style.SUCCESS('✅ IPN registered successfully!'))
            self.stdout.write(self.style.SUCCESS(f'IPN ID: {ipn_id}'))
            self.stdout.write('')
            self.stdout.write(self.style.WARNING('IMPORTANT: Update your configuration!'))
            self.stdout.write(self.style.WARNING(f"Open: backend/church/pesapal_config.py"))
            self.stdout.write(self.style.WARNING(f"Update: PESAPAL_IPN_ID = '{ipn_id}'"))
        else:
            self.stdout.write(self.style.ERROR('❌ Failed to register IPN'))
            self.stdout.write(self.style.ERROR('Check your Pesapal credentials and try again'))
