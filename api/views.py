# api/views.py
import logging
import uuid
from django.shortcuts import get_object_or_404
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status

from .models import Trip
from .serializers import (
    GenerateRequestSerializer,
    SearchQuerySerializer,
    TripPatchSerializer,
    TripSerializer,
)
from . import services

logger = logging.getLogger(__name__)

def _compute_estimates(plan: dict) -> dict:
    """Add estimated_cost per day + global estimates + map markers."""
    total_cost = 0
    markers = []

    for day in plan.get("days", []):
        day_cost = 0
        for act in day.get("activities", []):
            day_cost += act.get("cost", 0)
            if "lat" in act and "lng" in act:
                markers.append({
                    "day": day.get("day"),
                    "lat": act["lat"],
                    "lng": act["lng"],
                    "title": act.get("title", ""),
                })
        day["estimated_cost"] = day_cost
        total_cost += day_cost

    plan["estimates"] = {
        "total_cost": total_cost,
        "markers": markers,
    }
    return plan


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def generate(request):
    ser = GenerateRequestSerializer(data=request.data)
    ser.is_valid(raise_exception=True)
    data = ser.validated_data

    days = data["days"]
    prompt = (
        f"Plan {days} days in {data['destination']}. "
        f"Interests: {', '.join(data['interests']) if data['interests'] else 'sightseeing'}. "
        f"Budget level: {data['budget']}. "
        "Return ONLY valid JSON in this exact shape and no extra text:\n"
        '{"title":"Trip Title","days":[{"day":1,"summary":"...","activities":['
        '{"time":"09:00","title":"Activity","location":"Place","lat":15.5,"lng":73.7,"cost":2000,"type":"food|sight|activity"}'
        "]}]}"
    )

    plan = services.gemini(prompt)
    plan = _compute_estimates(plan)

    trip = Trip.objects.create(
        user=request.user,  # Securely tie to authenticated user
        destination=data["destination"],
        days=plan,
        preferences=data,
        status="draft",
    )

    return Response({"id": str(trip.id), "itinerary": plan}, status=status.HTTP_201_CREATED)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def search(request):
    ser = SearchQuerySerializer(data=request.query_params)
    ser.is_valid(raise_exception=True)
    q = ser.validated_data["q"]

    geo = services.geocode(q)
    results = services.brave_search(f"top attractions in {q}")

    return Response({
        "destination": q,
        "coordinates": geo,
        "results": [
            {
                "title": r.get("title", ""),
                "url": r.get("url", ""),
                "snippet": (r.get("description", "") or "")[:200],
            }
            for r in results
        ],
    })


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def list_trips(request):
    # Only return trips owned by the authenticated user
    trips = Trip.objects.filter(user=request.user)
    return Response([
        {
            "id": str(t.id),
            "destination": t.destination,
            "title": t.days.get("title", "Untitled"),
            "day_count": len(t.days.get("days", [])),
            "status": t.status,
            "updated_at": t.updated_at,
        }
        for t in trips
    ])


@api_view(["GET", "PATCH", "DELETE"])
@permission_classes([IsAuthenticated])
def trip_detail(request, trip_id):
    # Prevent unauthorized users from querying other people's objects
    trip = get_object_or_404(Trip, id=trip_id, user=request.user)

    if request.method == "GET":
        return Response(TripSerializer(trip).data)

    elif request.method == "PATCH":
        ser = TripPatchSerializer(data=request.data)
        ser.is_valid(raise_exception=True)

        if "days" in ser.validated_data:
            trip.days = _compute_estimates(ser.validated_data["days"])
        if "status" in ser.validated_data:
            trip.status = ser.validated_data["status"]
        trip.save()
        return Response(TripSerializer(trip).data)

    elif request.method == "DELETE":
        trip.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


# Keep legacy aliases for routing backward compatibility
generate_itinerary = generate
search_destinations = search