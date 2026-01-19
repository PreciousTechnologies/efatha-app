#!/usr/bin/env python
import os
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'efatha_backend.settings')
django.setup()

from church.models import Sermon

# Check all sermons
all_sermons = Sermon.objects.all()
print(f"\n📊 Total sermons in database: {all_sermons.count()}")

for sermon in all_sermons:
    print(f"\n  Sermon #{sermon.id}:")
    print(f"    Title: {sermon.title}")
    print(f"    Pastor: {sermon.preacher}")
    print(f"    Category: {sermon.category}")
    print(f"    is_active: {sermon.is_active} ⚠️" if not sermon.is_active else f"    is_active: {sermon.is_active} ✅")
    print(f"    Views: {sermon.views}")

# Fix inactive sermons
inactive = Sermon.objects.filter(is_active=False)
if inactive.count() > 0:
    print(f"\n⚠️ Found {inactive.count()} inactive sermon(s)!")
    print("   Activating them now...")
    inactive.update(is_active=True)
    print("✅ All sermons activated!")
else:
    print("\n✅ All sermons are already active")

# Show active sermons
active = Sermon.objects.filter(is_active=True)
print(f"\n✅ Active sermons: {active.count()}")
