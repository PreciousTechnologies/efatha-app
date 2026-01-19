# Efatha Church Backend - Setup Guide

## Prerequisites

- Python 3.10 or higher
- PostgreSQL 14 or higher
- pip (Python package manager)
- Virtual environment tool (venv or virtualenv)

---

## Step 1: Install PostgreSQL

### Windows
1. Download PostgreSQL from: https://www.postgresql.org/download/windows/
2. Run the installer
3. Set a password for the `postgres` user (remember this!)
4. Default port: 5432

### Verify Installation
```powershell
psql --version
```

---

## Step 2: Create Database

Open PowerShell and connect to PostgreSQL:

```powershell
# Connect as postgres user
psql -U postgres

# In PostgreSQL prompt, create database
CREATE DATABASE efatha_db;

# Create a user (optional, or use postgres user)
CREATE USER efatha_user WITH PASSWORD 'your_secure_password';

# Grant privileges
GRANT ALL PRIVILEGES ON DATABASE efatha_db TO efatha_user;

# Exit
\q
```

---

## Step 3: Set Up Python Environment

### Navigate to backend folder
```powershell
cd c:\Users\MAXFYNN\Desktop\efatha_app\backend
```

### Create virtual environment
```powershell
python -m venv venv
```

### Activate virtual environment
```powershell
# On Windows PowerShell
.\venv\Scripts\Activate.ps1

# If you get execution policy error, run:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## Step 4: Install Dependencies

```powershell
pip install --upgrade pip
pip install -r requirements.txt
```

---

## Step 5: Configure Environment Variables

### Create `.env` file
Copy the example file:
```powershell
cp .env.example .env
```

### Edit `.env` file with your settings:
```env
# Django Settings
SECRET_KEY=your-secret-key-generate-a-new-one-here
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

# Database Configuration
DB_NAME=efatha_db
DB_USER=postgres
DB_PASSWORD=your_postgres_password_here
DB_HOST=localhost
DB_PORT=5432

# JWT Settings
JWT_ACCESS_TOKEN_LIFETIME=60
JWT_REFRESH_TOKEN_LIFETIME=1440

# CORS Settings (add your Flutter app URLs later)
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000
```

### Generate a secure SECRET_KEY
```powershell
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```
Copy the output and paste it in your `.env` file.

---

## Step 6: Run Migrations

### Create migrations
```powershell
python manage.py makemigrations
```

### Apply migrations
```powershell
python manage.py migrate
```

---

## Step 7: Create Superuser (Admin)

```powershell
python manage.py createsuperuser
```

Follow the prompts:
- Username: admin (or your choice)
- Email: admin@efatha.org
- Password: (choose a strong password)

---

## Step 8: Create Initial Data (Optional)

You can create sample users with different roles:

```powershell
python manage.py shell
```

Then in the Python shell:
```python
from users.models import User

# Create Chief Apostle
User.objects.create_user(
    username='chiefapostle',
    email='chief@efatha.org',
    password='password123',
    first_name='Chief',
    last_name='Apostle',
    role='chief_apostle',
    membership_status='active'
)

# Create Bishop
User.objects.create_user(
    username='bishop',
    email='bishop@efatha.org',
    password='password123',
    first_name='John',
    last_name='Bishop',
    role='bishop',
    membership_status='active'
)

# Create Editor
User.objects.create_user(
    username='editor',
    email='editor@efatha.org',
    password='password123',
    first_name='Jane',
    last_name='Editor',
    role='editor',
    membership_status='active'
)

# Create Member
User.objects.create_user(
    username='member',
    email='member@efatha.org',
    password='password123',
    first_name='Test',
    last_name='Member',
    role='member',
    membership_status='active'
)

