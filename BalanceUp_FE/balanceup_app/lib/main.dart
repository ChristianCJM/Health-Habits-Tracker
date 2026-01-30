import 'package:balanceup_app/api/balanceup_api.dart';
import 'package:balanceup_app/session.dart';
import 'package:balanceup_app/token_store.dart';
import 'package:flutter/material.dart';
import 'notifications/notification_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await NotificationService.scheduleTestIn2Minutes();
  await NotificationService.initAndSchedule();
  final savedToken = await TokenStore.load();
  if (savedToken != null && savedToken.isNotEmpty) {
    AppSession.token = savedToken;
  }
  final api = BalanceUpApi(baseUrl: 'http://localhost:8080');

  runApp(BalanceUpApp(api: api));
}
