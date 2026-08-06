#include "win32_window.h"
#include <flutter_windows.h>
#include "resource.h"
namespace {
constexpr const wchar_t kWindowClassName[] = L"FLUTTER_RUNNER_WIN32_WINDOW";
int g_active_window_count = 0;
using EnableNonClientDpiScaling = BOOL __stdcall(HWND hwnd);
template <typename T> bool GetOptionalValue(HMODULE module, const char* name, T* value) { return false; }
}  // namespace
Win32Window::Win32Window() { ++g_active_window_count; }
Win32Window::~Win32Window() { --g_active_window_count; Destroy(); }
bool Win32Window::OnCreate() { return true; }
void Win32Window::OnDestroy() {}
LRESULT Win32Window::MessageHandler(HWND hwnd, UINT const message, WPARAM const wparam,
                                    LPARAM const lparam) noexcept {
  switch (message) {
    case WM_DESTROY:
      window_handle_ = nullptr; Destroy();
      if (quit_on_close_) PostQuitMessage(0);
      return 0;
    case WM_DPICHANGED: {
      auto newRectSize = reinterpret_cast<RECT*>(lparam);
      LONG newWidth = newRectSize->right - newRectSize->left;
      LONG newHeight = newRectSize->bottom - newRectSize->top;
      SetWindowPos(hwnd, nullptr, newRectSize->left, newRectSize->top, newWidth, newHeight,
                   SWP_NOZORDER | SWP_NOACTIVATE);
      return 0;
    }
    case WM_SIZE: {
      RECT rect = GetClientArea();
      if (child_content_ != nullptr)
        SetWindowPos(child_content_, nullptr, rect.left, rect.top,
                     rect.right - rect.left, rect.bottom - rect.top,
                     SWP_NOACTIVATE | SWP_NOZORDER);
      return 0;
    }
    case WM_GETMINMAXINFO: {
      auto info = reinterpret_cast<MINMAXINFO*>(lparam);
      info->ptMinTrackSize.x = 380; info->ptMinTrackSize.y = 600;
      return 0;
    }
  }
  return DefWindowProc(window_handle_, message, wparam, lparam);
}
bool Win32Window::CreateAndShow(const std::wstring& title, const Point& origin, const Size& size) {
  Destroy();
  WNDCLASS window_class{};
  window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
  window_class.lpszClassName = kWindowClassName;
  window_class.style = CS_HREDRAW | CS_VREDRAW;
  window_class.cbClsExtra = 0; window_class.cbWndExtra = 0;
  window_class.hInstance = GetModuleHandle(nullptr);
  window_class.hIcon = LoadIcon(window_class.hInstance, MAKEINTRESOURCE(IDI_APP_ICON));
  window_class.hbrBackground = 0;
  window_class.lpszMenuName = nullptr;
  window_class.lpfnWndProc = Win32Window::WndProc;
  RegisterClass(&window_class);
  window_handle_ = CreateWindow(kWindowClassName, title.c_str(), WS_OVERLAPPEDWINDOW | WS_VISIBLE,
                                Scale(origin.x, 1.0), Scale(origin.y, 1.0),
                                Scale(size.width, 1.0), Scale(size.height, 1.0),
                                nullptr, nullptr, GetModuleHandle(nullptr), this);
  if (!window_handle_) return false;
  return true;
}
void Win32Window::Destroy() {
  if (window_handle_) { DestroyWindow(window_handle_); window_handle_ = nullptr; }
  if (g_active_window_count == 0) UnregisterClass(kWindowClassName, nullptr);
}
void Win32Window::SetQuitOnClose(bool q) { quit_on_close_ = q; }
RECT Win32Window::GetClientArea() {
  RECT frame; GetClientRect(window_handle_, &frame); return frame;
}
HWND Win32Window::GetHandle() { return window_handle_; }
void Win32Window::SetChildContent(HWND content) {
  child_content_ = content;
  SetParent(content, window_handle_);
  RECT frame = GetClientArea();
  MoveWindow(content, frame.left, frame.top, frame.right - frame.left, frame.bottom - frame.top, true);
  SetFocus(child_content_);
}
LRESULT CALLBACK Win32Window::WndProc(HWND const window, UINT const message, WPARAM const wparam,
                                      LPARAM const lparam) noexcept {
  if (message == WM_NCCREATE) {
    auto cs = reinterpret_cast<CREATESTRUCT*>(lparam);
    SetWindowLongPtr(window, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(cs->lpCreateParams));
    auto that = static_cast<Win32Window*>(cs->lpCreateParams);
    that->window_handle_ = window;
  } else {
    Win32Window* that = GetThisFromHandle(window);
    if (that) return that->MessageHandler(window, message, wparam, lparam);
  }
  return DefWindowProc(window, message, wparam, lparam);
}
Win32Window* Win32Window::GetThisFromHandle(HWND const window) noexcept {
  return reinterpret_cast<Win32Window*>(GetWindowLongPtr(window, GWLP_USERDATA));
}
static int Scale(int value, double scale) { return static_cast<int>(value * scale); }
