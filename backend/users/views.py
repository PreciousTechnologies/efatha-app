from rest_framework import generics, status, viewsets
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import get_user_model
from .models import UserProfile
from .models_verification import VerificationCode
from .email_utils import send_verification_code_email, send_welcome_email
from .serializers import (
    UserSerializer, UserRegistrationSerializer,
    ChangePasswordSerializer, UserProfileSerializer
)

User = get_user_model()


class RegisterView(generics.CreateAPIView):
    """User registration endpoint"""
    queryset = User.objects.all()
    permission_classes = (AllowAny,)
    serializer_class = UserRegistrationSerializer
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        
        # Generate JWT tokens
        refresh = RefreshToken.for_user(user)
        
        # Return user data with tokens
        user_serializer = UserSerializer(user)
        
        return Response({
            'user': user_serializer.data,
            'access': str(refresh.access_token),
            'refresh': str(refresh),
        }, status=status.HTTP_201_CREATED)


class UserViewSet(viewsets.ModelViewSet):
    """User profile management"""
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = (IsAuthenticated,)
    
    def get_queryset(self):
        # Users can only see their own profile
        if self.request.user.is_staff:
            return User.objects.all()
        return User.objects.filter(id=self.request.user.id)
    
    @action(detail=False, methods=['get'])
    def me(self, request):
        """Get current user profile"""
        serializer = self.get_serializer(request.user)
        return Response(serializer.data)
    
    @action(detail=False, methods=['put', 'patch'])
    def update_profile(self, request):
        """Update current user profile"""
        serializer = self.get_serializer(
            request.user,
            data=request.data,
            partial=True
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)
    
    @action(detail=False, methods=['post'])
    def change_password(self, request):
        """Change user password"""
        serializer = ChangePasswordSerializer(
            data=request.data,
            context={'request': request}
        )
        serializer.is_valid(raise_exception=True)
        
        user = request.user
        user.set_password(serializer.validated_data['new_password'])
        user.save()
        
        return Response(
            {"message": "Password changed successfully"},
            status=status.HTTP_200_OK
        )
    
    @action(detail=False, methods=['post'])
    def upload_profile_picture(self, request):
        """Upload or update profile picture"""
        if 'profile_picture' not in request.FILES:
            return Response(
                {"error": "No profile picture provided"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        user = request.user
        
        # Delete old profile picture if exists
        if user.profile_picture:
            user.profile_picture.delete(save=False)
        
        user.profile_picture = request.FILES['profile_picture']
        user.save()
        
        serializer = self.get_serializer(user)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    @action(detail=False, methods=['delete'])
    def delete_profile_picture(self, request):
        """Delete profile picture"""
        user = request.user
        
        if user.profile_picture:
            user.profile_picture.delete(save=True)
            return Response(
                {"message": "Profile picture deleted successfully"},
                status=status.HTTP_200_OK
            )
        
        return Response(
            {"message": "No profile picture to delete"},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    @action(detail=False, methods=['patch'])
    def update_bio(self, request):
        """Update user bio"""
        bio = request.data.get('bio')
        
        if bio is None:
            return Response(
                {"error": "Bio field is required"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        user = request.user
        user.bio = bio
        user.save()
        
        serializer = self.get_serializer(user)
        return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([AllowAny])
def send_verification_code(request):
    """
    Send 4-digit verification code to email
    POST /api/auth/send-code/
    Body: { "email": "user@example.com", "purpose": "login" }
    """
    email = request.data.get('email')
    purpose = request.data.get('purpose', 'login')
    
    if not email:
        return Response(
            {"error": "Email is required"},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Validate email format
    import re
    if not re.match(r'^[\w\.-]+@[\w\.-]+\.\w+$', email):
        return Response(
            {"error": "Invalid email format"},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # For login, check if user exists
    if purpose == 'login':
        if not User.objects.filter(email=email).exists():
            return Response(
                {"error": "No account found with this email"},
                status=status.HTTP_404_NOT_FOUND
            )
    
    try:
        # Create verification code
        verification = VerificationCode.create_code(email, purpose)
        
        # Send email
        email_sent = send_verification_code_email(
            email,
            verification.code,
            purpose
        )
        
        if email_sent:
            return Response({
                "message": "Verification code sent to your email",
                "email": email,
                "expires_in_minutes": 10
            }, status=status.HTTP_200_OK)
        else:
            return Response(
                {"error": "Failed to send email. Please try again."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    except Exception as e:
        return Response(
            {"error": f"Error sending verification code: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
@permission_classes([AllowAny])
def verify_code_and_login(request):
    """
    Verify 4-digit code and log user in
    POST /api/auth/verify-code/
    Body: { "email": "user@example.com", "code": "1234" }
    """
    email = request.data.get('email')
    code = request.data.get('code')
    
    if not email or not code:
        return Response(
            {"error": "Email and code are required"},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Verify the code
    is_valid = VerificationCode.verify_code(email, code, purpose='login')
    
    if not is_valid:
        return Response(
            {"error": "Invalid or expired verification code"},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Get user
    try:
        user = User.objects.get(email=email)
    except User.DoesNotExist:
        return Response(
            {"error": "User not found"},
            status=status.HTTP_404_NOT_FOUND
        )
    
    # Generate tokens
    refresh = RefreshToken.for_user(user)
    
    # Serialize user data
    user_serializer = UserSerializer(user)
    
    return Response({
        "message": "Login successful",
        "access": str(refresh.access_token),
        "refresh": str(refresh),
        "user": user_serializer.data
    }, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([AllowAny])
def traditional_login(request):
    """
    Traditional username/email + password login
    POST /api/auth/login-password/
    Body: { "username": "user@example.com", "password": "password123" }
    """
    from django.contrib.auth import authenticate
    
    username = request.data.get('username')  # Can be email or username
    password = request.data.get('password')
    
    if not username or not password:
        return Response(
            {"error": "Username/email and password are required"},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Try to authenticate with email first
    user = None
    if '@' in username:
        try:
            user_obj = User.objects.get(email=username)
            user = authenticate(username=user_obj.username, password=password)
        except User.DoesNotExist:
            pass
    
    # If not found, try username
    if not user:
        user = authenticate(username=username, password=password)
    
    if not user:
        return Response(
            {"error": "Invalid credentials"},
            status=status.HTTP_401_UNAUTHORIZED
        )
    
    # Generate tokens
    refresh = RefreshToken.for_user(user)
    
    # Serialize user data
    user_serializer = UserSerializer(user)
    
    return Response({
        "message": "Login successful",
        "access": str(refresh.access_token),
        "refresh": str(refresh),
        "user": user_serializer.data
    }, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([AllowAny])
def get_constants(request):
    """
    Get application constants (church positions, countries, regions, etc.)
    GET /api/auth/constants/
    """
    
    # Church positions
    church_positions = [
        "Mtume Mkuu",
        "Msaidizi Binafsi wa Mtume Mkuu",
        "Mtume",
        "Mchungaji Kiongozi",
        "Mchungaji",
        "Katibu",
        "Mtawala",
        "Askofu",
        "Cell Leader",
        "Mweka Hazina",
        "Mwanakamati",
        "Mjumbe wa Board",
        "Funguka",
        "ICT",
        "TV",
        "Sunday School Teacher",
        "Walinzi",
        "Muumini"
    ]
    
    # Countries
    countries = [
        "Tanzania",
        "Kenya",
        "Malawi",
        "Zambia",
        "Rwanda",
        "Burundi",
        "Republic of Congo",
        "Mozambique",
        "Botswana",
        "South Africa",
        "South Sudan",
        "UK",
        "USA",
        "Pakistan",
        "India"
    ]
    
    # Tanzania regions
    tanzania_regions = [
        "Arusha",
        "Dar es Salaam",
        "Dodoma",
        "Geita",
        "Iringa",
        "Kagera",
        "Katavi",
        "Kigoma",
        "Kilimanjaro",
        "Lindi",
        "Manyara",
        "Mara",
        "Mbeya",
        "Morogoro",
        "Mtwara",
        "Mwanza",
        "Njombe",
        "Pemba Kaskazini",
        "Pemba Kusini",
        "Pwani",
        "Rukwa",
        "Ruvuma",
        "Shinyanga",
        "Simiyu",
        "Singida",
        "Songwe",
        "Tabora",
        "Tanga",
        "Unguja Kaskazini",
        "Unguja Kusini"
    ]
    
    # Service regions (all countries + Tanzania regions except Dar es Salaam + Mikoa)
    mikoa = [
        "Mwenge",
        "Ushindi",
        "Temeke",
        "Kinondoni",
        "Imara",
        "Yombo",
        "Kisukuru",
        "Zanzibar"
    ]
    
    # Service regions = Countries + Tanzania regions (except Dar) + Mikoa
    service_regions = []
    service_regions.extend(countries)
    service_regions.extend([region for region in tanzania_regions if region != "Dar es Salaam"])
    service_regions.extend(mikoa)
    
    return Response({
        "church_positions": church_positions,
        "countries": countries,
        "tanzania_regions": tanzania_regions,
        "service_regions": service_regions,
        "mikoa": mikoa
    }, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([AllowAny])
def get_regions_by_country(request):
    """
    Get regions for a specific country
    GET /api/auth/regions/?country=Tanzania
    """
    country = request.GET.get('country', '').lower()
    
    if country == 'tanzania':
        regions = [
            "Arusha", "Dar es Salaam", "Dodoma", "Geita", "Iringa",
            "Kagera", "Katavi", "Kigoma", "Kilimanjaro", "Lindi",
            "Manyara", "Mara", "Mbeya", "Morogoro", "Mtwara",
            "Mwanza", "Njombe", "Pemba Kaskazini", "Pemba Kusini",
            "Pwani", "Rukwa", "Ruvuma", "Shinyanga", "Simiyu",
            "Singida", "Songwe", "Tabora", "Tanga",
            "Unguja Kaskazini", "Unguja Kusini"
        ]
        return Response({
            "country": "Tanzania",
            "regions": regions
        }, status=status.HTTP_200_OK)
    else:
        return Response({
            "country": country,
            "regions": []
        }, status=status.HTTP_200_OK)
