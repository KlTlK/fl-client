import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../core/proxy_parser.dart';
import '../core/singbox_outbound_builder.dart';

/// Windows: запускаем готовый sing-box.exe как процесс (flux-vpn / XrayUI подход).
/// sing-box.exe лежит либо в libs/windows/ (dev), либо рядом с fl_client.exe (dist).
class SingBoxProcessService {
  Process? _proc;
  bool get running => _proc != null;
  final List<String> _logs = [];
  List<String> get logs => List.unmodifiable(_logs);

  String _exePath() {
    // 1) Рядом с исполняемым файлом (dist-сборка)
    final exeDir = Platform.resolvedExecutable;
    final nextToExe = File('${File(exeDir).parent.path}${Platform.pathSeparator}sing-box.exe');
    if (nextToExe.existsSync()) return nextToExe.path;
    // 2) libs/windows/ (dev / repo layout)
    const dev = 'libs/windows/sing-box.exe';
    if (File(dev).existsSync()) return dev;
    // 3) working dir
    if (File('sing-box.exe').existsSync()) return 'sing-box.exe';
    return nextToExe.path; // fallback
  }

  Future<void> start(ParsedNode node) async {
    final config = SingBoxOutboundBuilder.buildFullConfig(node);
    final tmp = await File('${Directory.systemTemp.path}/fl_client_singbox.json').writeAsString(config);
    final exe = _exePath();
    if (!File(exe).existsSync()) {
      throw StateError('sing-box.exe not found at $exe — run scripts/fetch_sing_box.ps1 or place it next to the app');
    }
    _proc = await Process.start(exe, ['run', '-c', tmp.path, '--disable-color']);
    _proc!.stdout.transform(utf8.decoder).listen((l) => _logs.add(l));
    _proc!.stderr.transform(utf8.decoder).listen((l) => _logs.add('[err] $l'));
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
