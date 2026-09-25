# api/services.py
import os
import json
import re
import requests
import google.generativeai as genai
from django.conf import settings

# Initialize Gemini API
genai.configure(api_key=os.environ.get("GEMINI_API_KEY", ""))

def geocode(query: str) -> dict:
    """Geocode a query to lat/lng with a safe request timeout."""
    try:
        # Replace this with your actual geocoding service URL if custom
        url = f"https://nominatim.openstreetmap.org/search?q={query}&format=json&limit=1"
        headers = {"User-Agent": "TravelPlannerApp/1.0"}
        response = requests.get(url, headers=headers, timeout=10)
        
        if response.status_code == 200 and response.json():
            data = response.json()[0]
            return {"lat": float(data["lat"]), "lng": float(data["lon"])}
    except Exception:
        pass
    return {"lat": 0.0, "lng": 0.0}

def brave_search(query: str) -> list:
    """Perform a web search using Brave Search API with request timeout."""
    api_key = os.environ.get("BRAVE_SEARCH_API_KEY", "")
    if not api_key:
        return []

    url = f"https://api.search.brave.com/res/v1/web/search?q={query}"
    headers = {"Accept": "application/json", "X-Subscription-Token": api_key}
    
    try:
        response = requests.get(url, headers=headers, timeout=10)
        if response.status_code == 200:
            return response.json().get("web", {}).get("results", [])
    except Exception:
        pass
    return []

def gemini(prompt: str) -> dict:
    """Generate itinerary JSON via Gemini and handle robust stripping of code markdown blocks."""
    model = genai.GenerativeModel("gemini-pro")
    
    # Enable explicit structured JSON mode if supported by the SDK version, or rely on generation
    response = model.generate_content(prompt)
    raw_text = response.text.strip()

    # Regex to clean out potential LLM markdown decorations (e.g. ```json ... ```)
    if raw_text.startswith("```"):
        raw_text = re.sub(r"^```(?:json)?\s*|```$", "", raw_text, flags=re.MULTILINE).strip()

    try:
        return json.loads(raw_text)
    except json.JSONDecodeError:
        # Clean fallback schema if JSON output parsing fails
        return {
            "title": "Failed to parse itinerary",
            "days": [
                {
                    "day": 1,
                    "summary": "Could not format response properly. Please try again.",
                    "activities": []
                }
            ]
        }