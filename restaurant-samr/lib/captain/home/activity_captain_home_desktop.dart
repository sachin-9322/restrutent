import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../repository/repo_captain.dart';
import 'controller_captain_home.dart';

class ActivityCaptainHomeDesktop extends StatelessWidget {
  final String serverIp;
  final int serverPort;

  const ActivityCaptainHomeDesktop({
    super.key,
    required this.serverIp,
    required this.serverPort,
  });

  @override
  Widget build(BuildContext context) {
    // Pass arguments to controller
    final ControllerCaptainHome controller = Get.put(
      ControllerCaptainHome(serverIp: serverIp, serverPort: serverPort),
      permanent: true,
    );

    return DefaultTabController(
      length: RepoCaptain.menuList.length,
      child: Scaffold(
        body: Row(
          children: [
            // Left Menu
            Expanded(
              flex: 15,
              child: Container(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        "Captain Dashboard",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Expanded(
                      child: ListView(
                        children: [
                          ...List.generate(
                            RepoCaptain.menuList.length,
                                (index) => buildMenuItem(index, controller),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Right Screen
            Expanded(
              flex: 85,
              child: Obx(() {
                return RepoCaptain.screen[controller.selectedIndex.value];
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMenuItem(int index, ControllerCaptainHome controller) {
    final menuItem = RepoCaptain.menuList[index];

    return Obx(
          () => Card(
        color: controller.selectedIndex.value == index
            ? Colors.green
            : Colors.white,
        child: ListTile(
          leading: Icon(menuItem.icon, color: Colors.black87),
          title: Text(
            menuItem.title,
            style: TextStyle(color: Colors.black87),
          ),
          selected: controller.selectedIndex.value == index,
          selectedTileColor: Colors.orangeAccent[100],
          onTap: () async {
            if (menuItem.title.toLowerCase() == "pull data") {
              // Directly fetch now
              await controller.fetchRoomTypesFromServer();
              await controller.fetchTablesFromServer();
              await controller.fetchCategoryTaxesFromServer();
              await controller.fetchFoodFromServer();
              debugPrint("Data pulled successfully");
            } else {
              controller.changeScreen(index);
            }
          },

        ),
      ),
    );
  }
}