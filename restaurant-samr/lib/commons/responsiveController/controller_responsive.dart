import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ControllerResponsive extends GetxController {
  final isMobile = false.obs;
  void updateScreenType() {
    var data = Get.width;
    debugPrint("data: $data");
    isMobile.value = Get.width < 600; // You can tweak this breakpoint
  }
}