from rest_framework import viewsets, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from .models import Property, Transaction, Viewing, Favorite
from .serializers import PropertySerializer, TransactionSerializer, ViewingSerializer

class PropertyViewSet(viewsets.ModelViewSet):
    queryset = Property.objects.filter(is_available=True)
    serializer_class = PropertySerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['city', 'property_type', 'bedrooms']
    search_fields = ['title', 'description', 'city']
    ordering_fields = ['price', 'created_at']
    ordering = ['-created_at']

    def perform_create(self, serializer):
        serializer.save(agent=self.request.user)

    @action(detail=True, methods=['post'])
    def favorite(self, request, pk=None):
        property_obj = self.get_object()
        favorite, created = Favorite.objects.get_or_create(
            user=request.user,
            property=property_obj
        )
        status_code = status.HTTP_201_CREATED if created else status.HTTP_200_OK
        return Response({'favorited': True}, status=status_code)

    @action(detail=True, methods=['post'])
    def unfavorite(self, request, pk=None):
        property_obj = self.get_object()
        deleted, _ = Favorite.objects.filter(
            user=request.user,
            property=property_obj
        ).delete()
        return Response({'unfavorited': deleted > 0}, status=status.HTTP_200_OK)
