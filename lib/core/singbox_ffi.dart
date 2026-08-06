import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

/// Низкоуровневые FFI-биндинги к собранному sing-box ядру (libbox / libsingbox).
/// Контракт функций повторяет sing-box experimental/libbox API [[16]]:
///   - BoxStart(configJson) / BoxStop(handle)
///   - ValidateConfig(configJson)
///   - SetLogCallback / traffic callbacks
///
/// Бинарь подгружается из libs/<platform> — его собирает CI-джоб build-core.yml
/// (gomobile для Android -> .aar/.so, go build cgo для Windows -> .dll) [[3]][[5]].
class SingBoxFFI {
  static SingBoxFFI? _instance;
  factory SingBoxFFI() => _instance ??= SingBoxFFI._();

  late final DynamicLibrary _lib;
  late final int Function(Pointer<Utf8>) _start;
  late final int Function(int) _stop;
  late final Pointer<Utf8> Function(Pointer<Utf8>) _validate;

  SingBoxFFI._() {
    _lib = _open();
    // Имена символов соответствуют экспорту libbox (adjust to your build).
    _start = _lib.lookupFunction<Int32 Function(Pointer<Utf8>), int Function(Pointer<Utf8>)>('box_start');
    _stop = _lib.lookupFunction<Int32 Function(Int64), int Function(int)>('box_stop');
    _validate = _lib.lookupFunction<Pointer<Utf8> Function(Pointer<Utf8>), Pointer<Utf8> Function(Pointer<Utf8>)>('box_validate');
  }

  DynamicLibrary _open() {
    if (Platform.isAndroid) {
      // На Android ядро лежит в нативной либе приложения (gomobile .so).
      return DynamicLibrary.open('libsingbox.so');
    } else if (Platform.isWindows) {
      return DynamicLibrary.open('libsingbox.dll');
    } else if (Platform.isMacOS) {
      return DynamicLibrary.open('libsingbox.dylib');
    } else {
      return DynamicLibrary.open('libsingbox.so');
    }
  }

  /// Стартует кор с JSON-конфигом. Возвращает handle (>0) или код ошибки.
  int start(String configJson) {
    final p = configJson.toNativeUtf8();
    try {
      return _start(p);
    } finally {
      calloc.free(p);
    }
  }

  int stop(int handle) => _stop(handle);

  /// Валидация конфига. Возвращает пустую строку если ок, иначе текст ошибки.
  String validate(String configJson) {
    final p = configJson.toNativeUtf8();
    try {
      final res = _validate(p);
      return res.toDartString();
    } finally {
      calloc.free(p);
    }
  }
}
