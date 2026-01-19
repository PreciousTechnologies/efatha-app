from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import FavoriteVerseViewSet, VerseHighlightViewSet

router = DefaultRouter()
router.register(r'favorites', FavoriteVerseViewSet, basename='favorite-verse')
router.register(r'highlights', VerseHighlightViewSet, basename='verse-highlight')

urlpatterns = [
    path('', include(router.urls)),
]
