import 'package:flutter/material.dart';
import '../api/balanceup_api.dart';

class HistoryScreen extends StatefulWidget {
  final BalanceUpApi api;
  const HistoryScreen({super.key, required this.api});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<_HistoryData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_HistoryData> _load() async {
    final habits = await widget.api.getHabits();

    final now = DateTime.now();
    final to = _fmt(now);
    final from = _fmt(now.subtract(const Duration(days: 6)));

    final Map<String, List<_DayEntry>> byDay = {};

    for (final h in habits) {
      final entries = await widget.api.getEntries(
        habitId: h.id,
        from: from,
        to: to,
      );

      for (final e in entries) {
        byDay.putIfAbsent(e.entryDate, () => []);
        byDay[e.entryDate]!.add(
          _DayEntry(
            habitName: h.name,
            value: e.valueNumeric ?? (e.valueBool == true ? 1 : 0),
            unit: h.unit ?? '',
          ),
        );
      }
    }

    return _HistoryData(byDay);
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<_HistoryData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final data = snapshot.data!;
          final days = data.daysSortedDesc;

          if (days.isEmpty) {
            return const Center(child: Text('No history yet'));
          }

          return ListView.builder(
            itemCount: days.length,
            itemBuilder: (context, i) {
              final day = days[i];
              final entries = data.byDay[day]!;

              return _DayCard(date: day, entries: entries);
            },
          );
        },
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final String date;
  final List<_DayEntry> entries;

  const _DayCard({required this.date, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...entries.map((e) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.habitName),
                    Text('${e.value}${e.unit}'),
                  ],
                )),
          ],
        ),
      ),
    );
  }
}

class _HistoryData {
  final Map<String, List<_DayEntry>> byDay;
  _HistoryData(this.byDay);

  List<String> get daysSortedDesc {
    final l = byDay.keys.toList();
    l.sort((a, b) => b.compareTo(a));
    return l;
  }
}

class _DayEntry {
  final String habitName;
  final num value;
  final String unit;

  _DayEntry({required this.habitName, required this.value, required this.unit});
}
