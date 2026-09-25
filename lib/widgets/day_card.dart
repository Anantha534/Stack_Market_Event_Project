// lib/widgets/day_card.dart
import 'package:flutter/material.dart';

import '../models/activity.dart'; // explicit: Dart imports are NOT transitive
import '../models/day.dart';
import 'activity_tile.dart';

class DayCard extends StatelessWidget {
  const DayCard({super.key, required this.day, this.onEditActivity});

  final DayPlan day;
  final void Function(Activity activity)? onEditActivity;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double totalCost =
        day.activities.fold<double>(0, (sum, a) => sum + a.cost);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'DAY ${day.dayNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    day.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${day.activities.length} activities • est. ₹${totalCost.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            ...day.activities.map(
              (a) => ActivityTile(
                activity: a,
                onEdit:
                    onEditActivity == null ? null : () => onEditActivity!(a),
              ),
            ),
          ],
        ),
      ),
    );
  }
}