from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    SermonViewSet, EventViewSet, EventRegistrationViewSet,
    PrayerRequestViewSet, PrayerRequestImageViewSet, PrayerCommentViewSet,
    TestimonyViewSet, GivingViewSet, AnnouncementViewSet, LiveStreamViewSet, LiveChatMessageViewSet
)

router = DefaultRouter()
router.register(r'sermons', SermonViewSet, basename='sermon')
router.register(r'events', EventViewSet, basename='event')
router.register(r'event-registrations', EventRegistrationViewSet, basename='event-registration')
router.register(r'prayer-requests', PrayerRequestViewSet, basename='prayer-request')
router.register(r'prayer-images', PrayerRequestImageViewSet, basename='prayer-image')
router.register(r'prayer-comments', PrayerCommentViewSet, basename='prayer-comment')
router.register(r'testimonies', TestimonyViewSet, basename='testimony')
router.register(r'giving', GivingViewSet, basename='giving')
router.register(r'announcements', AnnouncementViewSet, basename='announcement')
router.register(r'live-streams', LiveStreamViewSet, basename='live-stream')
router.register(r'live-chat', LiveChatMessageViewSet, basename='live-chat')

urlpatterns = [
    path('', include(router.urls)),
]
