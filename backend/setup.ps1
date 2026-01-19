# Backend Setup Script for Efatha Church App
# Run this in PowerShell from the backend directory

Write-Host "=== Efatha Church Backend Setup ===" -ForegroundColor Cyan
Write-Host ""

# Check Python
Write-Host "Checking Python installation..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version
    Write-Host "✓ $pythonVersion found" -ForegroundColor Green
} catch {
    Write-Host "✗ Python not found! Please install Python 3.10+" -ForegroundColor Red
    exit 1
}

# Check PostgreSQL
Write-Host "Checking PostgreSQL..." -ForegroundColor Yellow
try {
    $pgVersion = psql --version
    Write-Host "✓ $pgVersion found" -ForegroundColor Green
} catch {
    Write-Host "✗ PostgreSQL not found! Please install PostgreSQL 14+" -ForegroundColor Red
    exit 1
}

# Create virtual environment
Write-Host ""
Write-Host "Creating virtual environment..." -ForegroundColor Yellow
if (Test-Path "venv") {
    Write-Host "Virtual environment already exists" -ForegroundColor Yellow
} else {
    python -m venv venv
    Write-Host "✓ Virtual environment created" -ForegroundColor Green
}

# Activate virtual environment
Write-Host ""
Write-Host "Activating virtual environment..." -ForegroundColor Yellow
& .\venv\Scripts\Activate.ps1

# Install dependencies
Write-Host ""
Write-Host "Installing Python dependencies..." -ForegroundColor Yellow
pip install --upgrade pip
pip install -r requirements.txt
Write-Host "✓ Dependencies installed" -ForegroundColor Green

# Create .env if not exists
Write-Host ""
if (!(Test-Path ".env")) {
    Write-Host "Creating .env file..." -ForegroundColor Yellow
    Copy-Item .env.example .env
    Write-Host "✓ .env file created" -ForegroundColor Green
    Write-Host "⚠ Please update SECRET_KEY in .env file!" -ForegroundColor Yellow
} else {
    Write-Host ".env file already exists" -ForegroundColor Green
}

# Create database
Write-Host ""
Write-Host "Setting up database..." -ForegroundColor Yellow
Write-Host "Database: efatha_db" -ForegroundColor Cyan
Write-Host "User: postgres" -ForegroundColor Cyan
Write-Host "Password: kiburuta1" -ForegroundColor Cyan
Write-Host ""
$createDb = Read-Host "Create database? (y/n)"
if ($createDb -eq "y") {
    $env:PGPASSWORD = "kiburuta1"
    try {
        psql -U postgres -c "CREATE DATABASE efatha_db;"
        Write-Host "✓ Database created" -ForegroundColor Green
    } catch {
        Write-Host "Database might already exist or error occurred" -ForegroundColor Yellow
    }
}

# Run migrations
Write-Host ""
Write-Host "Running migrations..." -ForegroundColor Yellow
python manage.py makemigrations
python manage.py migrate
Write-Host "✓ Migrations completed" -ForegroundColor Green

# Create superuser
Write-Host ""
$createSuper = Read-Host "Create superuser? (y/n)"
if ($createSuper -eq "y") {
    python manage.py createsuperuser
}

# Collect static files
Write-Host ""
Write-Host "Collecting static files..." -ForegroundColor Yellow
python manage.py collectstatic --noinput
Write-Host "✓ Static files collected" -ForegroundColor Green

Write-Host ""
Write-Host "=== Setup Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "To start the server, run:" -ForegroundColor Cyan
Write-Host "  python manage.py runserver 0.0.0.0:8000" -ForegroundColor White
Write-Host ""
Write-Host "Then visit:" -ForegroundColor Cyan
Write-Host "  Admin Panel: http://localhost:8000/admin/" -ForegroundColor White
Write-Host "  API Docs: http://localhost:8000/swagger/" -ForegroundColor White
Write-Host ""
