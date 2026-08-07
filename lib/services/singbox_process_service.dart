import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../core/proxy_parser.dart';
import '../core/singbox_outbound_builder.dart';

/// Windows: запускаем собранный sing-box.exe как процесс с конфигом (XrayUI-style).
/// На винде FFI/dll путь сложен, поэтому process mode - надёжный рабочий вариант.
class SingBoxProcessService {
  Process? _proc;
  bool get running => _proc != null;
  final List<String> _logs = [];
  List<String> get logs => List.unmodifiable(_logs);

  /// Путь к sing-box.exe (лежит рядом с exe или в libs/windows/).
  String _exePath() {
    final candidates = [
      'libs/windows/sing-box.exe',
      'sing-box.exe',
      Platform.script.toFilePath().replaceAll(RegExp(r'[^\\/]+$'), '') + 'sing-box.exe',
    ];
    for (final c in candidates) {
      if (File(c).existsSync()) return c;
    }
    return 'sing-box.exe'; // fallback, упадёт с понятной ошибкой
  }

  Future<void> start(ParsedNode node) async {
    final config = SingBoxOutboundBuilder.buildFullConfig(node);
    // sing-box run -c <config>  (конфиг через stdin не поддерживается стабильно, пишем во временный файл)
    final tmp = await File('${Directory.systemTemp.path}/fl_client_singbox.json').writeAsString(config);
    final exe = _exePath();
    if (!File(exe).existsSync()) {
      throw StateError('sing-box.exe not found at $exe — build it via build-core.yml or place next to the app');
    }
    _proc = await Process.start(exe, ['run', '-c', tmp.path, '--disable-color']);
    _proc!.stdout.transform(utf8.decoder).listen((l) => _logs.add(l));
    _proc!.stderr.transform(utf8.decoder).listen((l) => _logs.add('[err] $l'));
    // Даём кору стартануть и проверяем что не упал сразу.
    await Future.delayed(const Duration(milliseconds: 800));
  }

  Future<void> stop() async {
    final p = _proc;
    if (p == null) return;
    _proc = null;
    p.kill(ProcessSignal.sigterm);
    await p.exitCode.timeout(const Duration(seconds: 3), onTimeout: () {
      p.kill(ProcessSignal.sigkill);
      return -1;
    });
  }
}
