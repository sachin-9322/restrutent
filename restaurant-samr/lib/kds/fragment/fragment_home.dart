import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/commons/responsiveController/controller_responsive.dart';
import 'package:splash_screen_03/kds/fragment/controller_kds.dart';
import 'package:splash_screen_03/kds/fragment/kds_home.dart';
import 'package:splash_screen_03/services/controller_server.dart';

class ActivityKDSHome extends StatefulWidget {


  final String serverIp;
  final int serverPort;

  const ActivityKDSHome({
    super.key,
    required this.serverIp,
    required this.serverPort,
  });

  @override
  State<ActivityKDSHome> createState() => _ActivityKDSHomeState();
}
class _ActivityKDSHomeState extends State<ActivityKDSHome> {
  late final ControllerServer controllerServer;
  late final KOTController kotController;

  @override
  void initState() {
    super.initState();

    // Use existing instances, do NOT create new ones
    controllerServer = Get.find<ControllerServer>();
    kotController = Get.find<KOTController>();
  }

  @override
  Widget build(BuildContext context) {
    final ControllerResponsive responsiveController =
        Get.put(ControllerResponsive());

    responsiveController.updateScreenType();

    // ✅ Just return your KDS UI, no new controller creation
    return KdsHome();
  }
}
