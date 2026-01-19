from rest_framework import serializers
from .models import FavoriteHymn


class FavoriteHymnSerializer(serializers.ModelSerializer):
    class Meta:
        model = FavoriteHymn
        fields = '__all__'
        read_only_fields = ['user', 'created_at']
