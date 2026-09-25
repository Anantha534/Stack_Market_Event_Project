import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/trip.dart';
import 'my_trips.dart';
import 'itinerary.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  static const route = '/search';
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _q = TextEditingController();
  final _origin = TextEditingController(text: 'Chennai');
  int _days = 3;
  String _budget = 'Moderate';
  final Set<String> _interests = {'Culture'};
  List<Destination> _results = [];
  bool _searching = false, _generating = false;
  String? _error;

  static const _interestOptions = ['Culture', 'Food', 'Nature', 'Adventure', 'Shopping', 'Nightlife', 'History', 'Relaxation'];
  static const _budgets = ['Budget', 'Moderate', 'Luxury'];

  Future<void> _search() async {
    setState(() { _searching = true; _error = null; });
    try {
      final r = await ApiClient.instance.searchDestinations(_q.text);
      setState(() => _results = r);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _searching = false);
    }
  }

  Future<void> _generate(String dest) async {
    setState(() { _generating = true; _error = null; });
    try {
      final trip = await ApiClient.instance.generateTrip(PlanRequest(
        destination: dest, days: _days, interests: _interests.toList(), budget: _budget, origin: _origin.text,
      ));
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ItineraryScreen(trip: trip)));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Generation failed.');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan a Trip'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmarks_outlined),
            tooltip: 'My Trips',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyTripsScreen())),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _q,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  hintText: 'Search a destination (e.g. Goa)',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _search),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Trip preferences', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      TextField(controller: _origin, decoration: const InputDecoration(labelText: 'Starting from', border: OutlineInputBorder(), isDense: true)),
                      const SizedBox(height: 14),
                      Row(children: [
                        const Text('Days: '),
                        Expanded(
                          child: Slider(
                            value: _days.toDouble(), min: 1, max: 10, divisions: 9,
                            label: '$_days',
                            onChanged: (v) => setState(() => _days = v.round()),
                          ),
                        ),
                        Text('$_days', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 6),
                      const Text('Budget', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, children: _budgets.map((b) =>
                        ChoiceChip(label: Text(b), selected: _budget == b, onSelected: (_) => setState(() => _budget = b))).toList()),
                      const SizedBox(height: 14),
                      const Text('Interests', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: _interestOptions.map((i) =>
                        FilterChip(label: Text(i), selected: _interests.contains(i),
                          onSelected: (s) => setState(() => s ? _interests.add(i) : _interests.remove(i)))).toList()),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 16),
              const Text('Destinations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              if (_searching) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
              ..._results.map((d) => Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(d.name.isNotEmpty ? d.name[0] : '?')),
                  title: Text(d.name),
                  subtitle: Text(d.description),
                  trailing: const Icon(Icons.auto_awesome),
                  onTap: _generating ? null : () => _generate(d.name),
                ),
              )),
            ],
          ),
          if (_generating)
            Container(
              color: Colors.black.withValues(alpha: 0.45),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('AI is building your itinerary…'),
                    ]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

