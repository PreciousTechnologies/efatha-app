from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from .models import FavoriteHymn
from .serializers import FavoriteHymnSerializer


class FavoriteHymnViewSet(viewsets.ModelViewSet):
    serializer_class = FavoriteHymnSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return FavoriteHymn.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
