from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import FavoriteHymnViewSet

router = DefaultRouter()
router.register(r'favorites', FavoriteHymnViewSet, basename='favorite-hymn')

urlpatterns = [
    path('', include(router.urls)),
]
