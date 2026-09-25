# api/urls.py
from django.urls import path
from . import views

urlpatterns = [
    path("search/", views.search, name="search"),
    path("trips/", views.list_trips, name="list_trips"),
    path("trips/generate/", views.generate, name="generate"),
    path("trips/<uuid:trip_id>/", views.trip_detail, name="trip_detail"),
]