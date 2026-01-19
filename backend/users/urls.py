from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from .views import (
    RegisterView, UserViewSet, 
    send_verification_code, verify_code_and_login, traditional_login,
    get_constants, get_regions_by_country
)

router = DefaultRouter()
router.register(r'users', UserViewSet, basename='user')

urlpatterns = [
    # JWT Authentication (Traditional)
    path('login/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    
    # Email Verification Login
    path('send-code/', send_verification_code, name='send_verification_code'),
    path('verify-code/', verify_code_and_login, name='verify_code_login'),
    
    # Password-based Login
    path('login-password/', traditional_login, name='login_password'),
    
    # User registration
    path('register/', RegisterView.as_view(), name='register'),
    
    # Constants for dropdowns
    path('constants/', get_constants, name='constants'),
    path('regions/', get_regions_by_country, name='regions-by-country'),
    
    # User management
    path('', include(router.urls)),
]
