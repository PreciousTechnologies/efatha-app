#!/usr/bin/env python
import os
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'efatha_backend.settings')
django.setup()

from users.models import User

# Check for editor users
editors = User.objects.filter(role='editor')
print(f"\n✅ Found {editors.count()} editor(s):")
for editor in editors:
    print(f"  - Username: {editor.username}")
    print(f"    Email: {editor.email}")
    print(f"    Name: {editor.get_full_name()}")
    print(f"    Role: {editor.role}")
    print()

if editors.count() == 0:
    print("⚠️ No editors found! Creating one...\n")
    
    # Create an editor user
    editor = User.objects.create_user(
        username='editor1',
        email='editor@efatha.org',
        password='editor123',
        first_name='John',
        last_name='Editor',
        role='editor'
    )
    print(f"✅ Created editor user:")
    print(f"   Username: {editor.username}")
    print(f"   Password: editor123")
    print(f"   Email: {editor.email}")
    print()
