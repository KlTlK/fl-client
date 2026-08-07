import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

/// Низкоуровневые FFI-биндинги к собранному sing-box ядру (libbox).
/// Контракт функций повторяет sing-box experimental/libbox API.
/// Для типобезопасной версии из C-хедеров: `dart run ffigen --config ffigen.yaml`.
class SingBoxFFI {
  static SingBoxFFI? _instance;
  factory SingBoxFFI() => _instance ??= SingBoxFFI._();

  late final DynamicLibrary _lib;
  late final int Function(Pointer<Utf8>) _start;
  late final int Function(int) _stop;
  late final Pointer<Utf8> Function(Pointer<Utf8>) _validate;
  // graceful shutdown: даёт кору время закрыть TUN/соединения (OneXray-style lifecycle).
  late final int Function(int, int) _shutdown;

  bool _loaded = false;
  String? loadError;

  SingBoxFFI._() {
    try {
      _lib = _open();
      _start = _lib.lookupFunction<Int32 Function(Pointer<Utf8>), int Function(Pointer<Utf8>)>('box_start');
      _stop = _lib.lookupFunction<Int32 Function(Int64), int Function(int)>('box_stop');
      _validate = _lib.lookupFunction<Pointer<Utf8> Function(Pointer<Utf8>), Pointer<Utf8> Function(Pointer<Utf8>)>('box_validate');
      // shutdown может отсутствовать в старых сборках - ловим мягко.
      try {
        _shutdown = _lib.lookupFunction<Int32 Function(Int64, Int32), int Function(int, int)>('box_shutdown');
      } catch (_) {
        _shutdown = (h, t) => _stop(h);
      }
      _loaded = true;
    } catch (e) {
      loadError = 'native lib not available: $e';
    }
  }

  bool get isLoaded => _loaded;

  DynamicLibrary _open() {
    if (Platform.isAndroid) return DynamicLibrary.open('libsingbox.so');
    if (Platform.isWindows) return DynamicLibrary.open('libsingbox.dll');
    if (Platform.isMacOS) return DynamicLibrary.open('libsingbox.dylib');
    return DynamicLibrary.open('libsingbox.so');
  }

  int start(String configJson) {
    if (!_loaded) throw StateError(loadError ?? 'ffi not loaded');
    final p = configJson.toNativeUtf8();
    try {
      return _start(p);
    } finally {
      calloc.free(p);
    }
  }

  /// Жёсткий стоп.
  int stop(int handle) {
    if (!_loaded || handle <= 0) return 0;
    return _stop(handle);
  }

  /// Graceful shutdown с таймаутом (мс). Даёт кору закрыть TUN и соединения.
  int shutdown(int handle, {int timeoutMs = 3000}) {
    if (!_loaded || handle <= 0) return 0;
    return _shutdown(handle, timeoutMs);
  }

  String validate(String configJson) {
    if (!_loaded) return loadError ?? 'ffi not loaded';
    final p = configJson.toNativeUtf8();
    try {
      final res = _validate(p);
      return res.toDartString();
    } finally {
      calloc.free(p);
    }
  }
}
