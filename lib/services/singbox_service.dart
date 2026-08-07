import 'dart:io';
import '../core/singbox_ffi.dart';
import '../core/proxy_parser.dart';
import '../core/singbox_outbound_builder.dart';
import 'singbox_process_service.dart';

/// Сервис ядра. На Android/macOS/Linux - FFI (in-process libbox).
/// На Windows - process mode (sing-box.exe), т.к. dll/cgo путь нестабилен.
class SingBoxService {
  final SingBoxFFI _ffi = SingBoxFFI();
  final SingBoxProcessService _proc = SingBoxProcessService();

  int _handle = 0;
  bool get running => _handle > 0 || _proc.running;

  bool get _useProcess => Platform.isWindows;

  bool get coreAvailable {
    if (_useProcess) return true; // exe проверится при старте
    return _ffi.isLoaded;
  }
  String? get coreError => _useProcess ? null : _ffi.loadError;

  List<ParsedNode> _nodes = const [];
  List<ParsedNode> get nodes => _nodes;

  List<ParsedNode> importConfig(String input) {
    _nodes = ProxyParser.parseAny(input);
    return _nodes;
  }

  Future<void> startNode(ParsedNode node) async {
    if (_useProcess) {
      await _proc.start(node);
      return;
    }
    if (!_ffi.isLoaded) throw StateError(_ffi.loadError ?? 'native core not loaded');
    final config = SingBoxOutboundBuilder.buildFullConfig(node);
    final err = _ffi.validate(config);
    if (err.isNotEmpty) throw ArgumentError('sing-box config invalid: $err');
    final h = _ffi.start(config);
    if (h <= 0) throw StateError('sing-box failed to start (code $h)');
    _handle = h;
  }

  Future<void> stop() async {
    if (_useProcess) {
      await _proc.stop();
      return;
    }
    if (_handle <= 0) return;
    final h = _handle;
    Object? firstError;
    try {
      _ffi.shutdown(h, timeoutMs: 3000);
    } catch (e) {
      firstError = e;
    }
    try {
      _ffi.stop(h);
    } catch (e) {
      throw StateError('core stop failed: ${firstError ?? e}');
    } finally {
      _handle = 0;
    }
    if (firstError != null) throw StateError('core shutdown warning: $firstError');
  }

  List<String> get processLogs => _proc.logs;
  void clearLogs() => _proc.clearLogs();

}
