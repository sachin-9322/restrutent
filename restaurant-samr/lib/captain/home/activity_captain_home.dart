import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/captain/home/fragment_cap_table.dart';
import 'package:splash_screen_03/captain/home/fragment_profile.dart';
import 'package:splash_screen_03/captain/pull/controller_captain_pull.dart';
import 'package:splash_screen_03/commons/responsiveController/controller_responsive.dart';
import 'package:splash_screen_03/services/controller_server.dart';

class ActivityCaptainHome extends StatefulWidget {
  final String serverIp;
  final int serverPort;

  const ActivityCaptainHome({
    super.key,
    required this.serverIp,
    required this.serverPort,
  });

  @override
  State<ActivityCaptainHome> createState() => _ActivityCaptainHomeState();
}
class _ActivityCaptainHomeState extends State<ActivityCaptainHome> {
  late final ControllerCaptainPull pullController;

  @override
  void initState() {
    super.initState();

    pullController = Get.put(
      ControllerCaptainPull(
        serverIp: widget.serverIp,
        serverPort: widget.serverPort,
      ),
      permanent: true,
    );

    // ✅ Delay the worker registration until the widget tree is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ever<List<String>>(pullController.kotStatusList, (list) {
        if (list.isNotEmpty) {
          final latest = list.last;

          debugPrint("🔔 Showing snackbar for: $latest");

          Get.snackbar(
            "KOT Status Update",
            latest,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.black87,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
            icon: const Icon(Icons.receipt_long, color: Colors.white),
            margin: const EdgeInsets.all(10),
            borderRadius: 10,
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final ControllerResponsive responsiveController =
        Get.put(ControllerResponsive(), permanent: true);
    final ControllerServer controllerServer =
        Get.put(ControllerServer(), permanent: true);

    responsiveController.updateScreenType();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF005D6A),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Captain Home", style: TextStyle(color: Colors.white,fontSize: 14, fontWeight: FontWeight.w500),),
            Obx(() {
              final list = pullController.kotStatusList;
              if (list.isEmpty) return const SizedBox.shrink();

              final latest = list.last;
              return Text(
                latest,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.yellowAccent,
                ),
              );
            }),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.white,),
            tooltip: "Pull Data",
            onPressed: () async {
              await pullController.manualRefresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white,),
            onPressed: () async {
              Navigator.push(context, MaterialPageRoute(builder: (context)=> const ActivityProfile()));
            },
          ),
       
        ],
      ),
      body: const FragmentCapTableOrder(),
    );
  }
}