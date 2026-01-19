# Gmail App Password Setup Guide for Efatha Church App

This guide will walk you through setting up Gmail to send verification code emails for your Efatha Church app.

## Overview

The app uses Gmail's SMTP server to send 4-digit verification codes via email. To use Gmail for this, you'll need to create an **App Password** (not your regular Gmail password).

---

## Step 1: Prerequisites

Before starting, ensure you have:
- A Gmail account (create one at gmail.com if needed)
- 2-Step Verification enabled on your Google Account (required for App Passwords)

---

## Step 2: Enable 2-Step Verification (If Not Already Enabled)

1. **Go to Google Account Settings**:
   - Visit: https://myaccount.google.com/
   - Or search "Google Account" in Google

2. **Navigate to Security**:
   - Click on "Security" in the left sidebar

3. **Find 2-Step Verification**:
   - Scroll down to "How you sign in to Google"
   - Click on "2-Step Verification"

4. **Enable 2-Step Verification**:
   - Click "Get Started"
   - Follow the prompts to verify your phone number
   - Choose your preferred 2FA method (SMS, Google Authenticator, etc.)
   - Complete the setup

---

## Step 3: Generate App Password

1. **Go to App Passwords**:
   - Visit: https://myaccount.google.com/apppasswords
   - Or Google Account → Security → 2-Step Verification → App passwords

2. **Sign In**:
   - You may be prompted to sign in again for security

3. **Create App Password**:
   - Under "Select app", choose **"Mail"**
   - Under "Select device", choose **"Other (Custom name)"**
   - Enter a name like: **"Efatha Church App"** or **"Django Backend"**
   - Click **"Generate"**

4. **Copy the Password**:
   - Google will display a 16-character password (e.g., `abcd efgh ijkl mnop`)
   - **IMPORTANT**: Copy this password immediately - you won't see it again!
   - Remove the spaces when copying (e.g., `abcdefghijklmnop`)

---

## Step 4: Configure Django Backend

1. **Open your `.env` file** in the backend folder:
   ```
   c:\Users\MAXFYNN\Desktop\efatha_app\backend\.env
   ```

2. **Add Email Configuration**:
   ```env
   # Email Configuration (Gmail)
   EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
   EMAIL_HOST=smtp.gmail.com
   EMAIL_PORT=587
   EMAIL_USE_TLS=True
   EMAIL_HOST_USER=your-email@gmail.com
   EMAIL_HOST_PASSWORD=your-16-character-app-password
   DEFAULT_FROM_EMAIL=Efatha Church <your-email@gmail.com>
   ```

3. **Replace the placeholders**:
   - `your-email@gmail.com` → Your actual Gmail address
   - `your-16-character-app-password` → The app password you copied (without spaces)

   **Example**:
   ```env
   EMAIL_HOST_USER=efathachurch@gmail.com
   EMAIL_HOST_PASSWORD=abcdefghijklmnop
   DEFAULT_FROM_EMAIL=Efatha Church <efathachurch@gmail.com>
   ```

---

## Step 5: Test Email Sending

### Option A: Using Django Shell

1. **Open PowerShell** in the backend folder:
   ```powershell
   cd c:\Users\MAXFYNN\Desktop\efatha_app\backend
   python manage.py shell
   ```

2. **Test sending email**:
   ```python
   from django.core.mail import send_mail
   
   send_mail(
       'Test Email from Efatha Church',
       'This is a test email to verify SMTP configuration.',
       'efathachurch@gmail.com',
       ['recipient@example.com'],  # Replace with your email
       fail_silently=False,
   )
   ```

3. **Check for success**:
   - If successful, you'll see `1` returned
   - Check the recipient email inbox (including spam folder)

### Option B: Using API Endpoint

1. **Start the server**:
   ```powershell
   python manage.py runserver
   ```

2. **Send verification code** via Postman or curl:
   ```bash
   curl -X POST http://localhost:8000/api/auth/send-code/ \
     -H "Content-Type: application/json" \
     -d "{\"email\": \"your-test-email@gmail.com\", \"purpose\": \"login\"}"
   ```

3. **Check your email** for the 4-digit code

---

## Step 6: Troubleshooting

### Issue: "Authentication failed"

**Solution**:
1. Verify your Gmail email is correct
2. Ensure you're using the App Password (not your regular password)
3. Check that the app password has no spaces
4. Verify 2-Step Verification is enabled

