import 'dart:io';
import 'package:flutter/material.dart';

void main() {
  // Write a file immediately to prove Dart is running
  try {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    File('$exeDir\\dart_alive.txt').writeAsStringSync('Dart main() executed at ${DateTime.now()}');
  } catch (_) {}

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Color(0xFF0E1117),
      body: Center(
        child: Text('fl-client is alive!', style: TextStyle(color: Color(0xFF3DF5C8), fontSize: 24)),
      ),
    ),
  ));
}
