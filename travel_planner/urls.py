from django.contrib import admin
from django.urls import path
from api.views import (
    generate,
    search,
    list_trips,
    trip_detail,
)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/generate/', generate, name='generate'),
    path('api/search/', search, name='search'),
    path('api/trips/', list_trips, name='list_trips'),
    path('api/trips/<str:trip_id>/', trip_detail, name='trip_detail'),
]