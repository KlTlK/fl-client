import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../core/proxy_parser.dart';
import '../core/singbox_outbound_builder.dart';

class SingBoxProcessService {
  Process? _proc;
  bool get running => _proc != null;
  final List<String> _logs = [];
  List<String> get logs => List.unmodifiable(_logs);

  void clearLogs() => _logs.clear();

  String _exePath() {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final nextToExe = File('$exeDir${Platform.pathSeparator}sing-box.exe');
    if (nextToExe.existsSync()) return nextToExe.path;
    const dev = 'libs/windows/sing-box.exe';
    if (File(dev).existsSync()) return dev;
    if (File('sing-box.exe').existsSync()) return 'sing-box.exe';
    return nextToExe.path;
  }

  void _log(String msg) {
    _logs.add('[${DateTime.now().toIso8601String()}] $msg');
    if (_logs.length > 500) _logs.removeAt(0);
    try {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      File('$exeDir${Platform.pathSeparator}singbox.log').writeAsStringSync(
        _logs.join('\n'), mode: FileMode.writeOnly);
    } catch (_) {}
  }

  Future<void> start(ParsedNode node) async {
    final config = SingBoxOutboundBuilder.buildFullConfig(node);
    final tmpPath = '${Directory.systemTemp.path}${Platform.pathSeparator}fl_client_singbox.json';
    await File(tmpPath).writeAsString(config);
    _log('Config: $config');

    final exe = _exePath();
    _log('sing-box: $exe (exists: ${File(exe).existsSync()})');
    if (!File(exe).existsSync()) throw StateError('sing-box.exe not found at $exe');

    // Launch elevated via PowerShell Start-Process -Verb RunAs
    // This triggers UAC prompt and runs sing-box as admin
    final psCmd = 'Start-Process -FilePath "$exe" -ArgumentList "run","-c","$tmpPath","--disable-color" -Verb RunAs -PassThru -WindowStyle Hidden | Select-Object -ExpandProperty Id';
    _log('Elevating: $psCmd');

    final result = await Process.run('powershell', ['-Command', psCmd]);
    _log('PowerShell stdout: ${result.stdout.toString().trim()}');
    _log('PowerShell stderr: ${result.stderr.toString().trim()}');

    if (result.exitCode != 0) {
      throw StateError('Failed to elevate sing-box: ${result.stderr}');
    }

    final pidStr = result.stdout.toString().trim();
    final pid = int.tryParse(pidStr);
    if (pid == null || pid <= 0) {
      throw StateError('Failed to get sing-box PID (got: "$pidStr"). UAC denied?');
    }

    _log('sing-box started with PID: $pid (elevated)');

    // Store PID for later kill
    _pid = pid;

    // Wait a bit and check if process is still alive
    await Future.delayed(const Duration(seconds: 2));
    final checkResult = await Process.run('powershell', [
      '-Command', 'Get-Process -Id $pid -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id'
    ]);
    if (checkResult.stdout.toString().trim().isEmpty) {
      // Process died - read log file for error
      final logFile = File('$tmpPath.log');
      String extra = '';
      if (logFile.existsSync()) extra = logFile.readAsStringSync();
      throw StateError('sing-box crashed after elevation. Check singbox.log. $extra');
    }

    _log('sing-box is running (PID $pid confirmed)');
  }

  int? _pid;

  Future<void> stop() async {
    final pid = _pid;
    if (pid == null) return;
    _pid = null;
    _log('Stopping sing-box PID: $pid');
    await Process.run('taskkill', ['/PID', '$pid', '/F']);
    _log('Stopped');
  }
}
