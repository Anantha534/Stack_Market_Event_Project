# api/admin.py
from django.contrib import admin
from .models import Trip


@admin.register(Trip)
class TripAdmin(admin.ModelAdmin):
    list_display = ("destination", "user_id", "status", "created_at")
    list_filter = ("status", "created_at")
    search_fields = ("destination", "user_id")