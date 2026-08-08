import 'dart:async';
import 'dart:io';
import '../core/proxy_parser.dart';
import '../core/singbox_outbound_builder.dart';

class SingBoxProcessService {
  int? _singboxPid;
  bool _running = false;
  bool get running => _running;
  final List<String> _logs = [];
  List<String> get logs => List.unmodifiable(_logs);
  void clearLogs() => _logs.clear();
  Timer? _tailTimer;

  String _exePath() {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final nextToExe = File('$exeDir${Platform.pathSeparator}sing-box.exe');
    if (nextToExe.existsSync()) return nextToExe.path;
    const dev = 'libs/windows/sing-box.exe';
    if (File(dev).existsSync()) return dev;
    return nextToExe.path;
  }

  String get _logPath => '${File(Platform.resolvedExecutable).parent.path}${Platform.pathSeparator}singbox.log';

  void _log(String msg) {
    _logs.add('[${DateTime.now().toIso8601String()}] $msg');
    if (_logs.length > 500) _logs.removeAt(0);
  }

  List<String> _readLogTail([int n = 50]) {
    try {
      final f = File(_logPath);
      if (!f.existsSync()) return [];
      final lines = f.readAsLinesSync();
      return lines.length > n ? lines.sublist(lines.length - n) : lines;
    } catch (_) { return []; }
  }

  Future<void> start(ParsedNode node) async {
    if (_running) return; // Already running, ignore

    final config = SingBoxOutboundBuilder.buildFullConfig(node);
    final tmpPath = '${Directory.systemTemp.path}${Platform.pathSeparator}fl_client_singbox.json';
    await File(tmpPath).writeAsString(config);
    _log('Config written');

    final exe = _exePath();
    if (!File(exe).existsSync()) throw StateError('sing-box.exe not found at $exe');

    // Validate
    _log('Validating config...');
    final checkResult = await Process.run(exe, ['check', '-c', tmpPath]);
    final checkOut = '${checkResult.stdout}\n${checkResult.stderr}'.trim();
    if (checkOut.isNotEmpty) _log('check: $checkOut');
    if (checkResult.exitCode != 0) throw StateError('Config invalid:\n$checkOut');
    _log('Config valid ✓');

    // Clear old log
    try { File(_logPath).deleteSync(); } catch (_) {}

    // Launch elevated with log redirect
    final scriptPath = '${Directory.systemTemp.path}${Platform.pathSeparator}fl_singbox_launch.ps1';
    final script = '''
\$logFile = "$_logPath"
\$id = [Security.Principal.WindowsIdentity]::GetCurrent()
\$pr = New-Object Security.Principal.WindowsPrincipal(\$id)
\$isAdmin = \$pr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
"[\$(Get-Date -Format o)] admin=\$isAdmin" | Out-File \$logFile -Encoding utf8
& "$exe" run -c "$tmpPath" --disable-color *>> \$logFile 2>&1
"[\$(Get-Date -Format o)] exit=\$LASTEXITCODE" | Out-File \$logFile -Append -Encoding utf8
''';
    await File(scriptPath).writeAsString(script);

    _log('Elevating...');
    final launchResult = await Process.run('powershell', [
      '-Command',
      'Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile","-ExecutionPolicy","Bypass","-File","$scriptPath" -WindowStyle Hidden -PassThru | Select-Object -ExpandProperty Id'
    ]);

    final wrapperPid = int.tryParse(launchResult.stdout.toString().trim());
    if (wrapperPid == null || wrapperPid <= 0) {
      throw StateError('Elevation failed. UAC denied?');
    }
    _log('Wrapper PID: $wrapperPid');

    // Wait for sing-box to start and find its PID
    await Future.delayed(const Duration(seconds: 3));

    // Find sing-box.exe process
    final findResult = await Process.run('powershell', [
      '-Command', '(Get-Process sing-box -ErrorAction SilentlyContinue | Select-Object -First 1).Id'
    ]);
    final sbPid = int.tryParse(findResult.stdout.toString().trim());
    if (sbPid == null || sbPid <= 0) {
      final crashLog = _readLogTail(50).join('\n');
      throw StateError('sing-box crashed after start.\nsingbox.log:\n$crashLog');
    }

    _singboxPid = sbPid;
    _running = true;
    _log('sing-box running PID: $sbPid');

    // Start tailing
    _startTailing();
  }

  void _startTailing() {
    _tailTimer?.cancel();
    var lastCount = 0;
    _tailTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      final lines = _readLogTail(200);
      if (lines.length > lastCount) {
        for (var i = lastCount; i < lines.length; i++) _log('sb: ${lines[i]}');
        lastCount = lines.length;
      }
    });
  }

  Future<void> stop() async {
    _tailTimer?.cancel();
    _tailTimer = null;

    if (!_running && _singboxPid == null) return;

    final pid = _singboxPid;
    _log('Stopping sing-box (PID: $pid)...');

    // Kill sing-box.exe directly by PID
    if (pid != null) {
      await Process.run('taskkill', ['/PID', '$pid', '/F']);
    }

    // Also kill any remaining sing-box.exe processes by name
    await Process.run('taskkill', ['/IM', 'sing-box.exe', '/F']);

    await Future.delayed(const Duration(seconds: 2));

    // Verify it's dead
    final check = await Process.run('powershell', [
      '-Command', '(Get-Process sing-box -ErrorAction SilentlyContinue) -ne \$null'
    ]);
    if (check.stdout.toString().trim() == 'True') {
      _log('Force killing remaining...');
      await Process.run('taskkill', ['/IM', 'sing-box.exe', '/F']);
      await Future.delayed(const Duration(seconds: 1));
    }

    // Restore routes
    await Process.run('powershell', [
      '-Command',
      'Get-NetIPInterface -AddressFamily IPv4 -ConnectionState Connected | ForEach-Object { \$idx = \$_.InterfaceIndex; \$existing = Get-NetRoute -InterfaceIndex \$idx -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue; if (\$existing) { \$gw = \$existing.NextHop | Select-Object -First 1; Remove-NetRoute -InterfaceIndex \$idx -DestinationPrefix "0.0.0.0/0" -Confirm:\$false -ErrorAction SilentlyContinue; New-NetRoute -InterfaceIndex \$idx -DestinationPrefix "0.0.0.0/0" -NextHop \$gw -ErrorAction SilentlyContinue } }'
    ]);

    _singboxPid = null;
    _running = false;
    _log('Stopped ✓');
  }
}
