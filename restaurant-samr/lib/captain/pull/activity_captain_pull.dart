// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'controller_captain_pull.dart';

// class ActivityCaptainPull extends StatelessWidget {
//   final String serverIp;
//   final int serverPort;

//   const ActivityCaptainPull({Key? key, required this.serverIp, required this.serverPort}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.put(ControllerCaptainPull(serverIp: serverIp, serverPort: serverPort));

//     return Scaffold(
//       appBar: AppBar(title: const Text("Pulling Data...")),
//       body: Center(
//         child: Obx(() => controller.isLoading.value
//             ? const CircularProgressIndicator()
//             : const Text("Data pulled successfully ✅")),
//       ),
//     );
//   }
// }