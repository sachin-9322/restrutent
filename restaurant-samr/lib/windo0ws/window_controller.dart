// // lib/utils/window/window_controller.dart
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:window_manager/window_manager.dart';

// class WindowController extends GetxController with WindowListener {
//   // Hide from Windows taskbar while in fullscreen (prevents taskbar peeking)
//   final bool hideFromTaskbarWhileFullscreen;

//   WindowController({this.hideFromTaskbarWhileFullscreen = true});

//   final RxBool isFullScreen = false.obs;
//   final RxBool isMaximized = false.obs;

//   bool get _isDesktop =>
//       GetPlatform.isWindows || GetPlatform.isLinux || GetPlatform.isMacOS || GetPlatform.isDesktop;

//   @override
//   void onInit() {
//     super.onInit();
//     if (_isDesktop) {
//       windowManager.addListener(this);
//       _syncState();
//     }
//   }

//   @override
//   void onClose() {
//     if (_isDesktop) {
//       windowManager.removeListener(this);
//     }
//     super.onClose();
//   }

//   Future<void> _syncState() async {
//     try {
//       isFullScreen.value = await windowManager.isFullScreen();
//     } catch (_) {
//       isFullScreen.value = false;
//     }
//     isMaximized.value = await windowManager.isMaximized();
//   }

//   // Keyboard shortcuts
//   void handleKey(RawKeyEvent event) {
//     if (event is! RawKeyDownEvent) return;

//     final key = event.logicalKey;
//     final isAlt = HardwareKeyboard.instance.isAltPressed;
//     final isCtrl = HardwareKeyboard.instance.isControlPressed;
//     final isMeta = HardwareKeyboard.instance.isMetaPressed; // Command on macOS

//     if (key == LogicalKeyboardKey.f11 ||
//         (key == LogicalKeyboardKey.enter && isAlt) ||
//         (key == LogicalKeyboardKey.keyF && isMeta && isCtrl)) {
//       toggleFullScreen();
//     }
//   }

//   Future<void> toggleFullScreen() async {
//     if (!_isDesktop) return;

//     try {
//       final full = await windowManager.isFullScreen();
//       if (!full) {
//         await windowManager.setFullScreen(true);
//         if (GetPlatform.isWindows) {
//           await windowManager.setAlwaysOnTop(true);
//           if (hideFromTaskbarWhileFullscreen) {
//             await windowManager.setSkipTaskbar(true);
//           }
//         }
//       } else {
//         if (GetPlatform.isWindows) {
//           if (hideFromTaskbarWhileFullscreen) {
//             await windowManager.setSkipTaskbar(false);
//           }
//           await windowManager.setAlwaysOnTop(false);
//         }
//         await windowManager.setFullScreen(false);
//       }
//     } catch (_) {
//       // Fallback: use maximize/unmaximize
//       if (await windowManager.isMaximized()) {
//         await windowManager.unmaximize();
//       } else {
//         await windowManager.maximize();
//       }
//     }
//   }

//   // Window events
//   @override
//   void onWindowEnterFullScreen() {
//     isFullScreen.value = true;
//     if (GetPlatform.isWindows) {
//       windowManager.setAlwaysOnTop(true);
//       if (hideFromTaskbarWhileFullscreen) {
//         windowManager.setSkipTaskbar(true);
//       }
//     }
//   }

//   @override
//   void onWindowLeaveFullScreen() {
//     isFullScreen.value = false;
//     if (GetPlatform.isWindows) {
//       if (hideFromTaskbarWhileFullscreen) {
//         windowManager.setSkipTaskbar(false);
//       }
//       windowManager.setAlwaysOnTop(false);
//     }
//   }

//   @override
//   void onWindowMaximize() => isMaximized.value = true;
//   @override
//   void onWindowUnmaximize() => isMaximized.value = false;
// }