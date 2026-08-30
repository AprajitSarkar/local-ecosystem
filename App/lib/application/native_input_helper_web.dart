// lib/application/native_input_helper_web.dart
class NativeInputHelper {
  static void init() {}
  static void moveMouse(double dx, double dy) {}
  static void clickMouse({required String button, required bool isDown}) {}
  static void scrollMouse(int dy) {}
  static void keyEvent({required int keyCode, required bool isUp, bool isShift = false}) {}
  static void typeChar(String char) {}
}
