# ============================================
# DJANGO BACKEND - SERMONS VIEWS
# File: church_app/views.py
# ============================================

from rest_framework import viewsets, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q
from .models import Sermon
from .serializers import SermonSerializer
from .permissions import IsEditorOrReadOnly

class SermonViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing sermons with file uploads
    
    Endpoints:
    - GET    /api/church/sermons/          List all sermons (with filters & search)
    - POST   /api/church/sermons/          Create new sermon (editors only)
    - GET    /api/church/sermons/{id}/     Retrieve sermon details
    - PATCH  /api/church/sermons/{id}/     Update sermon (editors only)
    - PUT    /api/church/sermons/{id}/     Replace sermon (editors only)
    - DELETE /api/church/sermons/{id}/     Delete sermon (editors only)
    """
    queryset = Sermon.objects.filter(is_active=True)
    serializer_class = SermonSerializer
    permission_classes = [IsAuthenticated, IsEditorOrReadOnly]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['title', 'pastor', 'topics', 'description', 'category']
    ordering_fields = ['created_at', 'views', 'title', 'pastor']
    ordering = ['-created_at']
    
    def get_queryset(self):
        """
        Filter sermons by category, pastor, topics, or search query
        
        Query parameters:
        - category: Filter by category (exact match)
        - pastor: Filter by pastor name (case-insensitive contains)
        - topics: Filter by topics (case-insensitive contains)
        - search: Search in title, pastor, topics, description, category
        """
        queryset = super().get_queryset()
        
        # Category filter
        category = self.request.query_params.get('category', None)
        if category and category.lower() != 'all':
            queryset = queryset.filter(category__iexact=category)
        
        # Pastor filter
        pastor = self.request.query_params.get('pastor', None)
        if pastor:
            queryset = queryset.filter(pastor__icontains=pastor)
        
        # Topics filter
        topics = self.request.query_params.get('topics', None)
        if topics:
            queryset = queryset.filter(topics__icontains=topics)
        
        # General search (overrides other filters if provided)
        search = self.request.query_params.get('search', None)
        if search:
            queryset = queryset.filter(
                Q(title__icontains=search) |
                Q(pastor__icontains=search) |
                Q(topics__icontains=search) |
                Q(description__icontains=search) |
                Q(category__icontains=search)
            )
        
        return queryset
    
    def list(self, request, *args, **kwargs):
        """List sermons with pagination"""
        queryset = self.filter_queryset(self.get_queryset())
        
        # Pagination
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response({
            'count': queryset.count(),
            'results': serializer.data
        })
    
    def retrieve(self, request, *args, **kwargs):
        """
        Retrieve sermon details and increment view count
        """
        instance = self.get_object()
        
        # Increment view count
        instance.increment_views()
        
        serializer = self.get_serializer(instance)
        return Response(serializer.data)
    
    def create(self, request, *args, **kwargs):
        """
        Create new sermon with file uploads
        Only editors can create sermons
        """
        print(f"📤 Received create request from user: {request.user.username}")
        print(f"📤 Request data: {request.data}")
        print(f"📤 Files: {request.FILES}")
        
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        
        print(f"✅ Sermon created successfully: {serializer.data['id']}")
        
        headers = self.get_success_headers(serializer.data)
        return Response(
            serializer.data,
            status=status.HTTP_201_CREATED,
            headers=headers
        )
    
    def update(self, request, *args, **kwargs):
        """
        Update sermon (full update)
        Only editors can update sermons
        """
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        
        print(f"📤 Updating sermon {instance.id}")
        print(f"📤 Request data: {request.data}")
        print(f"📤 Files: {request.FILES}")
        
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        
        print(f"✅ Sermon {instance.id} updated successfully")
        
        return Response(serializer.data)
    
    def partial_update(self, request, *args, **kwargs):
        """
        Partially update sermon (PATCH)
        Only editors can update sermons
        """
        kwargs['partial'] = True
        return self.update(request, *args, **kwargs)
    
    def destroy(self, request, *args, **kwargs):
        """
        Soft delete sermon (set is_active to False)
        Only editors can delete sermons
        """
        instance = self.get_object()
        
        print(f"🗑️ Soft deleting sermon {instance.id}")
        
        # Soft delete
        instance.is_active = False
        instance.save()
        
        print(f"✅ Sermon {instance.id} soft deleted")
        
        return Response(status=status.HTTP_204_NO_CONTENT)
    
    def perform_create(self, serializer):
        """Set uploaded_by to current user when creating"""
        serializer.save(uploaded_by=self.request.user)
    
    @action(detail=True, methods=['post'])
    def increment_views(self, request, pk=None):
        """
        Manually increment view count
        POST /api/church/sermons/{id}/increment_views/
        """
        sermon = self.get_object()
        sermon.increment_views()
        return Response({'views': sermon.views})
    
    @action(detail=False, methods=['get'])
    def categories(self, request):
        """
        Get list of all unique categories
        GET /api/church/sermons/categories/
        """
        categories = Sermon.objects.filter(is_active=True).values_list(
            'category', flat=True
        ).distinct().order_by('category')
        return Response(list(categories))
    
    @action(detail=False, methods=['get'])
    def pastors(self, request):
        """
        Get list of all unique pastors
        GET /api/church/sermons/pastors/
        """
        pastors = Sermon.objects.filter(is_active=True).values_list(
            'pastor', flat=True
        ).distinct().order_by('pastor')
        return Response(list(pastors))
