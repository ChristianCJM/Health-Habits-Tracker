import 'package:flutter/material.dart';
import '../api/balanceup_api.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;

  // Por agora, valores "mock" para UI ficar igual ao Figma.
  // Depois vamos calcular isto via entries.
  final String currentText;
  final double progress01; // 0..1
  final Color progressColor;
  final VoidCallback? onQuickAdd;


  const HabitCard({
    super.key,
    required this.habit,
    required this.currentText,
    required this.progress01,
    required this.progressColor,
    this.onQuickAdd,
  });

  @override
Widget build(BuildContext context) {
  final target = habit.dailyTarget?.toString() ?? '';
  final unit = habit.unit ?? '';

  return Card(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  habit.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                target.isEmpty ? '' : 'Goal: $target$unit',
                style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onQuickAdd,
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Add entry',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(currentText, style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress01.clamp(0, 1),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Streak: —', style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
        ],
      ),
    ),
  );
}

}
