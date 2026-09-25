import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/trip.dart';
import 'itinerary.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});
  static const route = '/trips';
  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  late Future<List<Trip>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiClient.instance.listTrips();
  }

  void _reload() => setState(() => _future = ApiClient.instance.listTrips());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Trips'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _reload),
      ]),
      body: FutureBuilder<List<Trip>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final trips = snap.data ?? [];
          if (trips.isEmpty) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.luggage_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text('No saved trips yet'),
                const SizedBox(height: 4),
                Text('Generate one from the Plan tab', style: TextStyle(color: Colors.grey.shade600)),
              ]),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trips.length,
            itemBuilder: (context, i) {
              final t = trips[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(t.destination.isNotEmpty ? t.destination[0] : '?')),
                  title: Text(t.destination, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${t.dayCount} days • from ${t.origin}\n${t.startDate}'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await ApiClient.instance.deleteTrip(t.id);
                      _reload();
                    },
                  ),
                  onTap: () async {
                    final trip = await ApiClient.instance.getTrip(t.id);
                    if (!mounted) return;
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ItineraryScreen(trip: trip)));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}