# Exit shell
exit()
```

---

## Step 9: Run Development Server

```powershell
python manage.py runserver
```

The server will start at: **http://127.0.0.1:8000/**

---

## Step 10: Test the API

### Access API Documentation
- **Swagger UI**: http://127.0.0.1:8000/swagger/
- **ReDoc**: http://127.0.0.1:8000/redoc/

### Access Admin Panel
- **Admin Panel**: http://127.0.0.1:8000/admin/
- Login with your superuser credentials

---

## Step 11: Test API Endpoints

### Register a new user
```powershell
curl -X POST http://127.0.0.1:8000/api/auth/register/ `
-H "Content-Type: application/json" `
-d '{
  "username": "testuser",
  "email": "test@example.com",
  "password": "testpass123",
  "password_confirm": "testpass123",
  "first_name": "Test",
  "last_name": "User",
  "phone_number": "+254712345678"
}'
```

### Login
```powershell
curl -X POST http://127.0.0.1:8000/api/auth/login/ `
-H "Content-Type: application/json" `
-d '{
  "username": "testuser",
  "password": "testpass123"
}'
```

You'll receive:
```json
{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

### Use the access token for authenticated requests
```powershell
curl -X GET http://127.0.0.1:8000/api/auth/users/me/ `
-H "Authorization: Bearer YOUR_ACCESS_TOKEN_HERE"
```

---

## Common Commands

### Create new migrations after model changes
```powershell
python manage.py makemigrations
python manage.py migrate
```

### Create static files
```powershell
python manage.py collectstatic
```

### Create a new Django app
```powershell
python manage.py startapp app_name
```

### Run tests
```powershell
python manage.py test
```

### Access Django shell
```powershell
python manage.py shell
```

### Flush database (WARNING: Deletes all data)
```powershell
python manage.py flush
```

---

## Project Structure

```
backend/
├── efatha_backend/           # Main project folder
│   ├── __init__.py
│   ├── settings.py          # Django settings
│   ├── urls.py              # Main URL configuration
│   ├── wsgi.py
│   └── asgi.py
├── users/                   # Users app
│   ├── models.py           # User, UserProfile models
│   ├── serializers.py      # API serializers
│   ├── views.py            # API views
│   ├── urls.py             # URL routes
│   ├── admin.py            # Admin interface
│   └── permissions.py      # Custom permissions
├── church/                  # Church app
│   ├── models.py           # Sermon, Event, Prayer, etc.
│   ├── serializers.py
│   ├── views.py
│   ├── urls.py
│   └── admin.py
├── bible/                   # Bible app (to be created)
├── hymns/                   # Hymns app (to be created)
├── manage.py               # Django management script
├── requirements.txt        # Python dependencies
├── .env                    # Environment variables (DON'T COMMIT!)
└── .env.example           # Example environment file
```

---

## Next Steps

1. ✅ **Backend is running**
2. 📝 **Complete remaining apps** (Bible, Hymns)
3. 🔗 **Create API endpoints** for all models
4. 📱 **Connect Flutter app** to backend
5. 🧪 **Write tests** for API endpoints
6. 🚀 **Deploy to production** server

---

## Troubleshooting

### Database connection error
- Check PostgreSQL is running
- Verify database credentials in `.env`
- Ensure database `efatha_db` exists

### Module not found error
- Activate virtual environment
- Run `pip install -r requirements.txt`

### Migration errors
- Delete migration files (except `__init__.py`)
- Run `python manage.py makemigrations` again
- Run `python manage.py migrate --run-syncdb`

### Port already in use
```powershell
# Run on different port
python manage.py runserver 8001
```

---

## Security Checklist

- [ ] Change SECRET_KEY in production
- [ ] Set DEBUG=False in production
- [ ] Use strong database password
- [ ] Enable HTTPS in production
- [ ] Set proper CORS origins
- [ ] Use environment variables for secrets
- [ ] Regular database backups
- [ ] Implement rate limiting
- [ ] Enable CSRF protection
- [ ] Use secure session cookies

---

**Need Help?**  
Check Django documentation: https://docs.djangoproject.com/
Check DRF documentation: https://www.django-rest-framework.org/
