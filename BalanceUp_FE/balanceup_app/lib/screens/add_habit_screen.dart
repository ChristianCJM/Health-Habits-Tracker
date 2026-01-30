import 'package:flutter/material.dart';
import '../api/balanceup_api.dart';

class AddHabitScreen extends StatefulWidget {
  final BalanceUpApi api;
  const AddHabitScreen({super.key, required this.api});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _name = TextEditingController();
  final _unit = TextEditingController();
  final _target = TextEditingController();
  String _type = 'numeric';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Habit')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Habit name'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _type,
              items: const [
                DropdownMenuItem(value: 'numeric', child: Text('Numeric')),
                DropdownMenuItem(value: 'boolean', child: Text('Yes / No')),
              ],
              onChanged: (v) => setState(() => _type = v!),
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _unit,
              decoration: const InputDecoration(labelText: 'Unit (optional)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _target,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Daily target (optional)'),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Create habit'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;

    await widget.api.createHabit(
      CreateHabitRequest(
        name: _name.text.trim(),
        type: _type,
        unit: _unit.text.trim().isEmpty ? null : _unit.text.trim(),
        dailyTarget: num.tryParse(_target.text),
      ),
    );

    if (!mounted) return;
    Navigator.pop(context, true);
  }
}
