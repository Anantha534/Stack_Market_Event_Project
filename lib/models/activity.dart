class Activity {
  Activity({
    required this.title,
    required this.description,
    required this.time,
    this.durationMins = 60,
    this.lat = 0,
    this.lng = 0,
    this.cost = 0,
  });

  final String title;
  final String description;
  final String time; // "09:00"
  final int durationMins;
  final double lat;
  final double lng;
  final double cost;

  factory Activity.fromJson(Map<String, dynamic> j) => Activity(
        title: j['title'] ?? '',
        description: j['description'] ?? '',
        time: j['time'] ?? '09:00',
        durationMins: j['duration_mins'] ?? 60,
        lat: (j['lat'] ?? 0).toDouble(),
        lng: (j['lng'] ?? 0).toDouble(),
        cost: (j['cost'] ?? 0).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'time': time,
        'duration_mins': durationMins,
        'lat': lat,
        'lng': lng,
        'cost': cost,
      };

  Activity copyWith({String? title, String? description, String? time}) =>
      Activity(
        title: title ?? this.title,
        description: description ?? this.description,
        time: time ?? this.time,
        durationMins: durationMins,
        lat: lat,
        lng: lng,
        cost: cost,
      );
}
