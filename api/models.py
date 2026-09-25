# api/models.py
import uuid
from django.db import models


class Trip(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user_id = models.CharField(max_length=100, default="demo", db_index=True)
    destination = models.CharField(max_length=200)
    days = models.JSONField(default=dict)
    preferences = models.JSONField(default=dict)
    status = models.CharField(max_length=20, default="draft")  # draft | saved | archived
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-updated_at"]

    def __str__(self):
        return f"{self.destination} ({self.status})"