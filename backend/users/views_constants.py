from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from efatha_backend.constants import (
    COUNTRIES, TANZANIA_REGIONS, SERVICE_REGIONS, CHURCH_POSITIONS
)


@api_view(['GET'])
@permission_classes([AllowAny])
def get_constants(request):
    """Get all app constants for dropdowns"""
    return Response({
        'countries': COUNTRIES,
        'tanzania_regions': TANZANIA_REGIONS,
        'service_regions': SERVICE_REGIONS,
        'church_positions': CHURCH_POSITIONS,
    })


@api_view(['GET'])
@permission_classes([AllowAny])
def get_regions_by_country(request):
    """Get regions based on selected country"""
    country = request.query_params.get('country', '').lower()
    
    if country == 'tanzania':
        return Response({'regions': TANZANIA_REGIONS})
    else:
        # For other countries, return empty or country name as region
        return Response({'regions': []})
