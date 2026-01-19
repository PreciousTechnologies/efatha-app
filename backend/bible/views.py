from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from .models import FavoriteVerse, VerseHighlight
from .serializers import FavoriteVerseSerializer, VerseHighlightSerializer


class FavoriteVerseViewSet(viewsets.ModelViewSet):
    serializer_class = FavoriteVerseSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return FavoriteVerse.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class VerseHighlightViewSet(viewsets.ModelViewSet):
    serializer_class = VerseHighlightSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return VerseHighlight.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
