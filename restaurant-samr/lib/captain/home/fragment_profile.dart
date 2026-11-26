import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/captain/login/auth_service.dart';
import 'package:splash_screen_03/model/entity_user.dart';

class ActivityProfile extends StatelessWidget {
  const ActivityProfile({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the single instance of our AuthService
    final authService = Get.find<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        // Use Obx to make the UI reactive to changes in authService.currentUser
        child: Obx(() {
          // Get the user object directly from the service.
          final EntityUser? user = authService.currentUser.value;

          if (user == null) {
            authService.fetchUserProfile();
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // --- User Summary Card ---
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.teal.shade100,
                        child: Text(
                          (user.userName?.isNotEmpty == true)
                              ? user.userName![0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.userName ?? 'Unknown User',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user.userType ?? 'Role: Unknown',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            if (user.restaurantName != null)
                              Text(
                                user.restaurantName!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(
                          Icons.logout_outlined,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () {
                          // Call the central logout method
                          authService.logout();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // --- Additional Details Card ---
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.phone, color: Colors.teal),
                        title: const Text("Mobile"),
                        subtitle: Text(user.mobile ?? "Not Available"),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(
                          Icons.location_on,
                          color: Colors.teal,
                        ),
                        title: const Text("Address"),
                        subtitle: Text(user.address ?? "Not Available"),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
