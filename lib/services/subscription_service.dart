import 'dart:io';
import '../core/proxy_parser.dart';

class SubscriptionService {
  Future<List<ParsedNode>> fetch(String url) async {
    // Используем системный curl - он правильно handling куки + TLS fingerprint
    final tmpCookie = '${Directory.systemTemp.path}${Platform.pathSeparator}fl_sub_cookies.txt';
    final tmpOut = '${Directory.systemTemp.path}${Platform.pathSeparator}fl_sub_response.txt';

    // Удаляем старые файлы
    try { File(tmpCookie).deleteSync(); } catch (_) {}
    try { File(tmpOut).deleteSync(); } catch (_) {}

    final result = await Process.run('curl', [
      '-L',                    // follow redirects
      '-s',                    // silent
      '-S',                    // show errors
      '--max-redirs', '10',
      '-c', tmpCookie,         // save cookies
      '-b', tmpCookie,         // send cookies
      '-A', 'v2rayN/6.23',    // user agent
      '-o', tmpOut,            // output to file
      '--connect-timeout', '15',
      '--max-time', '30',
      url.trim(),
    ]);

    if (result.exitCode != 0) {
      throw StateError('curl failed (exit ${result.exitCode}): ${result.stderr.toString().trim()}');
    }

    final file = File(tmpOut);
    if (!file.existsSync() || file.lengthSync() == 0) {
      throw StateError('Empty response from server');
    }

    final body = file.readAsStringSync().trim();

    // Cleanup
    try { File(tmpCookie).deleteSync(); } catch (_) {}
    try { File(tmpOut).deleteSync(); } catch (_) {}

    final nodes = ProxyParser.parseAny(body);
    if (nodes.isEmpty) throw StateError('No supported links (${body.length} bytes)');
    return nodes;
  }

  void dispose() {}
}
