from django.contrib import admin
from .models import Property, PropertyImage, Transaction, Viewing, Favorite

@admin.register(Property)
class PropertyAdmin(admin.ModelAdmin):
    list_display = ('title', 'price', 'city', 'property_type', 'is_available', 'created_at')
    list_filter = ('property_type', 'is_available', 'city')
    search_fields = ('title', 'description', 'city')
    readonly_fields = ('id', 'view_count', 'created_at', 'updated_at')

@admin.register(PropertyImage)
class PropertyImageAdmin(admin.ModelAdmin):
    list_display = ('property', 'display_order', 'uploaded_at')
    list_filter = ('uploaded_at',)

@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = ('property', 'buyer', 'sale_price', 'status', 'created_at')
    list_filter = ('status', 'created_at')

@admin.register(Viewing)
class ViewingAdmin(admin.ModelAdmin):
    list_display = ('property', 'buyer', 'scheduled_date', 'status')
    list_filter = ('status', 'scheduled_date')

@admin.register(Favorite)
class FavoriteAdmin(admin.ModelAdmin):
    list_display = ('user', 'property', 'created_at')
    list_filter = ('created_at',)
