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
    // Write to file
    try {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      File('$exeDir${Platform.pathSeparator}singbox.log').writeAsStringSync(
        _logs.join('\n'), mode: FileMode.writeOnly,
      );
    } catch (_) {}
  }

  Future<void> start(ParsedNode node) async {
    final config = SingBoxOutboundBuilder.buildFullConfig(node);
    final tmp = await File('${Directory.systemTemp.path}${Platform.pathSeparator}fl_client_singbox.json').writeAsString(config);
    _log('Config written to ${tmp.path}');
    _log('Config: $config');
    
    final exe = _exePath();
    _log('sing-box path: $exe (exists: ${File(exe).existsSync()})');
    
    if (!File(exe).existsSync()) {
      throw StateError('sing-box.exe not found at $exe');
    }
    
    _log('Starting: $exe run -c ${tmp.path}');
    _proc = await Process.start(exe, ['run', '-c', tmp.path, '--disable-color']);
    _log('Process started, pid: ${_proc!.pid}');
    
    _proc!.stdout.transform(utf8.decoder).listen((l) {
      for (final line in l.split('\n')) {
        if (line.trim().isNotEmpty) _log('stdout: $line');
      }
    });
    _proc!.stderr.transform(utf8.decoder).listen((l) {
      for (final line in l.split('\n')) {
        if (line.trim().isNotEmpty) _log('stderr: $line');
      }
    });
    _proc!.exitCode.then((code) => _log('Process exited with code: $code'));
    
    await Future.delayed(const Duration(seconds: 2));
    if (_logs.any((l) => l.contains('exited with code'))) {
      throw StateError('sing-box crashed immediately. Check singbox.log');
    }
  }

  Future<void> stop() async {
    final p = _proc;
    if (p == null) return;
    _proc = null;
    _log('Stopping process...');
    p.kill(ProcessSignal.sigterm);
    await p.exitCode.timeout(const Duration(seconds: 3), onTimeout: () {
      p.kill(ProcessSignal.sigkill);
      return -1;
    });
    _log('Process stopped');
  }
}