### Issue: "Connection refused" or "Timeout"

**Solution**:
1. Check your internet connection
2. Verify `EMAIL_PORT=587` and `EMAIL_USE_TLS=True`
3. Try `EMAIL_PORT=465` with `EMAIL_USE_SSL=True` instead

### Issue: Emails going to spam

**Solution**:
1. Add your sender email to recipient's contacts
2. Mark the email as "Not Spam"
3. Consider using a professional domain email (not Gmail) in production

### Issue: "Less secure app access"

**Solution**:
- Google removed "Less secure app access" in May 2022
- You **must** use App Passwords with 2-Step Verification
- Regular passwords will not work

---

## Step 7: Production Recommendations

### Use a Dedicated Email Account
- Create a separate Gmail account specifically for the app
- Example: `efathachurch.noreply@gmail.com`
- Don't use personal accounts

### Security Best Practices
- Never commit `.env` file to version control
- Add `.env` to `.gitignore`
- Rotate app passwords periodically
- Use different app passwords for different environments

### Email Service Alternatives

For production, consider professional email services:

1. **SendGrid** (Free tier: 100 emails/day)
   - Website: https://sendgrid.com/
   - Django package: `pip install sendgrid-django`

2. **Mailgun** (Free tier: 5,000 emails/month)
   - Website: https://www.mailgun.com/
   - Django package: `pip install django-mailgun`

3. **AWS SES** (62,000 emails/month free with AWS)
   - Website: https://aws.amazon.com/ses/
   - Django package: `pip install django-ses`

---

## Email Configuration Reference

### Gmail SMTP Settings
```env
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password
```

### Console Backend (Development/Testing)
```env
EMAIL_BACKEND=django.core.mail.backends.console.EmailBackend
```
This prints emails to console instead of sending them - useful for testing without SMTP setup.

### File Backend (Development/Testing)
```env
EMAIL_BACKEND=django.core.mail.backends.filebased.EmailBackend
EMAIL_FILE_PATH=/tmp/app-emails
```
Saves emails to files instead of sending them.

---

## Verification Code Email Features

The app sends beautifully designed HTML emails with:
- ✝️ Efatha Church branding
- Large, easy-to-read 4-digit code
- 10-minute expiration countdown
- Security warnings
- Mobile-responsive design
- Plain text fallback

---

## Quick Start Commands

1. **Create migration for VerificationCode model**:
   ```powershell
   cd backend
   python manage.py makemigrations
   ```

2. **Apply migrations**:
   ```powershell
   python manage.py migrate
   ```

3. **Test in Django shell**:
   ```powershell
   python manage.py shell
   ```
   ```python
   from users.models_verification import VerificationCode
   from users.email_utils import send_verification_code_email
   
   # Create code
   code = VerificationCode.create_code('test@example.com', 'login')
   print(f"Code: {code.code}")
   
   # Send email
   send_verification_code_email('test@example.com', code.code, 'login')
   ```

---

## API Endpoints for Email Verification

### Send Verification Code
```http
POST /api/auth/send-code/
Content-Type: application/json

{
  "email": "user@example.com",
  "purpose": "login"
}
```

**Response**:
```json
{
  "message": "Verification code sent to your email",
  "email": "user@example.com",
  "expires_in_minutes": 10
}
```

### Verify Code and Login
```http
POST /api/auth/verify-code/
Content-Type: application/json

{
  "email": "user@example.com",
  "code": "1234"
}
```

**Response**:
```json
{
  "message": "Login successful",
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": {
    "id": 1,
    "username": "johndoe",
    "email": "user@example.com",
    ...
  }
}
```

---

## Support

If you encounter issues:
1. Check the Django console for error messages
2. Verify all `.env` settings are correct
3. Test with console backend first (no SMTP needed)
4. Review Gmail security settings
5. Check spam folder for emails

---

## Summary Checklist

- [ ] 2-Step Verification enabled on Google Account
- [ ] App Password generated and copied
- [ ] `.env` file updated with email settings
- [ ] Migrations created and applied
- [ ] Test email sent successfully
- [ ] Verification code received in inbox
- [ ] API endpoints tested and working

**You're all set!** 🎉

The Efatha Church app can now send verification code emails to users for secure, passwordless login.
