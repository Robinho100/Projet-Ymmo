from rest_framework import serializers
from .models import Property, PropertyImage, Transaction, Viewing, Favorite

class PropertyImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = PropertyImage
        fields = ['id', 'image_url', 'thumbnail_url', 'alt_text', 'display_order']

class PropertySerializer(serializers.ModelSerializer):
    images = PropertyImageSerializer(many=True, read_only=True)
    agent_name = serializers.CharField(source='agent.get_full_name', read_only=True)
    favorite_count = serializers.SerializerMethodField()

    class Meta:
        model = Property
        fields = [
            'id', 'title', 'description', 'price', 'address', 'city', 'postal_code',
            'property_type', 'square_meters', 'bedrooms', 'bathrooms',
            'has_garage', 'has_garden', 'has_pool', 'energy_rating', 'condition',
            'agent', 'agent_name', 'is_available', 'is_featured', 'view_count',
            'images', 'favorite_count', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'view_count', 'created_at', 'updated_at']

    def get_favorite_count(self, obj):
        return obj.favorited_by.count()

class TransactionSerializer(serializers.ModelSerializer):
    property_title = serializers.CharField(source='property.title', read_only=True)

    class Meta:
        model = Transaction
        fields = [
            'id', 'property', 'property_title', 'buyer', 'agent', 'sale_price',
            'status', 'transaction_date', 'completion_date', 'commission_amount', 'notes'
        ]

class ViewingSerializer(serializers.ModelSerializer):
    property_title = serializers.CharField(source='property.title', read_only=True)

    class Meta:
        model = Viewing
        fields = [
            'id', 'property', 'property_title', 'buyer', 'agent',
            'scheduled_date', 'status', 'notes', 'created_at'
        ]
