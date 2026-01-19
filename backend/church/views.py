from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.exceptions import PermissionDenied
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import filters
from django.db import models as django_models
from .models import (
    Sermon, Event, EventRegistration, PrayerRequest,
    PrayerSupport, PrayerRequestImage, PrayerComment,
    Testimony, TestimonyPraise, Giving, PaymentTransaction, Announcement, LiveStream, LiveChatMessage
)
from .serializers import (
    SermonSerializer, EventSerializer, EventRegistrationSerializer,
    PrayerRequestSerializer, PrayerRequestImageSerializer, 
    PrayerCommentSerializer, TestimonySerializer, GivingSerializer,
    PaymentTransactionSerializer, AnnouncementSerializer, LiveStreamSerializer, LiveChatMessageSerializer
)
from users.permissions import CanEditContent, CanApproveContent


class SermonViewSet(viewsets.ModelViewSet):
    queryset = Sermon.objects.filter(is_active=True)
    serializer_class = SermonSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['category', 'preacher', 'is_featured']
    search_fields = ['title', 'description', 'preacher', 'topics', 'scripture_reference']
    ordering_fields = ['sermon_date', 'created_at', 'views']
    ordering = ['-created_at']
    
    def get_permissions(self):
        """Allow read for all authenticated, write for editors only"""
        if self.action in ['list', 'retrieve']:
            return [IsAuthenticated()]
        # For create, update, destroy - check if user is editor
        return [IsAuthenticated(), CanEditContent()]
    
    def get_queryset(self):
        """Filter sermons with enhanced search"""
        queryset = Sermon.objects.filter(is_active=True)
        
        # Filter by category
        category = self.request.query_params.get('category')
        if category:
            queryset = queryset.filter(category__iexact=category)
        
        # Filter by pastor/preacher
        pastor = self.request.query_params.get('pastor')
        if pastor:
            queryset = queryset.filter(preacher__icontains=pastor)
        
        # Filter by topics (comma-separated)
        topics = self.request.query_params.get('topics')
        if topics:
            topic_list = [t.strip() for t in topics.split(',')]
            for topic in topic_list:
                queryset = queryset.filter(topics__icontains=topic)
        
        # Search across multiple fields
        search = self.request.query_params.get('search')
        if search:
            from django.db.models import Q
            queryset = queryset.filter(
                Q(title__icontains=search) |
                Q(description__icontains=search) |
                Q(preacher__icontains=search) |
                Q(topics__icontains=search)
            )
        
        return queryset.order_by('-created_at')
    
    def retrieve(self, request, *args, **kwargs):
        """Increment view count when sermon is retrieved"""
        instance = self.get_object()
        instance.increment_views()
        serializer = self.get_serializer(instance)
        print(f"📖 Sermon retrieved: {instance.title} (Views: {instance.views})")
        return Response(serializer.data)
    
    def create(self, request, *args, **kwargs):
        """Create new sermon"""
        print(f"📤 Creating sermon: {request.data.get('title')}")
        print(f"   Pastor: {request.data.get('pastor')}")
        print(f"   Category: {request.data.get('category')}")
        print(f"   Has audio: {bool(request.FILES.get('audio_file'))}")
        print(f"   Has video: {bool(request.FILES.get('video_file'))}")
        print(f"   All data keys: {list(request.data.keys())}")
        print(f"   All file keys: {list(request.FILES.keys())}")
        
        serializer = self.get_serializer(data=request.data)
        if not serializer.is_valid():
            print(f"❌ Validation errors: {serializer.errors}")
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        self.perform_create(serializer)
        
        print(f"✅ Sermon created successfully: ID {serializer.data['id']}")
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
    def update(self, request, *args, **kwargs):
        """Update existing sermon"""
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        
        print(f"📝 Updating sermon: {instance.title} (ID: {instance.id})")
        
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        
        print(f"✅ Sermon updated successfully")
        return Response(serializer.data)
    
    def destroy(self, request, *args, **kwargs):
        """Soft delete sermon"""
        instance = self.get_object()
        instance.is_active = False
        instance.save()
        
        print(f"🗑️ Sermon soft deleted: {instance.title}")
        return Response(status=status.HTTP_204_NO_CONTENT)
    
    @action(detail=False, methods=['get'])
    def categories(self, request):
        """Get list of all unique categories"""
        categories = Sermon.objects.filter(is_active=True).values_list('category', flat=True).distinct()
        return Response(list(categories))
    
    @action(detail=False, methods=['get'])
    def pastors(self, request):
        """Get list of all unique pastors"""
        pastors = Sermon.objects.filter(is_active=True).values_list('preacher', flat=True).distinct()
        return Response(list(pastors))
    
    @action(detail=True, methods=['post'])
    def increment_view(self, request, pk=None):
        """Increment view count manually"""
        sermon = self.get_object()
        old_views = sermon.views
        sermon.increment_views()
        print(f"🔢 View count updated: {old_views} → {sermon.views} for '{sermon.title}'")
        return Response({'views': sermon.views})


