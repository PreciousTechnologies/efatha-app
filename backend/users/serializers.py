from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import UserProfile

User = get_user_model()


class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProfile
        fields = [
            'salvation_date', 'baptism_date', 'ministry',
            'emergency_contact_name', 'emergency_contact_phone',
            'marital_status'
        ]


class UserSerializer(serializers.ModelSerializer):
    profile = UserProfileSerializer(read_only=True)
    role_display = serializers.CharField(source='get_role_display_name', read_only=True)
    church_position_display = serializers.CharField(source='get_church_position_display', read_only=True)
    country_display = serializers.CharField(source='get_country_display', read_only=True)
    
    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'first_name', 'middle_name', 'last_name',
            'phone_number', 'profile_picture', 'date_of_birth', 'gender', 'marital_status',
            'role', 'role_display', 'church_position', 'church_position_display',
            'membership_number',
            'country', 'country_display', 'region', 'service_region', 'city',
            'residence', 'street', 'house_number', 'postal_address',
            'bio', 'address', 'receive_notifications', 'preferred_language',
            'profile', 'created_at'
        ]
        read_only_fields = ['id', 'created_at', 'role_display', 'church_position_display', 'country_display']


class UserRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'})
    password_confirm = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'})
    
    class Meta:
        model = User
        fields = [
            'username', 'email', 'password', 'password_confirm',
            'first_name', 'middle_name', 'last_name', 'phone_number',
            'gender', 'date_of_birth', 'marital_status',
            'church_position', 'membership_number', 'service_region',
            'country', 'region', 'city',
            'residence', 'street', 'house_number', 'postal_address'
        ]
    
    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError({"password": "Passwords don't match"})
        return attrs
    
    def create(self, validated_data):
        validated_data.pop('password_confirm')
        user = User.objects.create_user(**validated_data)
        # Create associated profile
        UserProfile.objects.create(user=user)
        return user


class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(required=True, write_only=True)
    new_password = serializers.CharField(required=True, write_only=True)
    
    def validate_old_password(self, value):
        user = self.context['request'].user
        if not user.check_password(value):
            raise serializers.ValidationError("Old password is incorrect")
        return value
