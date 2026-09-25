# api/db.py
import os
from pymongo import MongoClient
from django.conf import settings

# Initialize PyMongo Client
client = MongoClient(getattr(settings, "MONGO_URI", "mongodb://localhost:27017/"))
db = client[getattr(settings, "MONGO_DB_NAME", "travel_planner_db")]

# Collections
trips_collection = db["trips"]

# Create indexes for fast querying
trips_collection.create_index("user_id")
trips_collection.create_index("created_at")