class EventViewSet(viewsets.ModelViewSet):
    queryset = Event.objects.filter(is_published=True)
    serializer_class = EventSerializer
    permission_classes = [IsAuthenticated, CanEditContent]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['category', 'requires_registration']
    search_fields = ['title', 'description', 'location']
    ordering_fields = ['start_date', 'created_at']
    ordering = ['start_date']
    
    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [AllowAny()]
        return super().get_permissions()
    
    def perform_create(self, serializer):
        serializer.save(organizer=self.request.user)


class EventRegistrationViewSet(viewsets.ModelViewSet):
    queryset = EventRegistration.objects.all()
    serializer_class = EventRegistrationSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['event', 'attended']
    
    def get_queryset(self):
        # Users can only see their own registrations unless they're leadership
        if self.request.user.has_leadership_role():
            return EventRegistration.objects.all()
        return EventRegistration.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class PrayerRequestViewSet(viewsets.ModelViewSet):
    queryset = PrayerRequest.objects.all()
    serializer_class = PrayerRequestSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['category', 'is_answered', 'priority']
    ordering_fields = ['created_at', 'priority']
    ordering = ['-created_at']
    
    def get_queryset(self):
        # Show all prayer requests but respect anonymous setting
        queryset = PrayerRequest.objects.all()
        
        # Filter for "My Prayers" - user's own prayer requests
        my_prayers = self.request.query_params.get('my_prayers', None)
        if my_prayers == 'true':
            queryset = queryset.filter(user=self.request.user)
        
        return queryset
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
    
    def perform_update(self, serializer):
        # Only allow user to update their own prayer requests
        prayer_request = self.get_object()
        if prayer_request.user != self.request.user:
            raise PermissionDenied("You can only edit your own prayer requests")
        serializer.save()
    
    def perform_destroy(self, instance):
        # Only allow user to delete their own prayer requests
        if instance.user != self.request.user:
            raise PermissionDenied("You can only delete your own prayer requests")
        instance.delete()
    
    @action(detail=True, methods=['post'])
    def pray(self, request, pk=None):
        """Mark that user is praying for this request"""
        prayer_request = self.get_object()
        support, created = PrayerSupport.objects.get_or_create(
            prayer_request=prayer_request,
            user=request.user
        )
        if not created:
            # If already praying, remove support (toggle)
            support.delete()
            return Response({'message': 'Prayer support removed', 'is_praying': False})
        return Response({'message': 'Prayer support added', 'is_praying': True})
    
    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated, CanApproveContent])
    def mark_answered(self, request, pk=None):
        """Mark prayer request as answered"""
        prayer_request = self.get_object()
        prayer_request.is_answered = True
        prayer_request.save()
        return Response({'message': 'Prayer request marked as answered'})
    
    @action(detail=True, methods=['post'], url_path='upload-images')
    def upload_images(self, request, pk=None):
        """Upload multiple images to a prayer request"""
        prayer_request = self.get_object()
        
        # Check if user owns this prayer request
        if prayer_request.user != request.user:
            raise PermissionDenied("You can only upload images to your own prayer requests")
        
        images = request.FILES.getlist('images')
        captions = request.data.getlist('captions', [])
        
        created_images = []
        for idx, image_file in enumerate(images):
            caption = captions[idx] if idx < len(captions) else ""
            prayer_image = PrayerRequestImage.objects.create(
                prayer_request=prayer_request,
                image=image_file,
                caption=caption
            )
            created_images.append(prayer_image)
        
        serializer = PrayerRequestImageSerializer(
            created_images, 
            many=True, 
            context={'request': request}
        )
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class PrayerRequestImageViewSet(viewsets.ModelViewSet):
    """ViewSet for managing prayer request images"""
    queryset = PrayerRequestImage.objects.all()
    serializer_class = PrayerRequestImageSerializer
    permission_classes = [IsAuthenticated]
    
    def perform_create(self, serializer):
        prayer_request_id = self.request.data.get('prayer_request')
        prayer_request = PrayerRequest.objects.get(id=prayer_request_id)
        
        # Check if user owns this prayer request
        if prayer_request.user != self.request.user:
            raise PermissionDenied("You can only add images to your own prayer requests")
        
        serializer.save()
    
    def perform_destroy(self, instance):
        # Only allow user to delete images from their own prayer requests
        if instance.prayer_request.user != self.request.user:
            raise PermissionDenied("You can only delete images from your own prayer requests")
        instance.delete()


