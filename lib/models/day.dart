export 'activity.dart';        // makes Activity available to anyone importing day.dart

import 'activity.dart';

class DayPlan {
  DayPlan({required this.dayNumber, required this.title, required this.activities});

  final int dayNumber;
  final String title;
  final List<Activity> activities;

  factory DayPlan.fromJson(Map<String, dynamic> j) => DayPlan(
        dayNumber: j['day_number'] ?? 1,
        title: j['title'] ?? 'Day',
        activities: ((j['activities'] ?? []) as List)
            .map((e) => Activity.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'day_number': dayNumber,
        'title': title,
        'activities': activities.map((a) => a.toJson()).toList(),
      };
}

