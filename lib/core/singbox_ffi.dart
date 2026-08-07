import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

/// FFI биндинги к sing-box. LAZY init - не грузим либу при старте приложения.
class SingBoxFFI {
  static SingBoxFFI? _instance;
  factory SingBoxFFI() => _instance ??= SingBoxFFI._();

  DynamicLibrary? _lib;
  int Function(Pointer<Utf8>)? _start;
  int Function(int)? _stop;
  Pointer<Utf8> Function(Pointer<Utf8>)? _validate;
  int Function(int, int)? _shutdown;

  bool _loaded = false;
  bool _triedLoad = false;
  String? loadError;

  SingBoxFFI._();

  bool get isLoaded {
    _ensureLoaded();
    return _loaded;
  }

  void _ensureLoaded() {
    if (_triedLoad) return;
    _triedLoad = true;
    try {
      _lib = _open();
      _start = _lib!.lookupFunction<Int32 Function(Pointer<Utf8>), int Function(Pointer<Utf8>)>('box_start');
      _stop = _lib!.lookupFunction<Int32 Function(Int64), int Function(int)>('box_stop');
      _validate = _lib!.lookupFunction<Pointer<Utf8> Function(Pointer<Utf8>), Pointer<Utf8> Function(Pointer<Utf8>)>('box_validate');
      try {
        _shutdown = _lib!.lookupFunction<Int32 Function(Int64, Int32), int Function(int, int)>('box_shutdown');
      } catch (_) {
        _shutdown = (h, t) => _stop!(h);
      }
      _loaded = true;
    } catch (e) {
      loadError = 'native lib not available: $e';
      _loaded = false;
    }
  }

  DynamicLibrary _open() {
    if (Platform.isAndroid) return DynamicLibrary.open('libsingbox.so');
    if (Platform.isWindows) return DynamicLibrary.open('libsingbox.dll');
    if (Platform.isMacOS) return DynamicLibrary.open('libsingbox.dylib');
    return DynamicLibrary.open('libsingbox.so');
  }

  int start(String configJson) {
    _ensureLoaded();
    if (!_loaded) throw StateError(loadError ?? 'ffi not loaded');
    final p = configJson.toNativeUtf8();
    try {
      return _start!(p);
    } finally {
      calloc.free(p);
    }
  }

  int stop(int handle) {
    if (!_loaded || handle <= 0) return 0;
    return _stop!(handle);
  }

  int shutdown(int handle, {int timeoutMs = 3000}) {
    if (!_loaded || handle <= 0) return 0;
    return _shutdown!(handle, timeoutMs);
  }

  String validate(String configJson) {
    _ensureLoaded();
    if (!_loaded) return loadError ?? 'ffi not loaded';
    final p = configJson.toNativeUtf8();
    try {
      final res = _validate!(p);
      return res.toDartString();
    } finally {
      calloc.free(p);
    }
  }
}