class PrayerCommentViewSet(viewsets.ModelViewSet):
    """ViewSet for managing prayer request comments"""
    queryset = PrayerComment.objects.all()
    serializer_class = PrayerCommentSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['prayer_request']
    ordering = ['-created_at']
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
    
    def perform_update(self, serializer):
        # Only allow user to update their own comments
        comment = self.get_object()
        if comment.user != self.request.user:
            raise PermissionDenied("You can only edit your own comments")
        serializer.save()
    
    def perform_destroy(self, instance):
        # Only allow user to delete their own comments
        if instance.user != self.request.user:
            raise PermissionDenied("You can only delete your own comments")
        instance.delete()


class TestimonyViewSet(viewsets.ModelViewSet):
    queryset = Testimony.objects.filter(is_approved=True)
    serializer_class = TestimonySerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['is_featured']
    ordering_fields = ['created_at']
    ordering = ['-created_at']
    
    def get_queryset(self):
        # Show approved testimonies to all, but users can see their own pending ones
        if self.request.user.has_leadership_role():
            return Testimony.objects.all()
        return Testimony.objects.filter(
            django_models.Q(is_approved=True) | django_models.Q(user=self.request.user)
        )
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
    
    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated, CanApproveContent])
    def approve(self, request, pk=None):
        """Approve a testimony"""
        testimony = self.get_object()
        testimony.is_approved = True
        testimony.save()
        return Response({'message': 'Testimony approved'})
    
    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated, CanApproveContent])
    def feature(self, request, pk=None):
        """Feature a testimony"""
        testimony = self.get_object()
        testimony.is_featured = not testimony.is_featured
        testimony.save()
        return Response({'is_featured': testimony.is_featured})
    
    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def praise(self, request, pk=None):
        """Toggle praise on a testimony"""
        testimony = self.get_object()
        user = request.user
        
        # Check if user already praised
        praise = TestimonyPraise.objects.filter(testimony=testimony, user=user).first()
        
        if praise:
            # Remove praise
            praise.delete()
            return Response({
                'message': 'Praise removed',
                'praised': False,
                'praise_count': testimony.praises.count()
            })
        else:
            # Add praise
            TestimonyPraise.objects.create(testimony=testimony, user=user)
            return Response({
                'message': 'Testimony praised',
                'praised': True,
                'praise_count': testimony.praises.count()
            }, status=status.HTTP_201_CREATED)


