import 'dart:async';
import '../core/singbox_ffi.dart';
import '../core/proxy_parser.dart';
import '../core/singbox_outbound_builder.dart';

/// Сервис поверх FFI-ядра. Принимает сырую строку (ссылку или base64-саб),
/// парсит через [ProxyParser], собирает sing-box config через [SingBoxOutboundBuilder],
/// валидирует и стартует кор. Жрёт любые сабы.
class SingBoxService {
  final SingBoxFFI _ffi = SingBoxFFI();
  int _handle = 0;
  bool get running => _handle > 0;

  List<ParsedNode> _nodes = const [];
  List<ParsedNode> get nodes => _nodes;

  /// Импортирует подписку/ссылку. Возвращает распарсенные узлы.
  List<ParsedNode> importConfig(String input) {
    _nodes = ProxyParser.parseAny(input);
    return _nodes;
  }

  Future<void> startNode(ParsedNode node) async {
    final config = SingBoxOutboundBuilder.buildFullConfig(node);
    final err = _ffi.validate(config);
    if (err.isNotEmpty) throw ArgumentError('sing-box config invalid: $err');
    final h = _ffi.start(config);
    if (h <= 0) throw StateError('sing-box failed to start (code $h)');
    _handle = h;
  }

  /// Стартует первый узел из импортированного саба.
  Future<void> startFirst() async {
    if (_nodes.isEmpty) throw StateError('no nodes imported');
    await startNode(_nodes.first);
  }

  Future<void> stop() async {
    if (_handle > 0) {
      _ffi.stop(_handle);
      _handle = 0;
    }
  }
}
