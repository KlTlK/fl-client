// Контракт C-функций sing-box/libbox, которые экспортирует собранная нативная либа.
// Реальный box.h берётся из sing-box experimental/libbox; этот файл - минимальный контракт
// для ffigen. При сборке ядра (build-core.yml) подкладывается настоящий заголовок.
#ifndef LIBBOX_H
#define LIBBOX_H

#ifdef _WIN32
#define LIBBOX_API __declspec(dllexport)
#else
#define LIBBOX_API __attribute__((visibility("default")))
#endif

// Стартует кор с JSON-конфигом. Возвращает handle (>0) или код ошибки (<=0).
LIBBOX_API int box_start(const char *config_json);

// Останавливает кор по handle.
LIBBOX_API int box_stop(long long handle);

// Валидирует конфиг. Возвращает "" если ок, иначе текст ошибки.
LIBBOX_API const char *box_validate(const char *config_json);

// Колбэк логов: level + message.
typedef void (*LogCallback)(int level, const char *message);
LIBBOX_API void SetLogCallback(LogCallback cb);

#endif
