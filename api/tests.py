# api/tests.py
from unittest.mock import patch
from django.urls import reverse
from rest_framework.test import APITestCase


class TripFlowTest(APITestCase):
    @patch("services.gemini")
    def test_generate_and_list(self, mock_gemini):
        mock_gemini.return_value = {
            "title": "Test Trip",
            "days": [
                {
                    "day": 1,
                    "summary": "Arrival",
                    "activities": [
                        {"time": "10:00", "title": "Beach", "location": "Baga",
                         "lat": 15.55, "lng": 73.75, "cost": 1000, "type": "sight"}
                    ],
                }
            ],
        }

        resp = self.client.post(
            reverse("generate"),
            {"destination": "Goa", "days": 1, "interests": ["beach"], "budget": "mid"},
            format="json",
        )
        self.assertEqual(resp.status_code, 201)
        trip_id = resp.data["id"]

        list_resp = self.client.get(reverse("list_trips"), HTTP_X_USER_ID="demo")
        self.assertEqual(list_resp.status_code, 200)
        self.assertEqual(len(list_resp.data), 1)

        detail = self.client.get(f"/api/trips/{trip_id}/")
        self.assertEqual(detail.status_code, 200)

        patch = self.client.patch(
            f"/api/trips/{trip_id}/", {"status": "saved"}, format="json"
        )
        self.assertEqual(patch.status_code, 200)
        self.assertEqual(patch.data["status"], "saved")