import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/proxy_parser.dart';

enum PingMethod { tcp, httpGet }

class PingResult {
  final int? ms; // null = таймаут/ошибка
  final bool ok;
  const PingResult(this.ms, this.ok);
  static const failed = PingResult(null, false);
}

/// Измеряет задержку до узла двумя способами:
/// - [PingMethod.tcp] — время TCP-подключения к host:port (raw latency) [[1]][[4]].
/// - [PingMethod.httpGet] — время полного HTTP GET (для http/https прокси) [[9]].
class Pinger {
  final Duration timeout;
  Pinger({this.timeout = const Duration(seconds: 5)});

  Future<PingResult> ping(ParsedNode node, {PingMethod method = PingMethod.tcp}) {
    return method == PingMethod.tcp ? _tcp(node) : _httpGet(node);
  }

  Future<PingResult> _tcp(ParsedNode node) async {
    final sw = Stopwatch()..start();
    Socket? socket;
    try {
      socket = await Socket.connect(node.host, node.port, timeout: timeout);
      sw.stop();
      return PingResult(sw.elapsedMilliseconds, true);
    } catch (_) {
      return PingResult.failed;
    } finally {
      try {
        await socket?.close();
      } catch (_) {}
    }
  }

  Future<PingResult> _httpGet(ParsedNode node) async {
    final sw = Stopwatch()..start();
    try {
      // Делаем GET через сам узел как http-прокси если возможно, иначе прямой GET к host.
      final uri = Uri.parse('http://${node.host}:${node.port}/');
      final resp = await http.get(uri, headers: {'User-Agent': 'fl-client-ping'})
          .timeout(timeout);
      sw.stop();
      return PingResult(sw.elapsedMilliseconds, resp.statusCode < 500);
    } catch (_) {
      return PingResult.failed;
    }
  }
}
