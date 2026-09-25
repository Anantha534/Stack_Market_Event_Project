# api/views.py
from datetime import datetime
from bson import ObjectId
from bson.errors import InvalidId

from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status

from .db import trips_collection
from .serializers import (
    GenerateRequestSerializer,
    SearchQuerySerializer,
    TripPatchSerializer,
)
from . import services


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


def _format_trip_document(doc: dict) -> dict:
    """Convert MongoDB Document ObjectId and dates to JSON-friendly format."""
    if not doc:
        return None
    return {
        "id": str(doc["_id"]),
        "user_id": doc.get("user_id"),
        "destination": doc.get("destination"),
        "days": doc.get("days", {}),
        "preferences": doc.get("preferences", {}),
        "status": doc.get("status", "draft"),
        "created_at": doc.get("created_at"),
        "updated_at": doc.get("updated_at"),
    }


@api_view(["POST"])
def generate(request):
    ser = GenerateRequestSerializer(data=request.data)
    ser.is_valid(raise_exception=True)
    data = ser.validated_data

    uid = request.headers.get("X-User-Id", "demo")
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

    now = datetime.utcnow()
    trip_doc = {
        "user_id": uid,
        "destination": data["destination"],
        "days": plan,
        "preferences": data,
        "status": "draft",
        "created_at": now,
        "updated_at": now,
    }

    result = trips_collection.insert_one(trip_doc)

    return Response({
        "id": str(result.inserted_id),
        "itinerary": plan
    }, status=status.HTTP_201_CREATED)


@api_view(["GET"])
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
def list_trips(request):
    uid = request.headers.get("X-User-Id", "demo")
    trips = trips_collection.find({"user_id": uid}).sort("created_at", -1)

    return Response([
        {
            "id": str(t["_id"]),
            "destination": t.get("destination", ""),
            "title": t.get("days", {}).get("title", "Untitled"),
            "day_count": len(t.get("days", {}).get("days", [])),
            "status": t.get("status", "draft"),
            "updated_at": t.get("updated_at"),
        }
        for t in trips
    ])


@api_view(["GET", "PATCH", "DELETE"])
def trip_detail(request, trip_id):
    try:
        obj_id = ObjectId(trip_id)
    except (InvalidId, ValueError, TypeError):
        return Response({"detail": "Invalid Trip ID format."}, status=status.HTTP_400_BAD_REQUEST)

    trip = trips_collection.find_one({"_id": obj_id})
    if not trip:
        return Response({"detail": "Trip not found."}, status=status.HTTP_404_NOT_FOUND)

    if request.method == "GET":
        return Response(_format_trip_document(trip))

    elif request.method == "PATCH":
        ser = TripPatchSerializer(data=request.data)
        ser.is_valid(raise_exception=True)

        update_fields = {"updated_at": datetime.utcnow()}
        if "days" in ser.validated_data:
            update_fields["days"] = _compute_estimates(ser.validated_data["days"])
        if "status" in ser.validated_data:
            update_fields["status"] = ser.validated_data["status"]

        trips_collection.update_one({"_id": obj_id}, {"$set": update_fields})
        updated_trip = trips_collection.find_one({"_id": obj_id})
        return Response(_format_trip_document(updated_trip))

    elif request.method == "DELETE":
        trips_collection.delete_one({"_id": obj_id})
        return Response(status=status.HTTP_204_NO_CONTENT)


# Aliases for compatibility
generate_itinerary = generate
search_destinations = search