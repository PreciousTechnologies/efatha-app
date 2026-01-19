# Quick Start Script for Email Verification Setup
# Run this after configuring your Gmail App Password in .env

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Efatha Church - Email Verification Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if we're in the right directory
if (-Not (Test-Path "manage.py")) {
    Write-Host "❌ Error: Please run this script from the backend folder" -ForegroundColor Red
    Write-Host "   cd c:\Users\MAXFYNN\Desktop\efatha_app\backend" -ForegroundColor Yellow
    exit 1
}

# Check if .env exists
if (-Not (Test-Path ".env")) {
    Write-Host "⚠️  Warning: .env file not found" -ForegroundColor Yellow
    Write-Host "   Creating .env file from template..." -ForegroundColor Yellow
    
    $envContent = @"
# Database Configuration
DB_NAME=efatha_db
DB_USER=postgres
DB_PASSWORD=kiburuta1
DB_HOST=localhost
DB_PORT=5432

# Email Configuration (Gmail)
# Get App Password from: https://myaccount.google.com/apppasswords
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-16-character-app-password
DEFAULT_FROM_EMAIL=Efatha Church <your-email@gmail.com>

# JWT Configuration
JWT_ACCESS_TOKEN_LIFETIME=60
JWT_REFRESH_TOKEN_LIFETIME=1440

# CORS (Add your Flutter app IP)
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000

# Django
SECRET_KEY=django-insecure-change-this-in-production
DEBUG=True
"@
    
    $envContent | Out-File -FilePath ".env" -Encoding UTF8
    Write-Host "✅ .env file created" -ForegroundColor Green
    Write-Host "   ⚠️  Please update EMAIL_HOST_USER and EMAIL_HOST_PASSWORD" -ForegroundColor Yellow
    Write-Host ""
}

# Step 1: Create migrations
Write-Host "Step 1: Creating migrations for VerificationCode model..." -ForegroundColor Cyan
python manage.py makemigrations
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to create migrations" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Migrations created" -ForegroundColor Green
Write-Host ""

# Step 2: Apply migrations
Write-Host "Step 2: Applying migrations..." -ForegroundColor Cyan
python manage.py migrate
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to apply migrations" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Migrations applied" -ForegroundColor Green
Write-Host ""

# Step 3: Check if superuser exists
Write-Host "Step 3: Checking for superuser..." -ForegroundColor Cyan
$superuserCheck = python manage.py shell -c "from django.contrib.auth import get_user_model; User = get_user_model(); print(User.objects.filter(is_superuser=True).exists())"
if ($superuserCheck -eq "False") {
    Write-Host "⚠️  No superuser found. Creating one..." -ForegroundColor Yellow
    Write-Host "   Please enter superuser details:" -ForegroundColor Yellow
    python manage.py createsuperuser
} else {
    Write-Host "✅ Superuser exists" -ForegroundColor Green
}
Write-Host ""

# Step 4: Test email configuration
Write-Host "Step 4: Testing email configuration..." -ForegroundColor Cyan
$testEmailScript = @"
from users.models_verification import VerificationCode
from users.email_utils import send_verification_code_email
from django.conf import settings

# Check email backend
print(f'Email Backend: {settings.EMAIL_BACKEND}')

if settings.EMAIL_BACKEND == 'django.core.mail.backends.console.EmailBackend':
    print('✅ Using console backend (emails will print to console)')
    print('   This is perfect for testing without Gmail setup!')
else:
    print(f'Email Host: {settings.EMAIL_HOST}')
    print(f'Email User: {settings.EMAIL_HOST_USER}')
    print(f'Email TLS: {settings.EMAIL_USE_TLS}')
    
    if not settings.EMAIL_HOST_USER or settings.EMAIL_HOST_USER == 'your-email@gmail.com':
        print('⚠️  Email not configured! Update .env file with your Gmail credentials')
        print('   See GMAIL_SETUP_GUIDE.md for instructions')
    else:
        print('✅ Email configuration looks good!')

# Create a test verification code
code = VerificationCode.create_code('test@example.com', 'login')
print(f'\n✅ Test verification code created: {code.code}')
print(f'   Email: test@example.com')
print(f'   Expires at: {code.expires_at}')
"@

python manage.py shell -c $testEmailScript
Write-Host ""

# Step 5: Display next steps
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Setup Complete! 🎉" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Configure Gmail (if not already done):" -ForegroundColor White
Write-Host "   - Visit: https://myaccount.google.com/apppasswords" -ForegroundColor Gray
Write-Host "   - Generate App Password for 'Efatha Church App'" -ForegroundColor Gray
Write-Host "   - Update .env file with your email and app password" -ForegroundColor Gray
Write-Host "   - See GMAIL_SETUP_GUIDE.md for detailed instructions" -ForegroundColor Gray
Write-Host ""

Write-Host "2. Start the development server:" -ForegroundColor White
Write-Host "   python manage.py runserver 0.0.0.0:8000" -ForegroundColor Cyan
Write-Host ""

Write-Host "3. Test the API:" -ForegroundColor White
Write-Host "   - Swagger UI: http://localhost:8000/swagger/" -ForegroundColor Cyan
Write-Host "   - ReDoc: http://localhost:8000/redoc/" -ForegroundColor Cyan
Write-Host "   - Admin: http://localhost:8000/admin/" -ForegroundColor Cyan
Write-Host ""

Write-Host "4. Test email verification:" -ForegroundColor White
Write-Host "   # Send verification code" -ForegroundColor Gray
Write-Host "   curl -X POST http://localhost:8000/api/auth/send-code/ \" -ForegroundColor Cyan
Write-Host "     -H 'Content-Type: application/json' \" -ForegroundColor Cyan
Write-Host "     -d '{\"email\": \"your-email@gmail.com\", \"purpose\": \"login\"}'" -ForegroundColor Cyan
Write-Host ""
Write-Host "   # Verify code" -ForegroundColor Gray
Write-Host "   curl -X POST http://localhost:8000/api/auth/verify-code/ \" -ForegroundColor Cyan
Write-Host "     -H 'Content-Type: application/json' \" -ForegroundColor Cyan
Write-Host "     -d '{\"email\": \"your-email@gmail.com\", \"code\": \"1234\"}'" -ForegroundColor Cyan
Write-Host ""

Write-Host "5. Update Flutter app IP address:" -ForegroundColor White
Write-Host "   - File: lib/core/config/api_config.dart" -ForegroundColor Gray
Write-Host "   - Change baseUrl to your computer's IP (find with: ipconfig)" -ForegroundColor Gray
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📚 Documentation:" -ForegroundColor Yellow
Write-Host "   - GMAIL_SETUP_GUIDE.md - Gmail configuration" -ForegroundColor Gray
Write-Host "   - EMAIL_VERIFICATION_COMPLETE.md - Full implementation guide" -ForegroundColor Gray
Write-Host "   - AUTHENTICATION_FLOW_COMPLETE.md - Auth flow overview" -ForegroundColor Gray
Write-Host ""

Write-Host "Happy coding! ✝️ 🙏" -ForegroundColor Green
