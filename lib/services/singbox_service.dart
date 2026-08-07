import 'dart:async';
import '../core/singbox_ffi.dart';
import '../core/proxy_parser.dart';
import '../core/singbox_outbound_builder.dart';

/// Сервис поверх FFI-ядра с корректным lifecycle (graceful shutdown, propagate ошибок стопа).
class SingBoxService {
  final SingBoxFFI _ffi = SingBoxFFI();
  int _handle = 0;
  bool get running => _handle > 0;
  bool get coreAvailable => _ffi.isLoaded;
  String? get coreError => _ffi.loadError;

  List<ParsedNode> _nodes = const [];
  List<ParsedNode> get nodes => _nodes;

  List<ParsedNode> importConfig(String input) {
    _nodes = ProxyParser.parseAny(input);
    return _nodes;
  }

  Future<void> startNode(ParsedNode node) async {
    if (!_ffi.isLoaded) {
      throw StateError(_ffi.loadError ?? 'native core not loaded');
    }
    final config = SingBoxOutboundBuilder.buildFullConfig(node);
    final err = _ffi.validate(config);
    if (err.isNotEmpty) throw ArgumentError('sing-box config invalid: $err');
    final h = _ffi.start(config);
    if (h <= 0) throw StateError('sing-box failed to start (code $h)');
    _handle = h;
  }

  Future<void> startFirst() async {
    if (_nodes.isEmpty) throw StateError('no nodes imported');
    await startNode(_nodes.first);
  }

  /// Graceful stop: сначала мягкий shutdown (даёт кору закрыть TUN/соединения),
  /// потом жёсткий stop если нужно. Ошибки стопа пробрасываются наружу (OneXray-style).
  Future<void> stop() async {
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
      // propagate desktop core stop failure
      throw StateError('core stop failed: ${firstError ?? e}');
    } finally {
      _handle = 0;
    }
    if (firstError != null) {
      // мягкий shutdown упал, но жёсткий стоп прошёл - сообщаем, но не валим.
      throw StateError('core shutdown warning: $firstError');
    }
  }
}
