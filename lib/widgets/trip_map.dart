import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/trip.dart';

class TripMap extends StatelessWidget {
  const TripMap({super.key, required this.trip, this.height = 240});
  final Trip trip;
  final double height;

  @override
  Widget build(BuildContext context) {
    final points = <LatLng>[];
    for (final d in trip.days) {
      for (final a in d.activities) {
        if (a.lat != 0 && a.lng != 0) points.add(LatLng(a.lat, a.lng));
      }
    }
    if (points.isEmpty) points.add(LatLng(trip.lat, trip.lng));

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: points.first,
            initialZoom: 11,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.ps05.travelarchitect',
            ),
            if (points.length > 1)
              PolylineLayer(polylines: [
                Polyline(points: points, strokeWidth: 3, color: Theme.of(context).colorScheme.primary),
              ]),
            MarkerLayer(markers: [
              for (var i = 0; i < points.length; i++)
                Marker(
                  point: points[i],
                  width: 32,
                  height: 32,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text('${i + 1}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
            ]),
            const RichAttributionWidget(
              attributions: [TextSourceAttribution('OpenStreetMap contributors')],
            ),
          ],
        ),
      ),
    );
  }
}