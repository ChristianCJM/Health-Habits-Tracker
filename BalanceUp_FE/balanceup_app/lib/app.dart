import 'package:flutter/material.dart';
import 'api/balanceup_api.dart';
import 'session.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/profile_screen.dart';

class BalanceUpApp extends StatefulWidget {
  final BalanceUpApi api;
  const BalanceUpApp({super.key, required this.api});

  @override
  State<BalanceUpApp> createState() => _BalanceUpAppState();
}

class _BalanceUpAppState extends State<BalanceUpApp> {
  int _index = 0;

  void _onLoggedIn(String token) {
    setState(() {
      AppSession.token = token;
      _index = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
  Material(child: HomeScreen(api: widget.api)),
  Material(child: HistoryScreen(api: widget.api)),
  Material(child: StatsScreen(api: widget.api)),
  Material(child: ProfileScreen(api: widget.api)),
];
    return MaterialApp(
  title: 'BalanceUp',
  theme: ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF6F7FB),
  ),
  home: Scaffold(
    body: SafeArea(
      child: AppSession.isLoggedIn
          ? pages[_index]
          : LoginScreen(
              api: widget.api,
              onLoggedIn: _onLoggedIn,
            ),
    ),
    bottomNavigationBar: AppSession.isLoggedIn
        ? NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.history), label: 'History'),
              NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'Stats'),
              NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
            ],
          )
        : null,
  ),
);

  }
  }
