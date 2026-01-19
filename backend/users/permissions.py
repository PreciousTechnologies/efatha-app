from rest_framework import permissions


class IsAdminRole(permissions.BasePermission):
    """Only Admin can access"""
    
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == 'admin'


class IsLeadershipRole(permissions.BasePermission):
    """Leadership roles: Admin, Chief Apostle, Katibu Kiongozi, Apostle, Senior Pastor, Bishop"""
    
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        return request.user.has_leadership_role()


class CanEditContent(permissions.BasePermission):
    """Can edit content: Admin, Editor, Data Entry, and Leadership"""
    
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        
        # Allow read access to everyone
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Allow write access to those who can edit
        return request.user.can_edit_content()


class CanApproveContent(permissions.BasePermission):
    """Can approve content: Admin, Chief Apostle, Senior Pastor, Bishop"""
    
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        return request.user.can_approve_content()


class CanManageUsers(permissions.BasePermission):
    """Can manage users: Admin, Chief Apostle, Katibu Kiongozi"""
    
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        return request.user.can_manage_users()


class IsOwnerOrReadOnly(permissions.BasePermission):
    """
    Object-level permission to only allow owners of an object to edit it.
    """
    
    def has_object_permission(self, request, view, obj):
        # Read permissions are allowed to any request
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Write permissions are only allowed to the owner
        return obj.user == request.user


class IsOwnerOrLeadership(permissions.BasePermission):
    """
    Object-level permission for owner or leadership roles.
    """
    
    def has_object_permission(self, request, view, obj):
        # Read permissions allowed for authenticated users
        if request.method in permissions.SAFE_METHODS:
            return request.user.is_authenticated
        
        # Write permissions for owner or leadership
        if hasattr(obj, 'user'):
            is_owner = obj.user == request.user
        else:
            is_owner = obj == request.user
        
        return is_owner or request.user.has_leadership_role()
