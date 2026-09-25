export 'day.dart';             // makes DayPlan (and Activity) available downstream

import 'day.dart';

class Trip {
  Trip({
    required this.id,
    required this.destination,
    required this.startDate,
    required this.days,
    this.origin = 'Chennai',
    this.summary = '',
    this.lat = 0,
    this.lng = 0,
    this.estimatedCost = 0,
    this.travelNote = '',
  });

  final String id;
  final String origin;
  final String destination;
  final String startDate;
  final List<DayPlan> days;
  final String summary;
  final double lat;
  final double lng;
  final double estimatedCost;
  final String travelNote;

  int get dayCount => days.length;

  factory Trip.fromJson(Map<String, dynamic> j) => Trip(
        id: (j['_id'] ?? j['id'] ?? '').toString(),
        origin: j['origin'] ?? 'Chennai',
        destination: j['destination'] ?? '',
        startDate: j['start_date'] ?? '',
        days: ((j['days'] ?? []) as List)
            .map((e) => DayPlan.fromJson(e as Map<String, dynamic>))
            .toList(),
        summary: j['summary'] ?? '',
        lat: (j['lat'] ?? 0).toDouble(),
        lng: (j['lng'] ?? 0).toDouble(),
        estimatedCost: (j['estimated_cost'] ?? 0).toDouble(),
        travelNote: j['travel_note'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'origin': origin,
        'destination': destination,
        'start_date': startDate,
        'days': days.map((d) => d.toJson()).toList(),
        'summary': summary,
        'lat': lat,
        'lng': lng,
        'estimated_cost': estimatedCost,
        'travel_note': travelNote,
      };

  Trip copyWith({String? destination, List<DayPlan>? days}) => Trip(
        id: id,
        origin: origin,
        destination: destination ?? this.destination,
        startDate: startDate,
        days: days ?? this.days,
        summary: summary,
        lat: lat,
        lng: lng,
        estimatedCost: estimatedCost,
        travelNote: travelNote,
      );
}

class Destination {
  const Destination({
    required this.name,
    required this.lat,
    required this.lng,
    this.description = '',
  });

  final String name;
  final double lat;
  final double lng;
  final String description;

  factory Destination.fromJson(Map<String, dynamic> json) => Destination(
        name: (json['name'] ?? '').toString(),
        lat: (json['lat'] as num? ?? 0).toDouble(),
        lng: (json['lng'] as num? ?? 0).toDouble(),
        description: (json['description'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'lat': lat,
        'lng': lng,
        'description': description,
      };
}

class PlanRequest {
  PlanRequest({
    required this.destination,
    required this.days,
    required this.interests,
    required this.budget,
    this.origin = 'Chennai',
  });

  final String destination;
  final int days;
  final List<String> interests;
  final String budget;
  final String origin;

  Map<String, dynamic> toJson() => {
        'destination': destination,
        'days': days,
        'interests': interests,
        'budget': budget,
        'origin': origin,
      };
}

