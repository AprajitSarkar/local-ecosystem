// lib/application/native_input_helper_native.dart
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

const int MOUSEEVENTF_MOVE = 0x0001;
const int MOUSEEVENTF_LEFTDOWN = 0x0002;
const int MOUSEEVENTF_LEFTUP = 0x0004;
const int MOUSEEVENTF_RIGHTDOWN = 0x0008;
const int MOUSEEVENTF_RIGHTUP = 0x0010;
const int MOUSEEVENTF_MIDDLEDOWN = 0x0020;
const int MOUSEEVENTF_MIDDLEUP = 0x0040;
const int MOUSEEVENTF_WHEEL = 0x0800;

const int KEYEVENTF_KEYUP = 0x0002;
const int VK_BACK = 0x08;
const int VK_TAB = 0x09;
const int VK_RETURN = 0x0D;
const int VK_SHIFT = 0x10;
const int VK_ESCAPE = 0x1B;
const int VK_SPACE = 0x20;

final class POINT extends Struct {
  @Int32()
  external int x;
  @Int32()
  external int y;
}

typedef SetCursorPosNative = Int32 Function(Int32, Int32);
typedef SetCursorPosDart = int Function(int, int);

typedef GetCursorPosNative = Int32 Function(Pointer<POINT>);
typedef GetCursorPosDart = int Function(Pointer<POINT>);

typedef MouseEventNative = Void Function(Uint32, Uint32, Uint32, Uint32, IntPtr);
typedef MouseEventDart = void Function(int, int, int, int, int);

typedef KeybdEventNative = Void Function(Uint8, Uint8, Uint32, IntPtr);
typedef KeybdEventDart = void Function(int, int, int, int);

typedef VkKeyScanWNative = Int16 Function(Uint16);
typedef VkKeyScanWDart = int Function(int);

class NativeInputHelper {
  static SetCursorPosDart? _setCursorPos;
  static GetCursorPosDart? _getCursorPos;
  static MouseEventDart? _mouseEvent;
  static KeybdEventDart? _keybdEvent;
  static VkKeyScanWDart? _vkKeyScanW;
  static bool _initialized = false;

  static void init() {
    if (_initialized || !Platform.isWindows) return;
    _initialized = true;
    try {
      final user32 = DynamicLibrary.open('user32.dll');
      _setCursorPos = user32.lookupFunction<SetCursorPosNative, SetCursorPosDart>('SetCursorPos');
      _getCursorPos = user32.lookupFunction<GetCursorPosNative, GetCursorPosDart>('GetCursorPos');
      _mouseEvent = user32.lookupFunction<MouseEventNative, MouseEventDart>('mouse_event');
      _keybdEvent = user32.lookupFunction<KeybdEventNative, KeybdEventDart>('keybd_event');
      _vkKeyScanW = user32.lookupFunction<VkKeyScanWNative, VkKeyScanWDart>('VkKeyScanW');
    } catch (_) {}
  }

  static void moveMouse(double dx, double dy) {
    if (!Platform.isWindows || _getCursorPos == null || _setCursorPos == null) return;
    final point = calloc<POINT>();
    try {
      if (_getCursorPos!(point) != 0) {
        final newX = (point.ref.x + dx).round();
        final newY = (point.ref.y + dy).round();
        _setCursorPos!(newX, newY);
      }
    } catch (_) {
    } finally {
      calloc.free(point);
    }
  }

  static void clickMouse({required String button, required bool isDown}) {
    if (!Platform.isWindows || _mouseEvent == null) return;
    try {
      switch (button) {
        case 'left':
          _mouseEvent!(isDown ? MOUSEEVENTF_LEFTDOWN : MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
          break;
        case 'right':
          _mouseEvent!(isDown ? MOUSEEVENTF_RIGHTDOWN : MOUSEEVENTF_RIGHTUP, 0, 0, 0, 0);
          break;
        case 'middle':
          _mouseEvent!(isDown ? MOUSEEVENTF_MIDDLEDOWN : MOUSEEVENTF_MIDDLEUP, 0, 0, 0, 0);
          break;
        case 'double':
          _mouseEvent!(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0);
          _mouseEvent!(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
          _mouseEvent!(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0);
          _mouseEvent!(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
          break;
      }
    } catch (_) {}
  }

  static void scrollMouse(int dy) {
    if (!Platform.isWindows || _mouseEvent == null) return;
    try {
      _mouseEvent!(MOUSEEVENTF_WHEEL, 0, 0, dy, 0);
    } catch (_) {}
  }

  static void keyEvent({required int keyCode, required bool isUp, bool isShift = false}) {
    if (!Platform.isWindows || _keybdEvent == null) return;
    try {
      final flags = isUp ? KEYEVENTF_KEYUP : 0;
      if (isShift) _keybdEvent!(VK_SHIFT, 0, isUp ? KEYEVENTF_KEYUP : 0, 0);
      _keybdEvent!(keyCode, 0, flags, 0);
    } catch (_) {}
  }

  static void typeChar(String char) {
    if (!Platform.isWindows || _keybdEvent == null) return;
    try {
      if (char == '\n') {
        _keybdEvent!(VK_RETURN, 0, 0, 0);
        _keybdEvent!(VK_RETURN, 0, KEYEVENTF_KEYUP, 0);
      } else if (char == ' ') {
        _keybdEvent!(VK_SPACE, 0, 0, 0);
        _keybdEvent!(VK_SPACE, 0, KEYEVENTF_KEYUP, 0);
      } else if (_vkKeyScanW != null) {
        final rune = char.runes.first;
        final vk = _vkKeyScanW!(rune);
        final keycode = vk & 0xFF;
        final shift = (vk >> 8) & 1;
        if (shift != 0) _keybdEvent!(VK_SHIFT, 0, 0, 0);
        _keybdEvent!(keycode, 0, 0, 0);
        _keybdEvent!(keycode, 0, KEYEVENTF_KEYUP, 0);
        if (shift != 0) _keybdEvent!(VK_SHIFT, 0, KEYEVENTF_KEYUP, 0);
      }
    } catch (_) {}
  }
}
