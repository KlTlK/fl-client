#include "utils.h"
#include <flutter_windows.h>
#include <io.h>
#include <stdio.h>
#include <windows.h>
#include <iostream>
void CreateAndAttachConsole() {
  if (::AllocConsole()) {
    FILE *unused;
    if (freopen_s(&unused, "CONOUT$", "w", stdout)) {}
    setvbuf(stdout, nullptr, _IONBF, 0);
  }
}
std::vector<std::string> GetCommandLineArguments() {
  int argc;
  wchar_t** argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);
  if (argv == nullptr) return std::vector<std::string>();
  std::vector<std::string> command_line_arguments;
  for (int i = 1; i < argc; i++) {
    int utf16_length = lstrlenW(argv[i]);
    int utf8_length = WideCharToMultiByte(CP_UTF8, 0, argv[i], utf16_length, nullptr, 0, nullptr, nullptr);
    std::string s(utf8_length, 0);
    WideCharToMultiByte(CP_UTF8, 0, argv[i], utf16_length, s.data(), utf8_length, nullptr, nullptr);
    command_line_arguments.push_back(s);
  }
  LocalFree(argv);
  return command_line_arguments;
}
