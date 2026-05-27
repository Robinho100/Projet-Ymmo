from django.contrib import admin
from .models import UserProfile, Agent

@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'role', 'is_verified')
    list_filter = ('role', 'is_verified')
    search_fields = ('user__username', 'user__email')

@admin.register(Agent)
class AgentAdmin(admin.ModelAdmin):
    list_display = ('user', 'agency_name', 'license_number', 'rating', 'properties_sold')
    list_filter = ('is_verified', 'created_at')
    search_fields = ('user__username', 'license_number', 'agency_name')