class GivingViewSet(viewsets.ModelViewSet):
    queryset = Giving.objects.all()
    serializer_class = GivingSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['giving_type', 'payment_method', 'payment_status', 'currency']
    ordering_fields = ['created_at', 'amount']
    ordering = ['-created_at']
    
    def get_queryset(self):
        # Users can only see their own giving records unless they're leadership
        if self.request.user.has_leadership_role():
            return Giving.objects.all()
        return Giving.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        # Assign user if authenticated, otherwise use donor info
        if self.request.user.is_authenticated and not serializer.validated_data.get('is_anonymous'):
            serializer.save(user=self.request.user)
        else:
            serializer.save()
    
    @action(detail=False, methods=['post'], permission_classes=[AllowAny])
    def create_payment(self, request):
        """
        Create a giving record and initiate payment
        Accepts anonymous donations
        """
        from django.utils import timezone
        import uuid
        
        # Extract data
        amount = request.data.get('amount')
        currency = request.data.get('currency', 'USD')
        giving_type = request.data.get('giving_type')
        payment_method = request.data.get('payment_method')
        donor_name = request.data.get('donor_name', '')
        donor_email = request.data.get('donor_email', '')
        donor_phone = request.data.get('donor_phone', '')
        notes = request.data.get('notes', '')
        is_anonymous = request.data.get('is_anonymous', False)
        is_recurring = request.data.get('is_recurring', False)
        recurring_frequency = request.data.get('recurring_frequency', '')
        
        # Validate required fields
        if not all([amount, giving_type]):
            return Response(
                {'error': 'Amount and giving_type are required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            # Generate unique merchant reference
            merchant_reference = f"EFA-{uuid.uuid4().hex[:12].upper()}"
            
            # Create giving record
            giving_data = {
                'amount': amount,
                'currency': currency,
                'giving_type': giving_type,
                'payment_method': payment_method,
                'donor_name': donor_name,
                'donor_email': donor_email,
                'donor_phone': donor_phone,
                'notes': notes,
                'is_anonymous': is_anonymous,
                'is_recurring': is_recurring,
                'recurring_frequency': recurring_frequency,
                'merchant_reference': merchant_reference,
                'payment_status': 'pending',
            }
            
            # Add user if authenticated and not anonymous
            if request.user.is_authenticated and not is_anonymous:
                giving_data['user'] = request.user
            
            giving = Giving.objects.create(**giving_data)
            
            # Return giving ID and merchant reference
            serializer = GivingSerializer(giving, context={'request': request})
            return Response({
                'giving_id': giving.id,
                'merchant_reference': merchant_reference,
                'data': serializer.data
            }, status=status.HTTP_201_CREATED)
            
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )
    
    @action(detail=False, methods=['post'], permission_classes=[AllowAny])
    def verify_payment(self, request):
        """
        Verify payment and update giving status
        Called after payment gateway callback
        """
        from django.utils import timezone
        
        merchant_reference = request.data.get('merchant_reference')
        order_tracking_id = request.data.get('order_tracking_id')
        transaction_id = request.data.get('transaction_id')
        confirmation_code = request.data.get('confirmation_code')
        payment_method = request.data.get('payment_method')
        payment_status = request.data.get('payment_status')
        amount = request.data.get('amount')
        currency = request.data.get('currency')
        
        if not merchant_reference:
            return Response(
                {'error': 'Merchant reference is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            # Find the giving record
            giving = Giving.objects.get(merchant_reference=merchant_reference)
            
            # Create payment transaction record
            transaction = PaymentTransaction.objects.create(
                giving=giving,
                transaction_id=transaction_id or f"TXN-{timezone.now().timestamp()}",
                order_tracking_id=order_tracking_id or '',
                merchant_reference=merchant_reference,
                gateway=request.data.get('gateway', 'pesapal'),
                status='completed' if payment_status == 'completed' else 'failed',
                amount=amount or giving.amount,
                currency=currency or giving.currency,
                payment_method=payment_method or giving.payment_method,
                confirmation_code=confirmation_code or '',
                payment_status_description=request.data.get('payment_status_description', ''),
                request_data=request.data.get('request_data'),
                response_data=request.data.get('response_data'),
                callback_data=request.data,
                ip_address=request.META.get('REMOTE_ADDR'),
                user_agent=request.META.get('HTTP_USER_AGENT', ''),
            )
            
            # Update giving record
            if payment_status == 'completed':
                giving.payment_status = 'completed'
                giving.completed_at = timezone.now()
                giving.confirmation_code = confirmation_code or ''
                if payment_method:
                    giving.payment_method = payment_method
                transaction.mark_completed(confirmation_code, payment_method)
            else:
                giving.payment_status = 'failed'
                transaction.mark_failed(request.data.get('error_message', 'Payment failed'))
            
            giving.pesapal_tracking_id = order_tracking_id or ''
            giving.save()
            
            serializer = GivingSerializer(giving, context={'request': request})
            return Response({
                'message': 'Payment verified successfully',
                'giving': serializer.data,
                'transaction_id': transaction.id
            })
            
        except Giving.DoesNotExist:
            return Response(
                {'error': 'Giving record not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )
    
    @action(detail=True, methods=['get'], permission_classes=[AllowAny])
    def transactions(self, request, pk=None):
        """Get all transactions for a giving record"""
        giving = self.get_object()
        transactions = giving.transactions.all()
        serializer = PaymentTransactionSerializer(transactions, many=True)
        return Response(serializer.data)


class AnnouncementViewSet(viewsets.ModelViewSet):
    queryset = Announcement.objects.filter(is_published=True)
    serializer_class = AnnouncementSerializer
    permission_classes = [IsAuthenticated, CanEditContent]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['priority']
    ordering_fields = ['publish_date', 'priority']
    ordering = ['-priority', '-publish_date']
    
    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [AllowAny()]
        return super().get_permissions()
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)


class LiveStreamViewSet(viewsets.ModelViewSet):
    """ViewSet for managing live streams"""
    queryset = LiveStream.objects.all()
    serializer_class = LiveStreamSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status']
    search_fields = ['title', 'description']
    ordering_fields = ['created_at', 'scheduled_for']
    ordering = ['-created_at']
    
    def get_permissions(self):
        """Allow read for all authenticated, write for editors only"""
        if self.action in ['list', 'retrieve']:
            return [IsAuthenticated()]
        # For create, update, destroy - check if user is editor
        return [IsAuthenticated(), CanEditContent()]
    
    def perform_create(self, serializer):
        """Set the creator when creating a stream"""
        serializer.save(created_by=self.request.user)


class LiveChatMessageViewSet(viewsets.ModelViewSet):
    """ViewSet for managing live chat messages"""
    serializer_class = LiveChatMessageSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['live_stream']
    ordering = ['created_at']
    
    def get_queryset(self):
        """Get chat messages for a specific live stream"""
        queryset = LiveChatMessage.objects.select_related('user').all()
        
        # Filter by live stream if provided
        stream_id = self.request.query_params.get('live_stream')
        if stream_id:
            queryset = queryset.filter(live_stream_id=stream_id)
        
        # Limit to last 100 messages by default
        limit = int(self.request.query_params.get('limit', 100))
        queryset = queryset.order_by('-created_at')[:limit]
        
        return queryset.order_by('created_at')
    
    def perform_create(self, serializer):
        """Set the user when creating a message"""
        serializer.save(user=self.request.user)
