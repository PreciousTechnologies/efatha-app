# ============================================
# DJANGO BACKEND - SERMONS PERMISSIONS
# File: church_app/permissions.py
# ============================================

from rest_framework import permissions

class IsEditorOrReadOnly(permissions.BasePermission):
    """
    Custom permission:
    - Any authenticated user can read sermons (GET)
    - Only editors can create/update/delete sermons (POST, PUT, PATCH, DELETE)
    """
    
    def has_permission(self, request, view):
        # Allow read permissions for all authenticated users
        if request.method in permissions.SAFE_METHODS:
            return request.user and request.user.is_authenticated
        
        # Write permissions only for editors
        if not request.user or not request.user.is_authenticated:
            return False
        
        # Check if user has 'editor' role
        return hasattr(request.user, 'role') and request.user.role == 'editor'
    
    def has_object_permission(self, request, view, obj):
        # Read permissions for all authenticated users
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Write permissions only for editors
        if not request.user or not request.user.is_authenticated:
            return False
        
        return hasattr(request.user, 'role') and request.user.role == 'editor'
