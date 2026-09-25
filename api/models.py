# api/models.py
from django.db import models
from django.conf import settings

class Trip(models.Model):
    # Link directly to standard auth User instead of an unverified string header
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name="trips",
        db_index=True
    )
    destination = models.CharField(max_length=255)
    days = models.JSONField()  # Stores processed itinerary with estimates
    preferences = models.JSONField(default=dict, blank=True)
    status = models.CharField(max_length=50, default="draft", db_index=True)
    
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.destination} ({self.status}) for {self.user.username}"