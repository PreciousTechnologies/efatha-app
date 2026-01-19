"""
Email Utilities for Efatha Church App
Handles sending verification codes and other emails
"""
from django.core.mail import send_mail
from django.conf import settings
from django.template.loader import render_to_string
from django.utils.html import strip_tags


def send_verification_code_email(email, code, purpose='login'):
    """
    Send 4-digit verification code to user's email
    
    Args:
        email: Recipient email address
        code: 4-digit verification code
        purpose: Purpose of verification (login, registration, password_reset)
    """
    # Determine subject and context based on purpose
    purpose_config = {
        'login': {
            'subject': 'Efatha Church - Login Verification Code',
            'title': 'Login Verification',
            'message': 'Use this code to complete your login:',
        },
        'registration': {
            'subject': 'Efatha Church - Welcome! Verification Code',
            'title': 'Welcome to Efatha Church',
            'message': 'Use this code to complete your registration:',
        },
        'password_reset': {
            'subject': 'Efatha Church - Password Reset Code',
            'title': 'Password Reset',
            'message': 'Use this code to reset your password:',
        },
    }
    
    config = purpose_config.get(purpose, purpose_config['login'])
    
    # Email context
    context = {
        'code': code,
        'email': email,
        'title': config['title'],
        'message': config['message'],
        'expiry_minutes': 10,
    }
    
    # Create HTML email
    html_message = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body {{
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
                line-height: 1.6;
                color: #333;
                max-width: 600px;
                margin: 0 auto;
                padding: 20px;
            }}
            .container {{
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                padding: 40px;
                border-radius: 16px;
                text-align: center;
                box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            }}
            .logo {{
                color: white;
                font-size: 28px;
                font-weight: bold;
                margin-bottom: 10px;
            }}
            .subtitle {{
                color: rgba(255, 255, 255, 0.9);
                font-size: 14px;
                margin-bottom: 30px;
            }}
            .card {{
                background: white;
                padding: 30px;
                border-radius: 12px;
                margin: 20px 0;
            }}
            .title {{
                color: #333;
                font-size: 24px;
                font-weight: bold;
                margin-bottom: 15px;
            }}
            .message {{
                color: #666;
                font-size: 16px;
                margin-bottom: 25px;
            }}
            .code-container {{
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                padding: 20px;
                border-radius: 8px;
                margin: 20px 0;
            }}
            .code {{
                font-size: 48px;
                font-weight: bold;
                color: white;
                letter-spacing: 10px;
                font-family: 'Courier New', monospace;
            }}
            .expiry {{
                color: #999;
                font-size: 14px;
                margin-top: 20px;
            }}
            .warning {{
                background: #fff3cd;
                border-left: 4px solid #ffc107;
                padding: 15px;
                margin-top: 20px;
                text-align: left;
                border-radius: 4px;
            }}
            .warning-title {{
                color: #856404;
                font-weight: bold;
                margin-bottom: 5px;
            }}
            .warning-text {{
                color: #856404;
                font-size: 14px;
            }}
            .footer {{
                color: rgba(255, 255, 255, 0.8);
                font-size: 12px;
                margin-top: 30px;
            }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="logo">✝ EFATHA CHURCH</div>
            <div class="subtitle">Tunaombea, Tunasoma, Tunaimba</div>
            
            <div class="card">
                <div class="title">{config['title']}</div>
                <div class="message">{config['message']}</div>
                
                <div class="code-container">
                    <div class="code">{code}</div>
                </div>
                
                <div class="expiry">
                    This code will expire in {context['expiry_minutes']} minutes
                </div>
                
                <div class="warning">
                    <div class="warning-title">⚠️ Security Notice</div>
                    <div class="warning-text">
                        Never share this code with anyone. Efatha Church staff will never ask for your verification code.
                    </div>
                </div>
            </div>
            
            <div class="footer">
                If you didn't request this code, please ignore this email.<br>
                © 2025 Efatha Church. All rights reserved.
            </div>
        </div>
    </body>
    </html>
    """
    
    # Plain text version
    plain_message = f"""
    EFATHA CHURCH
    Tunaombea, Tunasoma, Tunaimba
    
    {config['title']}
    
    {config['message']}
    
    Your verification code is: {code}
    
    This code will expire in {context['expiry_minutes']} minutes.
    
    Security Notice:
    Never share this code with anyone. Efatha Church staff will never ask for your verification code.
    
    If you didn't request this code, please ignore this email.
    
    © 2025 Efatha Church. All rights reserved.
    """
    
    try:
        send_mail(
            subject=config['subject'],
            message=plain_message,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[email],
            html_message=html_message,
            fail_silently=False,
        )
        return True
    except Exception as e:
        print(f"Error sending email to {email}: {str(e)}")
        return False


def send_welcome_email(user):
    """Send welcome email to new users"""
    subject = 'Welcome to Efatha Church Community!'
    
    html_message = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body {{
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                line-height: 1.6;
                color: #333;
                max-width: 600px;
                margin: 0 auto;
                padding: 20px;
            }}
            .container {{
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                padding: 40px;
                border-radius: 16px;
                text-align: center;
            }}
            .logo {{
                color: white;
                font-size: 32px;
                font-weight: bold;
                margin-bottom: 20px;
            }}
            .card {{
                background: white;
                padding: 30px;
                border-radius: 12px;
                margin: 20px 0;
                text-align: left;
            }}
            .greeting {{
                font-size: 24px;
                font-weight: bold;
                color: #333;
                margin-bottom: 15px;
            }}
            .features {{
                margin: 20px 0;
            }}
            .feature {{
                padding: 10px 0;
                border-bottom: 1px solid #eee;
            }}
            .footer {{
                color: rgba(255, 255, 255, 0.9);
                font-size: 14px;
                margin-top: 20px;
            }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="logo">✝ EFATHA CHURCH</div>
            
            <div class="card">
                <div class="greeting">Welcome, {user.first_name}!</div>
                
                <p>We're excited to have you join the Efatha Church community. Your account has been successfully created.</p>
                
                <div class="features">
                    <div class="feature">📖 Access the Holy Bible anytime</div>
                    <div class="feature">🎵 Browse Tenzi za Rohoni</div>
                    <div class="feature">🎥 Watch live sermons and events</div>
                    <div class="feature">🙏 Share prayer requests</div>
                    <div class="feature">💰 Make giving contributions</div>
                    <div class="feature">📢 Stay updated with announcements</div>
                </div>
                
                <p style="margin-top: 20px;">
                    <strong>Membership Number:</strong> {user.membership_number}<br>
                    <strong>Email:</strong> {user.email}
                </p>
            </div>
            
            <div class="footer">
                Tunaombea, Tunasoma, Tunaimba<br>
                © 2025 Efatha Church. All rights reserved.
            </div>
        </div>
    </body>
    </html>
    """
    
    plain_message = f"""
    EFATHA CHURCH
    
    Welcome, {user.first_name}!
    
    We're excited to have you join the Efatha Church community. Your account has been successfully created.
    
    Features available to you:
    - Access the Holy Bible anytime
    - Browse Tenzi za Rohoni
    - Watch live sermons and events
    - Share prayer requests
    - Make giving contributions
    - Stay updated with announcements
    
    Membership Number: {user.membership_number}
    Email: {user.email}
    
    Tunaombea, Tunasoma, Tunaimba
    © 2025 Efatha Church. All rights reserved.
    """
    
    try:
        send_mail(
            subject=subject,
            message=plain_message,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[user.email],
            html_message=html_message,
            fail_silently=True,
        )
    except Exception as e:
        print(f"Error sending welcome email: {str(e)}")
