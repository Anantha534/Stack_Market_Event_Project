// lib/api/mock_backend.dart
//
// Offline stand-in for the Django service layer (planner.py + search.py +
// MongoDB Atlas). Flip kUseMockBackend = false in api_client.dart to go live.
//
// NOTE: this file must NEVER import api_client.dart — that would create a
// circular dependency (dart analyzer flags the whole file with cascading
// "undefined class" errors). It only depends on the models.

import '../models/trip.dart';

class MockBackend {
  final List<Trip> _trips = [];

  static const List<Destination> _catalog = [
    Destination(name: 'Goa', lat: 15.2993, lng: 74.1240, description: 'Beaches & nightlife'),
    Destination(name: 'Jaipur', lat: 26.9124, lng: 75.7873, description: 'Pink City heritage'),
    Destination(name: 'Manali', lat: 32.2432, lng: 77.1892, description: 'Himalayan hills'),
    Destination(name: 'Munnar', lat: 10.0889, lng: 77.0595, description: 'Tea plantations'),
    Destination(name: 'Udaipur', lat: 24.5854, lng: 73.7125, description: 'Lakes & palaces'),
    Destination(name: 'Pondicherry', lat: 11.9416, lng: 79.8083, description: 'French quarter'),
    Destination(name: 'Rishikesh', lat: 30.0869, lng: 78.2676, description: 'Rafting & yoga'),
    Destination(name: 'Hampi', lat: 15.3350, lng: 76.4600, description: 'Ancient ruins'),
    Destination(name: 'Kochi', lat: 9.9312, lng: 76.2673, description: 'Backwaters & art'),
    Destination(name: 'Darjeeling', lat: 27.0360, lng: 88.2627, description: 'Tea & toy train'),
  ];

  // ── search.py stand-in (Brave Search lives behind Django) ─────────
  Future<List<Destination>> searchDestinations(String query) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List<Destination>.of(_catalog);
    return _catalog
        .where((d) =>
            d.name.toLowerCase().contains(q) ||
            d.description.toLowerCase().contains(q))
        .toList();
  }

  // ── planner.py stand-in (Gemini API + HF fallback live behind Django)
  Future<Trip> generateTrip(PlanRequest req) async {
    await Future.delayed(const Duration(seconds: 2)); // fake "AI thinking"

    final match = await searchDestinations(req.destination);
    final lat = match.isNotEmpty ? match.first.lat : 15.0;
    final lng = match.isNotEmpty ? match.first.lng : 75.0;

    const templates = <List<String>>[
      ['Arrival & local walk', 'Hotel check-in', 'Sunset viewpoint', 'Dinner at local restaurant'],
      ['Old town heritage tour', 'Museum visit', 'Street food crawl', 'Evening market'],
      ['Nature / adventure day', 'Scenic spot', 'Local crafts shopping', 'Cultural show'],
      ['Temple & architecture', 'Lakeside lunch', 'Boat ride', 'Rooftop dinner'],
      ['Beach / relaxation', 'Water sports', 'Spa break', 'Night beach walk'],
    ];
    const times = <String>['09:00', '12:30', '15:30', '19:00'];
    const costs = <double>[500, 800, 400, 1200];

    final days = <DayPlan>[];
    for (var i = 1; i <= req.days; i++) {
      final t = templates[(i - 1) % templates.length];
      days.add(
        DayPlan(
          dayNumber: i,
          title: 'Day $i • ${req.destination}',
          activities: [
            for (var k = 0; k < t.length; k++)
              Activity(
                title: t[k],
                description:
                    '${t[k]} — planned for day $i of your ${req.destination} trip.',
                time: times[k],
                durationMins: k == 0 ? 120 : 90,
                lat: lat + 0.008 * k,
                lng: lng + 0.008 * k,
                cost: costs[k],
              ),
          ],
        ),
      );
    }

    final perDay = req.budget == 'Luxury'
        ? 25000.0
        : req.budget == 'Budget'
            ? 7000.0
            : 15000.0;

    final trip = Trip(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      origin: req.origin,
      destination: req.destination,
      startDate: DateTime.now().toIso8601String().substring(0, 10),
      days: days,
      summary:
          'A ${req.days}-day ${req.budget.toLowerCase()} trip to ${req.destination} '
          'focused on ${req.interests.join(", ")}.',
      lat: lat,
      lng: lng,
      estimatedCost: perDay * req.days,
      travelNote:
          'Map centre: ${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)}',
    );

    _trips.insert(0, trip);
    return trip;
  }

  // ── MongoDB Atlas stand-in ────────────────────────────────────────
  Future<List<Trip>> listTrips() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List<Trip>.of(_trips);
  }

  Future<Trip> getTrip(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (_trips.isEmpty) throw Exception('Trip not found');
    return _trips.firstWhere((t) => t.id == id, orElse: () => _trips.first);
  }

  Future<Trip> updateTrip(Trip trip) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final i = _trips.indexWhere((t) => t.id == trip.id);
    if (i >= 0) {
      _trips[i] = trip;
    } else {
      _trips.insert(0, trip);
    }
    return trip;
  }

  Future<void> deleteTrip(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _trips.removeWhere((t) => t.id == id);
  }
}