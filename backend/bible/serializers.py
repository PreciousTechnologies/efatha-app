from rest_framework import serializers
from .models import FavoriteVerse, VerseHighlight


class FavoriteVerseSerializer(serializers.ModelSerializer):
    class Meta:
        model = FavoriteVerse
        fields = '__all__'
        read_only_fields = ['user', 'created_at']


class VerseHighlightSerializer(serializers.ModelSerializer):
    class Meta:
        model = VerseHighlight
        fields = '__all__'
        read_only_fields = ['user', 'created_at']
