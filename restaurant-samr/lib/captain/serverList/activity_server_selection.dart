import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controller_server_selection.dart';

class ActivityServerSelection extends StatelessWidget {
  final String username;
  final String password;

  ActivityServerSelection({Key? key, required this.username, required this.password}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Permanent controller to avoid disposal issues
    final controller = Get.put(
      ControllerServerSelection(username: username, password: password),
      permanent: true,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Select Server')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.serverList.isEmpty) {
          return const Center(
            child: Text('No servers found. Make sure the server is running.'),
          );
        }

        return ListView.builder(
          itemCount: controller.serverList.length,
          itemBuilder: (context, index) {
            final server = controller.serverList[index];

            return ListTile(
              title: Text(server),
              trailing: ElevatedButton(
                child: const Text('Connect'),
                onPressed: () async {
                  try {
                    // Connect and login to server
                    await controller.loginToServer(server);
                    // No need for extra snackbar here; handled inside controller
                  } catch (e) {
                    Get.snackbar('Error', 'Connection failed: $e');
                  }
                },
              ),
            );
          },
        );
      }),
    );
  }
}
