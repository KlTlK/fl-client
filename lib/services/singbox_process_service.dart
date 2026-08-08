import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../core/proxy_parser.dart';
import '../core/singbox_outbound_builder.dart';

class SingBoxProcessService {
  Process? _proc;
  int? _pid;
  bool get running => _pid != null;
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
    _log('Config written');

    final exe = _exePath();
    _log('sing-box: $exe (exists: ${File(exe).existsSync()})');
    if (!File(exe).existsSync()) throw StateError('sing-box.exe not found at $exe');

    // Launch elevated
    final psCmd = 'Start-Process -FilePath "$exe" -ArgumentList "run","-c","$tmpPath","--disable-color" -Verb RunAs -PassThru -WindowStyle Hidden | Select-Object -ExpandProperty Id';
    _log('Elevating sing-box...');

    final result = await Process.run('powershell', ['-Command', psCmd]);
    _log('PS stdout: ${result.stdout.toString().trim()}');
    if (result.stderr.toString().trim().isNotEmpty) _log('PS stderr: ${result.stderr.toString().trim()}');

    if (result.exitCode != 0) throw StateError('Elevation failed: ${result.stderr}');

    final pid = int.tryParse(result.stdout.toString().trim());
    if (pid == null || pid <= 0) throw StateError('No PID returned. UAC denied?');

    _pid = pid;
    _log('sing-box PID: $pid (elevated)');

    await Future.delayed(const Duration(seconds: 3));

    // Check if still alive
    final check = await Process.run('powershell', [
      '-Command', '(Get-Process -Id $pid -ErrorAction SilentlyContinue) -ne \$null'
    ]);
    if (check.stdout.toString().trim() != 'True') {
      _pid = null;
      throw StateError('sing-box crashed after start. Check singbox.log');
    }
    _log('sing-box running OK');
  }

  Future<void> stop() async {
    final pid = _pid;
    if (pid == null) return;
    _log('Stopping sing-box PID: $pid (graceful)...');

    // Graceful: send CTRL+C equivalent via taskkill without /F first
    await Process.run('taskkill', ['/PID', '$pid']);
    
    // Wait for graceful shutdown (sing-box cleans up TUN routes on SIGTERM)
    await Future.delayed(const Duration(seconds: 3));

    // Check if still alive, force kill if needed
    final check = await Process.run('powershell', [
      '-Command', '(Get-Process -Id $pid -ErrorAction SilentlyContinue) -ne \$null'
    ]);
    if (check.stdout.toString().trim() == 'True') {
      _log('Force killing...');
      await Process.run('taskkill', ['/PID', '$pid', '/F']);
      await Future.delayed(const Duration(seconds: 1));
    }

    // Restore default route just in case
    await Process.run('powershell', [
      '-Command', 'Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | ForEach-Object { Remove-NetRoute -InterfaceIndex \$_.InterfaceIndex -DestinationPrefix "0.0.0.0/0" -Confirm:\$false -ErrorAction SilentlyContinue }; Get-NetIPInterface -AddressFamily IPv4 | Where-Object { \$_.ConnectionState -eq "Connected" } | ForEach-Object { New-NetRoute -InterfaceIndex \$_.InterfaceIndex -DestinationPrefix "0.0.0.0/0" -NextHop (Get-NetIPConfiguration -InterfaceIndex \$_.InterfaceIndex | Select-Object -ExpandProperty IPv4DefaultGateway | Select-Object -ExpandProperty NextHop) -ErrorAction SilentlyContinue }'
    ]);
    _log('Routes restored');

    _pid = null;
    _log('Stopped');
  }
}
