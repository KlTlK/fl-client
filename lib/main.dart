import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'state/vpn_state.dart';
import 'screens/home_screen.dart';

void main() async {
  // Ловим все ошибки и пишем в файл рядом с exe чтоб можно было дебажить
  FlutterError.onError = (details) {
    _logError('FlutterError: ${details.exception}\n${details.stack}');
    FlutterError.presentError(details);
  };

  try {
    runApp(
      ChangeNotifierProvider(
        create: (_) => VpnState(),
        child: const FlClientApp(),
      ),
    );
  } catch (e, st) {
    _logError('FATAL: $e\n$st');
    // Fallback: покажем ошибку в нативном диалоге если Flutter не стартанул
    stderr.writeln('FATAL: $e');
    exitCode = 1;
  }
}

void _logError(String msg) {
  try {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    File('$exeDir${Platform.pathSeparator}crash.log').writeAsStringSync(
      '${DateTime.now()}\n$msg\n---\n',
      mode: FileMode.append,
    );
  } catch (_) {}
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
