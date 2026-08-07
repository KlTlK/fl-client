import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'state/vpn_state.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => VpnState()..bootstrap(),
      child: const FlClientApp(),
    ),
  );
}

class FlClientApp extends StatelessWidget {
  const FlClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'fl-client',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const HomeScreen(),
    );
  }
}
