// lib/services/startup/resume_session_page.dart
import 'dart:async'; // ADD THIS
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:splash_screen_03/captain/serverList/controller_server_selection.dart';
import 'package:splash_screen_03/utils/app_routes.dart';

class ResumeSessionPage extends StatefulWidget {
  const ResumeSessionPage({Key? key}) : super(key: key);

  @override
  State<ResumeSessionPage> createState() => _ResumeSessionPageState();
}

class _ResumeSessionPageState extends State<ResumeSessionPage> {
  Timer? _guard;

  @override
  void initState() {
    super.initState();

    // Hard guard: never get stuck here
    _guard = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        debugPrint('[ResumeSession] Guard timeout -> Login');
        Get.offAllNamed(AppRoutes.login);
      }
    });

    _resume();
  }

  Future<void> _resume() async {
    final s = GetStorage();
    final server = (s.read('serverIpPort') ?? '').toString();
    final user = (s.read('username') ?? '').toString();
    final pass = (s.read('password') ?? '').toString();

    if (server.isEmpty || user.isEmpty || pass.isEmpty) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    // Fresh controller with saved creds
    if (Get.isRegistered<ControllerServerSelection>()) {
      Get.delete<ControllerServerSelection>(force: true);
    }
    final css = Get.put(
      ControllerServerSelection(username: user, password: pass),
      permanent: true,
    );

    final ok = await css.loginToServer(server);
    if (!ok && mounted) {
      // Couldn’t connect or login – go to Login
      _guard?.cancel();
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    // On success, ControllerServerSelection will navigate.
    // When it navigates away, this widget is disposed, and the guard timer is canceled in dispose().
  }

  @override
  void dispose() {
    _guard?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}