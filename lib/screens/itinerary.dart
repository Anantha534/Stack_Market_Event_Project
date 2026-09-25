import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../widgets/day_card.dart';
import '../widgets/trip_map.dart';
import 'edit.dart';

class ItineraryScreen extends StatefulWidget {
  const ItineraryScreen({super.key, required this.trip});
  final Trip trip;
  static const route = '/itinerary';
  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  late Trip _trip = widget.trip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_trip.destination),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit itinerary',
            onPressed: () async {
              final updated = await Navigator.of(context).push<Trip>(
                MaterialPageRoute(builder: (_) => EditScreen(trip: _trip)),
              );
              if (updated != null) setState(() => _trip = updated);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.route, color: cs.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${_trip.origin} → ${_trip.destination}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                  ]),
                  const SizedBox(height: 8),
                  Text(_trip.summary, style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 12),
                  Wrap(spacing: 10, runSpacing: 6, children: [
                    _chip(Icons.calendar_today, '${_trip.dayCount} days'),
                    _chip(Icons.currency_rupee, '~${_trip.estimatedCost.toStringAsFixed(0)} est.'),
                    _chip(Icons.place, _trip.destination),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          TripMap(trip: _trip),
          const SizedBox(height: 6),
          Text(_trip.travelNote, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          ..._trip.days.map((d) => DayCard(day: d)),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) => Chip(
        avatar: Icon(icon, size: 16),
        label: Text(label),
        visualDensity: VisualDensity.compact,
      );
}

