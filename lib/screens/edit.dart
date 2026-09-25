import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/day.dart';        // <-- DayPlan lives here
import '../models/trip.dart';

class EditScreen extends StatefulWidget {
  const EditScreen({super.key, required this.trip});
  final Trip trip;
  static const route = '/edit';
  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  late List<DayPlan> _days;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _days = List.of(widget.trip.days);
  }

  Future<void> _editActivity(int di, int ai) async {
    final act = _days[di].activities[ai];
    final titleC = TextEditingController(text: act.title);
    final descC = TextEditingController(text: act.description);
    final timeC = TextEditingController(text: act.time);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit activity'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: titleC, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 8),
            TextField(controller: descC, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 8),
            TextField(controller: timeC, decoration: const InputDecoration(labelText: 'Time (HH:MM)')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );

    if (ok == true && mounted) {
      setState(() {
        final list = List.of(_days[di].activities);
        list[ai] = act.copyWith(title: titleC.text, description: descC.text, time: timeC.text);
        _days[di] = DayPlan(
          dayNumber: _days[di].dayNumber,
          title: _days[di].title,
          activities: list,
        );
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updated = widget.trip.copyWith(days: _days);
    try {
      final saved = await ApiClient.instance.updateTrip(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Itinerary saved')));
      Navigator.of(context).pop(saved);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Itinerary'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('SAVE'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.trip.destination,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text('${widget.trip.dayCount} days • from ${widget.trip.origin}',
              style: TextStyle(color: Colors.grey.shade600)),
          const Divider(height: 28),
          for (var di = 0; di < _days.length; di++) ...[
            Text('Day ${_days[di].dayNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            for (var ai = 0; ai < _days[di].activities.length; ai++)
              Card(
                child: ListTile(
                  leading: Text(_days[di].activities[ai].time),
                  title: Text(_days[di].activities[ai].title),
                  subtitle: Text(_days[di].activities[ai].description),
                  trailing: const Icon(Icons.edit_outlined, size: 18),
                  onTap: () => _editActivity(di, ai),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
