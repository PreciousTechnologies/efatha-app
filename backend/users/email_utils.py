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

    purpose_labels = {
        'login': 'Login',
        'registration': 'Registration',
        'password_reset': 'Password Reset',
    }
    purpose_label = purpose_labels.get(purpose, 'Login')

    # Inline SVG icons (emoji-free, crisp on all modern mail clients)
    ICON_CROSS_LIGHT = '<svg width="13" height="16" viewBox="0 0 12 16" style="vertical-align: -3px;" role="img" aria-label="Cross"><rect x="4.5" y="0" width="3" height="16" rx="1" fill="#ffffff"/><rect x="0" y="4" width="12" height="3" rx="1" fill="#ffffff"/></svg>'
    ICON_TARGET_GOLD = '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#fde68a" stroke-width="2.5" style="vertical-align: -2px;" role="img" aria-label="Target"><circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="4.5"/><circle cx="12" cy="12" r="1" fill="#fde68a" stroke="none"/></svg>'
    ICON_TARGET_GREEN = '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#059669" stroke-width="2.2" role="img" aria-label="Target"><circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="4.5"/><circle cx="12" cy="12" r="1" fill="#059669" stroke="none"/></svg>'
    ICON_CLOCK = '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#6B46C1" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" role="img" aria-label="Clock"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>'
    ICON_MAIL = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#2196F3" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align: -2px;" role="img" aria-label="Email"><rect x="2" y="4" width="20" height="16" rx="3"/><path d="M2 7l10 7L22 7"/></svg>'
    ICON_ALERT = '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#b45309" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align: -2px;" role="img" aria-label="Warning"><path d="M10.3 3.9L1.8 18a2 2 0 001.7 3h17a2 2 0 001.7-3L13.7 3.9a2 2 0 00-3.4 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>'
    ICON_SPARK = '<svg width="18" height="18" viewBox="0 0 24 24" fill="#F59E0B" style="vertical-align: -3px;" role="img" aria-label="Sparkle"><path d="M12 0l2.6 9.4L24 12l-9.4 2.6L12 24l-2.6-9.4L0 12l9.4-2.6z"/></svg>'

    # Email context
    context = {
        'code': code,
        'email': email,
        'title': config['title'],
        'message': config['message'],
        'expiry_minutes': 10,
    }

    # Skeuomorphic digit tiles — one tactile "key" per digit
    digits = list(str(code))
    digit_cells = ''.join(
        f'''
        <td align="center" valign="middle" style="width: 64px; height: 78px; background: #ffffff; background: linear-gradient(180deg, #ffffff 0%, #f3effd 55%, #ddd2f7 100%); border: 1px solid #c6b6f2; border-bottom: 3px solid #a583ec; border-radius: 18px; box-shadow: inset 0 2px 0 #ffffff, inset 0 -4px 8px rgba(107, 70, 193, 0.28), 0 12px 22px rgba(76, 29, 149, 0.35);">
            <div style="height: 5px; width: 34px; background: #ffffff; opacity: 0.9; border-radius: 3px; margin: 7px auto 0;"></div>
            <div style="font-size: 42px; font-weight: 800; line-height: 1; color: #4c1d95; font-family: 'Courier New', Courier, monospace; text-shadow: 0 1px 0 #ffffff, 0 -1px 1px rgba(0, 0, 0, 0.25); padding-bottom: 8px;">{d}</div>
        </td>
        <td style="width: 10px; font-size: 0; line-height: 0;">&nbsp;</td>
        '''
        for d in digits
    )

    # Create HTML email — liquid glass + skeuomorphism + bento grid
    html_message = f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>{config['subject']}</title>
        <style>
            @media only screen and (max-width: 480px) {{
                .bento-col {{
                    display: block !important;
                    width: 100% !important;
                    padding-bottom: 10px !important;
                }}
                .hero-title {{
                    font-size: 22px !important;
                }}
            }}
        </style>
    </head>
    <body style="margin: 0; padding: 0; background-color: #17123b; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;">
        <div style="display: none; max-height: 0; overflow: hidden; opacity: 0; color: transparent;">
            Your Efatha verification code is inside — it expires in 10 minutes.
        </div>
        <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="background-color: #17123b;">
            <tr>
                <td align="center" style="padding: 32px 16px;">
                    <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="600" style="max-width: 600px; width: 100%;">

                        <!-- ===== HERO (deep gradient, floating orbs) ===== -->
                        <tr>
                            <td bgcolor="#5b3fb8" style="background-color: #5b3fb8; background: radial-gradient(circle at 15% 20%, rgba(255, 255, 255, 0.35) 0, rgba(255, 255, 255, 0) 28%), radial-gradient(circle at 85% 15%, rgba(253, 224, 71, 0.45) 0, rgba(253, 224, 71, 0) 26%), radial-gradient(circle at 80% 85%, rgba(139, 92, 246, 0.9) 0, rgba(139, 92, 246, 0) 40%), linear-gradient(135deg, #2b1a5e 0%, #6B46C1 55%, #8B5CF6 100%); border-radius: 28px; padding: 38px 32px 30px; text-align: center;">
                                <div style="display: inline-block; background: rgba(255, 255, 255, 0.18); border: 1px solid rgba(255, 255, 255, 0.45); border-radius: 999px; padding: 8px 20px; font-size: 15px; font-weight: 800; letter-spacing: 3px; color: #ffffff;">
                                    {ICON_CROSS_LIGHT} EFATHA CHURCH
                                </div>
                                <div class="hero-title" style="color: #ffffff; font-size: 26px; font-weight: 800; margin: 16px 0 6px;">
                                    {config['title']}
                                </div>
                                <div style="color: rgba(255, 255, 255, 0.85); font-size: 13px; letter-spacing: 1px;">
                                    Tunaombea &nbsp;&bull;&nbsp; Tunasoma &nbsp;&bull;&nbsp; Tunaimba
                                </div>
                                <div style="display: inline-block; margin-top: 14px; background: rgba(0, 0, 0, 0.25); border: 1px solid rgba(255, 255, 255, 0.3); color: #fde68a; font-size: 12px; font-weight: 700; letter-spacing: 1.5px; text-transform: uppercase; border-radius: 999px; padding: 6px 16px;">
                                    {ICON_TARGET_GOLD} {purpose_label} code
                                </div>
                            </td>
                        </tr>

                        <tr><td style="height: 16px; font-size: 0; line-height: 0;">&nbsp;</td></tr>

                        <!-- ===== LIQUID GLASS CARD ===== -->
                        <tr>
                            <td bgcolor="#ffffff" style="background-color: #ffffff; background: rgba(255, 255, 255, 0.88); -webkit-backdrop-filter: blur(20px) saturate(160%); backdrop-filter: blur(20px) saturate(160%); border: 1px solid rgba(255, 255, 255, 0.65); border-radius: 24px; box-shadow: 0 24px 60px rgba(0, 0, 0, 0.45), inset 0 1px 0 rgba(255, 255, 255, 0.9); padding: 34px 30px; text-align: center;">
                                <div style="color: #1e1b4b; font-size: 19px; font-weight: 800;">
                                    Hello {ICON_SPARK}
                                </div>
                                <div style="color: #6d6390; font-size: 15px; margin: 8px 0 4px;">
                                    {config['message']}
                                </div>

                                <!-- Skeuomorphic code keys -->
                                <table role="presentation" cellpadding="0" cellspacing="0" border="0" align="center" style="margin: 22px auto 6px; border-collapse: separate;">
                                    <tr>
                                        {digit_cells}
                                    </tr>
                                </table>

                                <!-- Bento grid -->
                                <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="margin-top: 18px; border-collapse: separate; border-spacing: 0;">
                                    <tr>
                                        <td class="bento-col" width="50%" valign="top" style="padding-right: 5px;">
                                            <div style="background: rgba(107, 70, 193, 0.08); border: 1px solid rgba(107, 70, 193, 0.20); border-radius: 16px; padding: 12px 14px; text-align: left;">
                                                <div style="line-height: 1;">{ICON_CLOCK}</div>
                                                <div style="font-size: 11px; font-weight: 700; letter-spacing: 1.2px; text-transform: uppercase; color: #8b83a8; margin-top: 6px;">Expires in</div>
                                                <div style="font-size: 16px; font-weight: 800; color: #1e1b4b;">{context['expiry_minutes']} minutes</div>
                                            </div>
                                        </td>
                                        <td class="bento-col" width="50%" valign="top" style="padding-left: 5px;">
                                            <div style="background: rgba(16, 185, 129, 0.10); border: 1px solid rgba(16, 185, 129, 0.25); border-radius: 16px; padding: 12px 14px; text-align: left;">
                                                <div style="line-height: 1;">{ICON_TARGET_GREEN}</div>
                                                <div style="font-size: 11px; font-weight: 700; letter-spacing: 1.2px; text-transform: uppercase; color: #8b83a8; margin-top: 6px;">Purpose</div>
                                                <div style="font-size: 16px; font-weight: 800; color: #1e1b4b;">{purpose_label}</div>
                                            </div>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td colspan="2" style="padding-top: 10px;">
                                            <div style="background: rgba(33, 150, 243, 0.08); border: 1px solid rgba(33, 150, 243, 0.22); border-radius: 16px; padding: 12px 14px; text-align: left;">
                                                <div style="font-size: 11px; font-weight: 700; letter-spacing: 1.2px; text-transform: uppercase; color: #8b83a8;">{ICON_MAIL} Sent to</div>
                                                <div style="font-size: 15px; font-weight: 700; color: #1e1b4b; word-break: break-all;">{email}</div>
                                            </div>
                                        </td>
                                    </tr>
                                </table>

                                <!-- Security notice -->
                                <div style="background: rgba(245, 158, 11, 0.12); border: 1px solid rgba(245, 158, 11, 0.35); border-left: 4px solid #F59E0B; border-radius: 14px; padding: 14px 16px; margin-top: 18px; text-align: left;">
                                    <div style="color: #92400e; font-weight: 800; font-size: 14px;">{ICON_ALERT} Security Notice</div>
                                    <div style="color: #92400e; font-size: 13px; margin-top: 4px;">
                                        Never share this code with anyone. Efatha Church staff will never ask for your verification code.
                                    </div>
                                </div>
                            </td>
                        </tr>

                        <tr><td style="height: 16px; font-size: 0; line-height: 0;">&nbsp;</td></tr>

                        <!-- ===== FOOTER ===== -->
                        <tr>
                            <td bgcolor="#221c4e" style="background-color: #221c4e; border: 1px solid rgba(255, 255, 255, 0.12); border-radius: 20px; padding: 22px 24px; text-align: center;">
                                <div style="color: rgba(255, 255, 255, 0.9); font-size: 13px; font-weight: 700; letter-spacing: 1px;">
                                    {ICON_CROSS_LIGHT} EFATHA CHURCH
                                </div>
                                <div style="color: rgba(255, 255, 255, 0.6); font-size: 12px; margin-top: 8px; line-height: 1.7;">
                                    If you didn&apos;t request this code, please ignore this email.<br>
                                    &copy; 2025 Efatha Church. All rights reserved.
                                </div>
                            </td>
                        </tr>

                    </table>
                </td>
            </tr>
        </table>
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
