import os
import re
import json
import requests
from django.conf import settings

# Gemini AI Service
def generate_itinerary_plan(destination, days, budget, interests, travel_style="balanced", pace="moderate"):
    """Generate travel itinerary using Gemini AI"""
    import google.generativeai as genai
    genai.configure(api_key=settings.GEMINI_API_KEY)

    prompt = f"""
    Create a {days}-day travel itinerary for {destination}.
    Budget: {budget}
    Interests: {', '.join(interests) if interests else 'general sightseeing'}
    Travel style: {travel_style}
    Pace: {pace}

    Return STRICT JSON format only, no explanations:
    {{
        "destination": "{destination}",
        "summary": "Brief overview of the trip",
        "total_estimated_cost": "Estimated total cost range",
        "days": [
            {{
                "day": 1,
                "title": "Day title",
                "activities": [
                    {{
                        "time": "HH:MM",
                        "place": "Place name",
                        "description": "Activity description",
                        "duration_hours": 2,
                        "cost_estimate": "$XX"
                    }}
                ]
            }}
        ],
        "travel_tips": ["Tip 1", "Tip 2"],
        "best_transport": "Recommended transport mode"
    }}
    Include 3-5 activities per day with real place names.
    """

    model = genai.GenerativeModel('gemini-1.5-flash')
    response = model.generate_content(prompt)

    # Extract JSON from response
    text = response.text
    json_match = re.search(r'```json\s*([\s\S]*?)\s*```', text)
    if json_match:
        text = json_match.group(1)

    try:
        return json.loads(text)
    except json.JSONDecodeError:
        # Fallback if JSON parsing fails
        return {
            "destination": destination,
            "summary": f"Trip to {destination}",
            "days": [],
            "error": "Failed to parse AI response"
        }

# Location Services
def geocode_location(location):
    """Get coordinates for a location using Nominatim"""
    url = "https://nominatim.openstreetmap.org/search"
    params = {
        "q": location,
        "format": "json",
        "limit": 1
    }
    headers = {"User-Agent": "TravelPlannerHackathon/1.0"}

    try:
        response = requests.get(url, params=params, headers=headers, timeout=10)
        response.raise_for_status()
        data = response.json()
        if data:
            return {
                "lat": float(data[0]["lat"]),
                "lon": float(data[0]["lon"]),
                "display_name": data[0]["display_name"]
            }
    except Exception as e:
        print(f"Geocoding error: {e}")
    return None

def estimate_route(start, end):
    """Estimate travel route between two points using OSRM"""
    if not start or not end:
        return None

    url = f"https://router.project-osrm.org/route/v1/driving/{start['lon']},{start['lat']};{end['lon']},{end['lat']}"
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        data = response.json()
        route = data["routes"][0]
        return {
            "distance_km": round(route["distance"] / 1000, 1),
            "duration_min": round(route["duration"] / 60),
            "cost_estimate_usd": round((route["distance"] / 1000) * 0.5, 2)  # Simple cost estimate
        }
    except Exception as e:
        print(f"Route estimation error: {e}")
        return None

def get_map_url(lat, lon):
    """Generate Google Maps URL for a location"""
    return f"https://www.google.com/maps/search/?api=1&query={lat},{lon}"

# Search Service
def search_destinations(query):
    """Search for destinations using Brave Search"""
    if not settings.BRAVE_API_KEY:
        return []

    url = "https://api.search.brave.com/res/v1/web/search"
    headers = {"X-Subscription-Token": settings.BRAVE_API_KEY}
    params = {
        "q": f"{query} travel destination guide",
        "count": 5
    }

    try:
        response = requests.get(url, headers=headers, params=params, timeout=10)
        response.raise_for_status()
        data = response.json()
        return [
            {
                "title": result.get("title", ""),
                "url": result.get("url", ""),
                "description": result.get("description", "")
            }
            for result in data.get("web", {}).get("results", [])
        ]
    except Exception as e:
        print(f"Search error: {e}")
        return []