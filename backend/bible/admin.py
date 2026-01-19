from django.contrib import admin
from .models import FavoriteVerse, VerseHighlight


@admin.register(FavoriteVerse)
class FavoriteVerseAdmin(admin.ModelAdmin):
    list_display = ['user', 'book', 'chapter', 'verse', 'bible_version', 'created_at']
    list_filter = ['bible_version']
    search_fields = ['user__username', 'book', 'verse_text']


@admin.register(VerseHighlight)
class VerseHighlightAdmin(admin.ModelAdmin):
    list_display = ['user', 'book', 'chapter', 'verse', 'color', 'bible_version', 'created_at']
    list_filter = ['color', 'bible_version']
    search_fields = ['user__username', 'book']
