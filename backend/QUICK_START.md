# Quick Start Guide - Efatha Church Backend

## Prerequisites Installed ✅
- Python 3.10+
- PostgreSQL 14+
- Git

## Step 1: Start PostgreSQL

Make sure PostgreSQL is running. If not:
```powershell
# Start PostgreSQL service
Start-Service postgresql-x64-14  # Adjust version as needed
```

## Step 2: Setup Backend

```powershell
# Navigate to backend
cd C:\Users\MAXFYNN\Desktop\efatha_app\backend

# Create virtual environment
python -m venv venv

# Activate virtual environment  
.\venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements.txt

# Run migrations
python manage.py makemigrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser
# Username: admin
# Email: admin@efatha.org
# Password: (your choice)

# Run server
python manage.py runserver
```

## Step 3: Test API

Open browser:
- **API Docs**: http://localhost:8000/swagger/
- **Admin Panel**: http://localhost:8000/admin/

## Step 4: Create Test Data (Optional)

```powershell
python manage.py shell
```

Then run:
```python
from users.models import User

# Create sample users with different roles
User.objects.create_user(
    username='chiefapostle',
    email='chief@efatha.org',
    password='efatha2025',
    first_name='Mtume',
    last_name='Mkuu',
    role='chief_apostle',
    church_position='mtume_mkuu',
    country='tanzania',
    region='Dar es Salaam',
    service_region='Kinondoni',
    membership_status='active'
)

User.objects.create_user(
    username='member1',
    email='member@efatha.org',
    password='efatha2025',
    first_name='John',
    last_name='Doe',
    role='member',
    church_position='muumini',
    country='tanzania',
    membership_status='active'
)

exit()
```

## API Endpoints Available

### Authentication
- `POST /api/auth/register/` - Register new user
- `POST /api/auth/login/` - Login (get JWT tokens)
- `POST /api/auth/refresh/` - Refresh access token
- `GET /api/auth/users/me/` - Get current user profile

### Constants (for dropdowns)
- `GET /api/auth/constants/` - Get all constants (countries, regions, positions)
- `GET /api/auth/regions/?country=tanzania` - Get regions by country

### Church
- `GET /api/church/sermons/` - List sermons
- `GET /api/church/events/` - List events
- `POST /api/church/prayer-requests/` - Submit prayer request
- `POST /api/church/testimonies/` - Submit testimony
- `POST /api/church/giving/` - Record giving

### Bible
- `GET /api/bible/favorites/` - Get favorite verses
- `POST /api/bible/favorites/` - Add favorite verse
- `GET /api/bible/highlights/` - Get highlighted verses
- `POST /api/bible/highlights/` - Add verse highlight

### Hymns
- `GET /api/hymns/favorites/` - Get favorite hymns
- `POST /api/hymns/favorites/` - Add favorite hymn

## Database Info

```
Database: efatha_db
User: postgres
Password: kiburuta1
Host: localhost
Port: 5432
```

## Next: Connect Flutter App

See `FLUTTER_INTEGRATION.md` for Flutter setup instructions.
