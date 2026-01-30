import 'package:flutter/material.dart';
import '../api/balanceup_api.dart';

class HabitDetailsScreen extends StatefulWidget {
  final BalanceUpApi api;
  final Habit habit;

  const HabitDetailsScreen({
    super.key,
    required this.api,
    required this.habit,
  });

  @override
  State<HabitDetailsScreen> createState() => _HabitDetailsScreenState();
}

class _HabitDetailsScreenState extends State<HabitDetailsScreen> {
  late Future<List<HabitEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadWeek();
  }

  Future<List<HabitEntry>> _loadWeek() async {
    final now = DateTime.now();
    final to = _fmtDate(now);
    final from = _fmtDate(now.subtract(const Duration(days: 6)));
    return widget.api.getEntries(habitId: widget.habit.id, from: from, to: to);
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _refresh() async {
    setState(() {
      _future = _loadWeek();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.habit;
    final goal = h.dailyTarget ?? 0;
    final unit = h.unit ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(h.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<HabitEntry>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorView(
                error: snapshot.error.toString(),
                onRetry: _refresh,
              );
            }

            final entries = snapshot.data ?? [];
            final todayStr = _fmtDate(DateTime.now());
            final today = entries.where((e) => e.entryDate == todayStr).toList();

            num current = 0;
            if (today.isNotEmpty) {
              // se existir mais de uma entry (não devia), soma
              current = today.fold<num>(0, (sum, e) => sum + (e.valueNumeric ?? 0));
            }

            final progress = (goal > 0) ? (current / goal).clamp(0, 1) : 0.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 16,
                        offset: Offset(0, 6),
                        color: Color(0x11000000),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        goal > 0
                            ? 'Current: $current$unit  •  Goal: $goal$unit'
                            : 'Current: $current$unit',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress.toDouble(),
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              await _addEntryDialog(unit: unit);
                              await _refresh();
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add entry'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: _refresh,
                            child: const Text('Refresh'),
                          )
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const Text(
                  'Last 7 days',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: _WeekList(entries: entries, unit: unit),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _addEntryDialog({required String unit}) async {
    final h = widget.habit;
    final isBoolean = h.type.toLowerCase() == 'boolean';

    if (isBoolean) {
      // boolean habit: simple toggle dialog
      bool value = true;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Add entry'),
          content: StatefulBuilder(
            builder: (ctx, setState) => Row(
              children: [
                const Text('Done today?'),
                const SizedBox(width: 12),
                Switch(
                  value: value,
                  onChanged: (v) => setState(() => value = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      );

      if (ok == true) {
        await widget.api.createEntry(
          habitId: h.id,
          req: CreateEntryRequest(
            entryDate: _fmtDate(DateTime.now()),
            valueBool: value,
          ),
        );
      }
      return;
    }

    // numeric habit dialog
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add entry'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Value ($unit)',
            hintText: 'e.g. 250',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );

    if (ok == true) {
      final raw = controller.text.trim();
      final value = num.tryParse(raw);
      if (value == null) return;

      await widget.api.createEntry(
        habitId: h.id,
        req: CreateEntryRequest(
          entryDate: _fmtDate(DateTime.now()),
          valueNumeric: value,
        ),
      );
    }
  }
}

class _WeekList extends StatelessWidget {
  final List<HabitEntry> entries;
  final String unit;

  const _WeekList({required this.entries, required this.unit});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(child: Text('No entries yet'));
    }

    // group by day (simple)
    final byDate = <String, num>{};
    for (final e in entries) {
      final v = e.valueNumeric ?? 0;
      byDate[e.entryDate] = (byDate[e.entryDate] ?? 0) + v;
    }

    final dates = byDate.keys.toList()..sort();

    return ListView.separated(
      itemCount: dates.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final d = dates[i];
        final v = byDate[d] ?? 0;
        return ListTile(
          title: Text(d),
          trailing: Text('$v$unit'),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Failed to load entries', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async => onRetry(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
