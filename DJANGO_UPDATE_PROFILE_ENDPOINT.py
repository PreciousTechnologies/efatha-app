# Django Backend - Update Profile Endpoint
# File: your_app/views.py

from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .serializers import UserSerializer

@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def update_profile(request):
    """
    Update user profile information
    Endpoint: PATCH /api/auth/users/update_profile/
    """
    user = request.user
    
    # Define allowed fields for updating
    user_model_fields = ['first_name', 'last_name', 'email']
    profile_fields = [
        'middle_name', 'phone_number', 'date_of_birth', 'gender', 'marital_status',
        'country', 'region', 'city', 'residence', 'street', 'house_number',
        'postal_address', 'church_position', 'service_region', 'bio'
    ]
    
    # Update User model fields
    for field in user_model_fields:
        if field in request.data:
            setattr(user, field, request.data[field])
    
    try:
        user.save()
    except Exception as e:
        return Response(
            {'detail': f'Failed to update user: {str(e)}'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Update UserProfile fields
    try:
        profile = user.profile  # Assuming OneToOne relationship
    except Exception as e:
        return Response(
            {'detail': f'Profile not found: {str(e)}'},
            status=status.HTTP_404_NOT_FOUND
        )
    
    for field in profile_fields:
        if field in request.data:
            setattr(profile, field, request.data[field])
    
    try:
        profile.save()
    except Exception as e:
        return Response(
            {'detail': f'Failed to update profile: {str(e)}'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Return updated user data
    serializer = UserSerializer(user)
    return Response(serializer.data, status=status.HTTP_200_OK)


# ========================================
# File: your_app/urls.py
# ========================================

from django.urls import path
from .views import update_profile

urlpatterns = [
    # ... existing urls ...
    path('users/update_profile/', update_profile, name='update_profile'),
]


# ========================================
# Testing the endpoint with curl
# ========================================

# curl -X PATCH http://10.103.160.233:8000/api/auth/users/update_profile/ \
#   -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
#   -H "Content-Type: application/json" \
#   -d '{
#     "first_name": "John",
#     "last_name": "Doe",
#     "email": "john.doe@example.com",
#     "phone_number": "+255123456789",
#     "gender": "Male",
#     "marital_status": "Married",
#     "country": "Tanzania",
#     "region": "Dar es Salaam",
#     "city": "Kinondoni",
#     "residence": "Mwenge",
#     "church_position": "Muumini",
#     "service_region": "Mwenge",
#     "bio": "Dedicated member of Efatha Church"
#   }'
