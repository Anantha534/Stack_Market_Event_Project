# api/tests.py
from django.contrib.auth.models import User
from django.urls import reverse
from rest_framework.test import APITestCase, APIClient
from rest_framework import status
from .models import Trip

class TripAPITests(APITestCase):

    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(username="testuser", password="securepassword123")
        self.other_user = User.objects.create_user(username="otheruser", password="securepassword123")
        
        # Build standard authentication token for tests
        from rest_framework.authtoken.models import Token
        self.token = Token.objects.create(user=self.user)
        self.client.credentials(HTTP_AUTHORIZATION='Token ' + self.token.key)

        # Mock Trip instance owned by main tester
        self.trip = Trip.objects.create(
            user=self.user,
            destination="Goa",
            days={"title": "Goa Trip", "days": []},
            preferences={"destination": "Goa", "days": 3, "interests": ["beach"], "budget": "medium"},
            status="draft"
        )

    def test_unauthenticated_request_blocked(self):
        """Verify that requests without headers are rejected."""
        self.client.credentials()  # Clear auth token credentials
        response = self.client.get(reverse('list_trips'))
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_authenticated_user_can_list_trips(self):
        """Verify logged in users can read their owned items."""
        response = self.client.get(reverse('list_trips'))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

    def test_cannot_read_other_users_trips(self):
        """Ensure strict isolation prevents cross-profile reads."""
        # Create trip owned by secondary user
        other_trip = Trip.objects.create(
            user=self.other_user,
            destination="Paris",
            days={"title": "Paris Trip", "days": []},
            status="draft"
        )
        url = reverse('trip_detail', kwargs={'trip_id': other_trip.id})
        response = self.client.get(url)
        # Expected to fail as 404 since it shouldn't exist in user context query scope
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)