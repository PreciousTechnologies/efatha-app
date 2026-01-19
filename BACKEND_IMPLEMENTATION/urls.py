# ============================================
# DJANGO BACKEND - SERMONS URL CONFIGURATION
# File: church_app/urls.py
# ============================================

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import SermonViewSet

# Create router and register viewsets
router = DefaultRouter()
router.register(r'sermons', SermonViewSet, basename='sermon')

urlpatterns = [
    # Church app URLs
    path('church/', include(router.urls)),
]

# This generates the following endpoints:
# GET    /api/church/sermons/                    - List all sermons
# POST   /api/church/sermons/                    - Create sermon
# GET    /api/church/sermons/{id}/               - Get sermon details
# PUT    /api/church/sermons/{id}/               - Update sermon (full)
# PATCH  /api/church/sermons/{id}/               - Update sermon (partial)
# DELETE /api/church/sermons/{id}/               - Delete sermon
# POST   /api/church/sermons/{id}/increment_views/ - Increment views
# GET    /api/church/sermons/categories/         - List categories
# GET    /api/church/sermons/pastors/            - List pastors
