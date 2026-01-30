import 'package:balanceup_app/screens/add_habit_screen.dart';
import 'package:flutter/material.dart';
import '../api/balanceup_api.dart';
import '../widgets/habit_card.dart';
import 'habit_details_screen.dart';


class HomeScreen extends StatefulWidget {
  final BalanceUpApi api;
  const HomeScreen({super.key, required this.api});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  Future<void> _openQuickAdd(DashboardHabit h) async {
  final isBoolean = h.type.toLowerCase() == 'boolean';
  final unit = h.unit ?? '';

  if (isBoolean) {
    bool value = true;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: StatefulBuilder(
            builder: (ctx, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Done today?'),
                    const SizedBox(width: 12),
                    Switch(value: value, onChanged: (v) => setState(() => value = v)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (ok == true) {
      await widget.api.createEntry(
        habitId: h.id,
        req: CreateEntryRequest(
          entryDate: _today(),
          valueBool: value,
        ),
      );
    }
    return;
  }

  final controller = TextEditingController(text: '');
  final ok = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(h.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Add value ($unit)',
                hintText: 'e.g. 250',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      );
    },
  );

  if (ok == true) {
    final raw = controller.text.trim();
    final value = num.tryParse(raw);
    if (value == null) return;

    await widget.api.createEntry(
      habitId: h.id,
      req: CreateEntryRequest(
        entryDate: _today(),
        valueNumeric: value,
      ),
    );
  }
}

String _today() {
  final d = DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                const Text(
                  'BalanceUp',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    final created = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => AddHabitScreen(api: widget.api),
                      ),
                    );
                    if (created == true) {
                      await _refresh();
                    }
                  },
                ),
              ],
            ),

          const SizedBox(height: 16),

          Expanded(
            child: FutureBuilder<List<DashboardHabit>>(
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

                final habits = snapshot.data ?? [];
                if (habits.isEmpty) {
                  return _EmptyView(onCreateDefaults: _createDefaultHabits);
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: habits.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) {
                      final h = habits[i]; // agora é DashboardHabit
                      final unit = h.unit ?? '';

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => HabitDetailsScreen(api: widget.api, habit: h),
                              ),
                            );
                          },
                          child: HabitCard(
                            habit: h,
                            currentText: 'Current: ${h.todayCurrent}${h.unit ?? ''}',
                            progress01: h.todayProgress.toDouble(),
                            progressColor: Colors.blue,
                            onQuickAdd: () async {
                              await _openQuickAdd(h);
                              await _refresh();
                            },
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

  _MockData _mockProgress(Habit h) {
    final cat = (h.category ?? '').toLowerCase();
    if (cat == 'water') return _MockData('Current: 400ml', 0.2, Colors.blue);
    if (cat == 'movement') return _MockData('Current: 15min', 0.5, Colors.green);
    if (cat == 'sleep') return _MockData('Hours slept last night', 0.0, Colors.purple);
    if (cat == 'food') return _MockData('Current: 2 meals', 1.0, Colors.orange);
    return _MockData('Current: —', 0.0, Colors.grey);
  }

  Future<void> _createDefaultHabits() async {
    // Opcional: cria 4 hábitos default se DB estiver vazio.
    // Isto facilita demo.
    final defaults = [
      CreateHabitRequest(name: 'Drink Water', type: 'numeric', unit: 'ml', dailyTarget: 2000, category: 'water'),
      CreateHabitRequest(name: 'Move your body', type: 'numeric', unit: 'min', dailyTarget: 30, category: 'movement'),
      CreateHabitRequest(name: 'Sleep', type: 'numeric', unit: 'h', dailyTarget: 7, category: 'sleep'),
      CreateHabitRequest(name: 'Healthy meals', type: 'numeric', unit: 'meals', dailyTarget: 2, category: 'food'),
    ];

    for (final d in defaults) {
      await widget.api.createHabit(d);
    }

    if (!mounted) return;
    await _refresh();
  }
}

class _MockData {
  final String currentText;
  final double progress;
  final Color color;
  _MockData(this.currentText, this.progress, this.color);
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Failed to load habits', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final Future<void> Function() onCreateDefaults;
  const _EmptyView({required this.onCreateDefaults});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No habits yet', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Create default habits to start quickly.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async => onCreateDefaults(),
              child: const Text('Create defaults'),
            )
          ],
        ),
      ),
    );
  }
}
