import 'package:flutter/material.dart';
import '../models/activity.dart';

class ActivityTile extends StatelessWidget {
  const ActivityTile({super.key, required this.activity, this.onEdit});
  final Activity activity;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8E8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(activity.time,
                style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(activity.description,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('${activity.durationMins} min',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(width: 12),
                  Icon(Icons.currency_rupee, size: 14, color: Colors.grey.shade600),
                  Text(activity.cost.toStringAsFixed(0),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ]),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: onEdit),
        ],
      ),
    );
  }
}