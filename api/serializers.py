# api/serializers.py
from rest_framework import serializers
from .models import Trip


class GenerateRequestSerializer(serializers.Serializer):
    destination = serializers.CharField(max_length=200)
    days = serializers.IntegerField(min_value=1, max_value=30, default=3)
    interests = serializers.ListField(child=serializers.CharField(), required=False, default=list)
    budget = serializers.CharField(max_length=20, required=False, default="mid")


class SearchQuerySerializer(serializers.Serializer):
    q = serializers.CharField(max_length=200)


class TripPatchSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=["draft", "saved", "archived"], required=False)
    days = serializers.JSONField(required=False)


class TripSerializer(serializers.ModelSerializer):
    id = serializers.UUIDField(read_only=True)

    class Meta:
        model = Trip
        fields = [
            "id",
            "user_id",
            "destination",
            "days",
            "preferences",
            "status",
            "created_at",
            "updated_at",
        ]