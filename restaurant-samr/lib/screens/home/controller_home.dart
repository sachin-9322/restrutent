import 'dart:ui'; // For Rect
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

class ControllerHome extends GetxController with WindowListener {
  final selectedIndex = 0.obs;
  final isCollapsed = false.obs;
  final keyFocusNode = FocusNode();

  final isFullScreen = false.obs;

  // Save window state before full-screen
  Rect? _preFullScreenBounds;
  bool? _preWasMaximized;

  // Internal flags
  bool _toggleBusy = false;
  bool _shouldRestoreOnLeave = false;

  @override
  void onInit() {
    super.onInit();
    if (GetPlatform.isDesktop) {
      windowManager.addListener(this);
      _syncFullScreenState();
    }
  }

  @override
  void onReady() {
    super.onReady();
    // Ensure we capture keyboard shortcuts
    if (GetPlatform.isDesktop) {
      keyFocusNode.requestFocus();
    }
  }

  @override
  void onClose() {
    keyFocusNode.dispose();
    if (GetPlatform.isDesktop) {
      windowManager.removeListener(this);
    }
    super.onClose();
  }

  Future<void> _syncFullScreenState() async {
    if (!GetPlatform.isDesktop) return;
    isFullScreen.value = await windowManager.isFullScreen();
  }

  Future<void> toggleFullScreen() async {
    if (!GetPlatform.isDesktop || _toggleBusy) return;
    _toggleBusy = true;
    try {
      if (isFullScreen.value) {
        // EXIT full-screen: let the WindowListener event do the restore
        if (_preWasMaximized == true || _preFullScreenBounds != null) {
          _shouldRestoreOnLeave = true;
        }
        await windowManager.setFullScreen(false);
      } else {
        // ENTER full-screen: save current window state
        _preWasMaximized = await windowManager.isMaximized();
        if (_preWasMaximized == true) {
          // If maximized, we’ll just re-maximize on exit
          _preFullScreenBounds = null;
        } else {
          _preFullScreenBounds = await windowManager.getBounds();
        }
        await windowManager.setFullScreen(true);
      }
    } finally {
      _toggleBusy = false;
    }
  }

  void handleKey(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    final k = event.logicalKey;

    // ESC exits full-screen (and restores state)
    if (k == LogicalKeyboardKey.escape && isFullScreen.value) {
      toggleFullScreen();
      return;
    }

    // Toggle full-screen via common shortcuts
    final isAltEnter = (k == LogicalKeyboardKey.enter) && event.isAltPressed;
    final isMacToggle = GetPlatform.isMacOS &&
        k == LogicalKeyboardKey.keyF &&
        event.isMetaPressed &&
        event.isControlPressed;

    if (k == LogicalKeyboardKey.f11 || isAltEnter || isMacToggle) {
      toggleFullScreen();
    }
  }

  // WindowListener: keep reactive state and restore when exiting
  @override
  void onWindowEnterFullScreen() {
    isFullScreen.value = true;
  }

  @override
  void onWindowLeaveFullScreen() {
    isFullScreen.value = false;

    if (_shouldRestoreOnLeave) {
      _shouldRestoreOnLeave = false;

      // Restore previous window state after the OS exits full-screen
      Future.microtask(() async {
        try {
          if (_preWasMaximized == true) {
            await windowManager.maximize();
          } else if (_preFullScreenBounds != null) {
            await windowManager.setBounds(_preFullScreenBounds!);
          }
        } finally {
          _preFullScreenBounds = null;
          _preWasMaximized = null;
        }
      });
    }
  }

  // App UI helpers
  void changeScreen(int index) {
    selectedIndex.value = index;
  }

  void toggleCollapse() {
    isCollapsed.toggle();
  }
}