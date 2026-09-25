# travel_planner/urls.py
from django.contrib import admin
from django.urls import path
from rest_framework.authtoken.views import obtain_auth_token
from api.views import (
    generate,
    search,
    list_trips,
    trip_detail,
)

urlpatterns = [
    path('admin/', admin.site.urls),
    
    # Token Authentication Endpoint
    path('api/auth-token/', obtain_auth_token, name='api_token_auth'),
    
    # API endpoints
    path('api/generate/', generate, name='generate'),
    path('api/search/', search, name='search'),
    path('api/trips/', list_trips, name='list_trips'),
    path('api/trips/<str:trip_id>/', trip_detail, name='trip_detail'),
]