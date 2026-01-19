from django.contrib import admin
from .models import FavoriteHymn


@admin.register(FavoriteHymn)
class FavoriteHymnAdmin(admin.ModelAdmin):
    list_display = ['user', 'hymn_number', 'hymn_title', 'category', 'created_at']
    list_filter = ['category']
    search_fields = ['user__username', 'hymn_title', 'hymn_number']
