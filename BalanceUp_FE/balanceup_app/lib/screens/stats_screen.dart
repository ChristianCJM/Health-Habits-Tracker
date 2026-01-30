import 'package:flutter/material.dart';
import '../api/balanceup_api.dart';

class StatsScreen extends StatefulWidget {
  final BalanceUpApi api;
  const StatsScreen({super.key, required this.api});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Future<List<DashboardHabit>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.getDashboard();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.api.getDashboard();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Stats', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<DashboardHabit>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text(snapshot.error.toString()));
                }

                final habits = snapshot.data ?? [];
                if (habits.isEmpty) {
                  return const Center(child: Text('No stats yet.'));
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: habits.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final h = habits[i];
                      final p = (h.todayProgress * 100).round();

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(h.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Text('Today: $p%'),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(value: h.todayProgress.ceilToDouble().clamp(0, 1)),
                              const SizedBox(height: 8),
                              Text('Current: ${h.todayCurrent}${h.unit ?? ''}'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
