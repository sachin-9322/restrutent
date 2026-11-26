import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../repository/repo_captain.dart';
import 'controller_captain_home.dart';

class ActivityCaptainHomeMobile extends StatelessWidget {

  final String serverIp;
  final int serverPort;

  const ActivityCaptainHomeMobile({
    super.key,
    required this.serverIp,
    required this.serverPort,
  });

  @override
  Widget build(BuildContext context) {
    final ControllerCaptainHome controller = Get.put(
      ControllerCaptainHome(serverIp: serverIp, serverPort: serverPort),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text("Captain Dashboard"),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              child: Text(
                "Captain Menu",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  ...List.generate(
                    RepoCaptain.menuList.length,
                        (index) => buildMenuItem(index, controller, context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Obx(() {
        return RepoCaptain.screen[controller.selectedIndex.value];
      }),
    );
  }

  Widget buildMenuItem(int index, ControllerCaptainHome controller, BuildContext context) {
    return Obx(
          () => Card(
        color: controller.selectedIndex.value == index
            ? Colors.green
            : Colors.white,
        child: ListTile(
          leading: Icon(RepoCaptain.menuList[index].icon, color: Colors.black87),
          title: Text(
            RepoCaptain.menuList[index].title,
            style: TextStyle(color: Colors.black87),
          ),
          selected: controller.selectedIndex.value == index,
          selectedTileColor: Colors.orangeAccent[100],
          onTap: () {
            controller.changeScreen(index);
            Navigator.pop(context); // closes the drawer on mobile
          },
        ),
      ),
    );
  }
}