import 'dart:async';
import 'dart:io';
import '../core/proxy_parser.dart';
import '../core/singbox_outbound_builder.dart';

class SingBoxProcessService {
  int? _pid;
  bool get running => _pid != null;
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
    if (File('sing-box.exe').existsSync()) return 'sing-box.exe';
    return nextToExe.path;
  }

  String get _logPath {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    return '$exeDir${Platform.pathSeparator}singbox.log';
  }

  void _log(String msg) {
    _logs.add('[${DateTime.now().toIso8601String()}] $msg');
    if (_logs.length > 500) _logs.removeAt(0);
  }

  /// Read last N lines from singbox.log
  List<String> _readLogTail([int n = 50]) {
    try {
      final f = File(_logPath);
      if (!f.existsSync()) return [];
      final lines = f.readAsLinesSync();
      return lines.length > n ? lines.sublist(lines.length - n) : lines;
    } catch (_) {
      return [];
    }
  }

  Future<void> start(ParsedNode node) async {
    final config = SingBoxOutboundBuilder.buildFullConfig(node);
    final tmpPath = '${Directory.systemTemp.path}${Platform.pathSeparator}fl_client_singbox.json';
    await File(tmpPath).writeAsString(config);
    _log('Config written to $tmpPath');

    final exe = _exePath();
    _log('sing-box: $exe (exists: ${File(exe).existsSync()})');
    if (!File(exe).existsSync()) throw StateError('sing-box.exe not found at $exe');

    // Step 1: Validate config with sing-box check (non-elevated is fine for validation)
    _log('Validating config: sing-box check -c ...');
    final checkResult = await Process.run(exe, ['check', '-c', tmpPath]);
    final checkOut = '${checkResult.stdout}\n${checkResult.stderr}'.trim();
    if (checkOut.isNotEmpty) _log('check output: $checkOut');
    if (checkResult.exitCode != 0) {
      throw StateError('Config invalid:\n$checkOut');
    }
    _log('Config valid ✓');

    // Step 2: Clear old log
    try { File(_logPath).deleteSync(); } catch (_) {}

    // Step 3: Launch elevated via powershell wrapper that redirects output to log file
    // The wrapper also checks admin token
    final psScript = '''
\$ErrorActionPreference = 'Stop'
\$logFile = '$_logPath'
# Check admin
\$id = [Security.Principal.WindowsIdentity]::GetCurrent()
\$pr = New-Object Security.Principal.WindowsPrincipal(\$id)
\$isAdmin = \$pr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
"admin=\$isAdmin" | Out-File -FilePath \$logFile -Encoding utf8
# Run sing-box, redirect all output to log
& '$exe' run -c '$tmpPath' --disable-color *>> \$logFile
"exit=\$LASTEXITCODE" | Out-File -FilePath \$logFile -Append -Encoding utf8
''';

    _log('Elevating sing-box with log redirect...');
    final result = await Process.run('powershell', [
      '-Command',
      'Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile","-Command",\'$psScript\' -WindowStyle Hidden -PassThru | Select-Object -ExpandProperty Id'
    ]);

    // Hmm, nested quoting is tricky. Let me use a simpler approach: write the script to a temp .ps1 file
    // Actually let me redo this with a temp script file approach
    
    final scriptPath = '${Directory.systemTemp.path}${Platform.pathSeparator}fl_singbox_launch.ps1';
    final scriptContent = '''
\$logFile = "$_logPath"
\$id = [Security.Principal.WindowsIdentity]::GetCurrent()
\$pr = New-Object Security.Principal.WindowsPrincipal(\$id)
\$isAdmin = \$pr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
"[\$(Get-Date -Format o)] admin=\$isAdmin" | Out-File -FilePath \$logFile -Encoding utf8
"[\$(Get-Date -Format o)] starting sing-box..." | Out-File -FilePath \$logFile -Append -Encoding utf8
& "$exe" run -c "$tmpPath" --disable-color *>> \$logFile 2>&1
"[\$(Get-Date -Format o)] exit=\$LASTEXITCODE" | Out-File -FilePath \$logFile -Append -Encoding utf8
''';
    await File(scriptPath).writeAsString(scriptContent);

    final launchResult = await Process.run('powershell', [
      '-Command',
      'Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile","-ExecutionPolicy","Bypass","-File","$scriptPath" -WindowStyle Hidden -PassThru | Select-Object -ExpandProperty Id'
    ]);

    final pidStr = launchResult.stdout.toString().trim();
    _log('Launch PS stdout: "$pidStr"');
    if (launchResult.stderr.toString().trim().isNotEmpty) {
      _log('Launch PS stderr: ${launchResult.stderr.toString().trim()}');
    }

    final pid = int.tryParse(pidStr);
    if (pid == null || pid <= 0) {
      throw StateError('Failed to elevate (no PID). UAC denied?\nPS stderr: ${launchResult.stderr}');
    }
    _pid = pid;
    _log('Elevated powershell PID: $pid');

    // Step 4: Wait and tail the log file
    await Future.delayed(const Duration(seconds: 3));

    // Read what singbox.log says so far
    final logTail = _readLogTail(30);
    for (final line in logTail) {
      _log('singbox: $line');
    }

    // Check if the powershell wrapper is still alive (meaning sing-box might still be running)
    final aliveCheck = await Process.run('powershell', [
      '-Command', '(Get-Process -Id $pid -ErrorAction SilentlyContinue) -ne \$null'
    ]);
    final alive = aliveCheck.stdout.toString().trim() == 'True';

    if (!alive) {
      // Crashed - show the log
      final crashLog = _readLogTail(50).join('\n');
      _pid = null;
      throw StateError('sing-box crashed after start.\nsingbox.log:\n$crashLog');
    }

    _log('sing-box appears running (wrapper PID $pid alive)');

    // Start tailing the log in real time
    _startTailing();
  }

  void _startTailing() {
    _tailTimer?.cancel();
    var lastLineCount = 0;
    _tailTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      final lines = _readLogTail(200);
      if (lines.length > lastLineCount) {
        for (var i = lastLineCount; i < lines.length; i++) {
          _log('singbox: ${lines[i]}');
        }
        lastLineCount = lines.length;
      }
      // Check if process died
      if (_pid != null) {
        Process.run('powershell', [
          '-Command', '(Get-Process -Id $_pid -ErrorAction SilentlyContinue) -ne \$null'
        ]).then((r) {
          if (r.stdout.toString().trim() != 'True' && _pid != null) {
            _log('sing-box process died!');
            _tailTimer?.cancel();
          }
        });
      }
    });
  }

  Future<void> stop() async {
    _tailTimer?.cancel();
    _tailTimer = null;
    final pid = _pid;
    if (pid == null) return;
    _log('Stopping (graceful)...');

    // Kill the powershell wrapper and its child sing-box
    await Process.run('taskkill', ['/PID', '$pid', '/T']);
    await Future.delayed(const Duration(seconds: 3));

    // Force kill if still alive
    final check = await Process.run('powershell', [
      '-Command', '(Get-Process -Id $pid -ErrorAction SilentlyContinue) -ne \$null'
    ]);
    if (check.stdout.toString().trim() == 'True') {
      _log('Force killing...');
      await Process.run('taskkill', ['/PID', '$pid', '/T', '/F']);
      await Future.delayed(const Duration(seconds: 1));
    }

    // Restore routes
    await Process.run('powershell', [
      '-Command',
      'Get-NetIPInterface -AddressFamily IPv4 -ConnectionState Connected | ForEach-Object { \$idx = \$_.InterfaceIndex; \$gw = (Get-NetRoute -InterfaceIndex \$idx -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Select-Object -First 1).NextHop; if (\$gw) { Remove-NetRoute -InterfaceIndex \$idx -DestinationPrefix "0.0.0.0/0" -Confirm:\$false -ErrorAction SilentlyContinue; New-NetRoute -InterfaceIndex \$idx -DestinationPrefix "0.0.0.0/0" -NextHop \$gw -ErrorAction SilentlyContinue } }'
    ]);
    _log('Routes restored');

    _pid = null;
    _log('Stopped');
  }
}
