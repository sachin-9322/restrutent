// lib/screens/login/activity_login.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/captain/serverList/server_discover.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/printerquick_connect.dart';
import 'package:splash_screen_03/screens/home/fragments/table_order/widget/glass_card.dart';
import 'package:splash_screen_03/screens/user_form/activity_user_form.dart';
import 'controller_login.dart';

class ActivityLogin extends StatelessWidget {
  ActivityLogin({super.key});

  final ControllerLogin controller = Get.put(ControllerLogin());

  @override
  Widget build(BuildContext context) {
    final serverPicker = Get.put(ServerDiscoveryController(), permanent: true);

    return Scaffold(
      body: Stack(
        children: [
          // 🌈 Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF004D40),
                  Color(0xFF00796B),
                ],
              ),
            ),
          ),

          // 🧊 Glass Login Card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: GlasssCard(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(32),
                  child: Obx(
                    () => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SvgPicture.asset(
                          'assets/logo/logo.svg',
                          height: 32,
                          semanticsLabel: 'RH POS Logo',
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Welcome Back',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Sign in to continue',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                        const SizedBox(height: 30),

                        // 🔌 Server Selector
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: serverPicker.selectedServer.value.isEmpty
                                    ? null
                                    : serverPicker.selectedServer.value,
                                items: serverPicker.servers
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(
                                          s,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null && v.isNotEmpty) {
                                    serverPicker.manualSelect(v);
                                  } else {
                                    serverPicker.selectedServer.value = '';
                                  }
                                },
                                style: const TextStyle(color: Colors.white),
                                dropdownColor: Colors.black87,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.1),
                                  labelText: 'Server',
                                  labelStyle:
                                      const TextStyle(color: Colors.white70),
                                  prefixIcon: const Icon(
                                    Icons.dns_outlined,
                                    color: Colors.white70,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Colors.tealAccent,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: serverPicker.isDiscovering.value
                                  ? null
                                  : serverPicker.discover,
                              tooltip: 'Refresh servers',
                              icon: serverPicker.isDiscovering.value
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white70,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.refresh,
                                      color: Colors.white70,
                                    ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // 👤 Username
                        TextField(
                          onChanged: (value) =>
                              controller.username.value = value,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            labelText: 'Username',
                            labelStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              color: Colors.white70,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.tealAccent,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 🔒 Password
                        TextField(
                          onChanged: (value) =>
                              controller.password.value = value,
                          style: const TextStyle(color: Colors.white),
                          obscureText: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            labelText: 'Password',
                            labelStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: Colors.white70,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.tealAccent,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 🚪 Login Button
                        controller.isLoading.value
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white70,
                                ),
                              )
                            : ElevatedButton(
                                onPressed: () => controller.login(
                                  selectedServer:
                                      serverPicker.selectedServer.value,
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: Colors.tealAccent.shade700,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                        const SizedBox(height: 20),

                        // // 🧍 Register Link
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.center,
                        //   children: [
                        //     const Text(
                        //       "Don't have an account?",
                        //       style: TextStyle(color: Colors.white70),
                        //     ),
                        //     TextButton(
                        //       onPressed: () => Get.to(() => ActivityUserForm()),
                        //       child: const Text(
                        //         'Register',
                        //         style: TextStyle(
                        //           color: Colors.tealAccent,
                        //           fontWeight: FontWeight.bold,
                        //         ),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
