import 'package:flutter/services.dart';
import '../core/proxy_parser.dart';
import 'subscription_service.dart';

/// Фасад импорта: из буфера обмена, по URL, или из строки (QR-сканер передаёт строку).
class ConfigImporter {
  final SubscriptionService _subs = SubscriptionService();

  /// Из произвольной строки (ссылка / base64 / пачка) - то что дал QR или вставил юзер.
  List<ParsedNode> fromString(String raw) => ProxyParser.parseAny(raw);

  /// Из буфера обмена.
  Future<List<ParsedNode>> fromClipboard() async {
    final raw = await Clipboard.getData(Clipboard.kTextPlain);
    if (raw == null || raw.text == null || raw.text!.trim().isEmpty) {
      return const [];
    }
    return ProxyParser.parseAny(raw.text!);
  }

  /// По URL подписки (HTTPS).
  Future<List<ParsedNode>> fromUrl(String url) => _subs.fetch(url);

  void dispose() => _subs.dispose();
}
