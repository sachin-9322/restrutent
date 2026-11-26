import 'package:get/get.dart';

import 'controller_responsive.dart';

class BindingResponsive extends Bindings {
  @override
  void dependencies() {
    Get.put(ControllerResponsive(), permanent: true);
  }
}
