import 'package:balanceup_app/token_store.dart';
import 'package:flutter/material.dart';
import '../api/balanceup_api.dart';
import '../session.dart';
import 'add_habit_screen.dart';

class ProfileScreen extends StatelessWidget {
  final BalanceUpApi api;
  const ProfileScreen({super.key, required this.api});

  @override
  Widget build(BuildContext context) {
    final tokenPreview = (AppSession.token ?? '').isEmpty
        ? '(no token)'
        : '${AppSession.token!.substring(0, 8)}...';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profile', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Session', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Token: $tokenPreview'),
                  const SizedBox(height: 8),
                  const Text(
                    'Note: token is stored in memory only (no persistence).',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => AddHabitScreen(api: api)),
                );
                if (created == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Habit created')),
                  );
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Habit'),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await TokenStore.clear();
                AppSession.clear();
                (context as Element).markNeedsBuild();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }
}
