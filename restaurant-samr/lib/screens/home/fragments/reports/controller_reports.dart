import 'package:get/get.dart';

class ControllerReports extends GetxController {

  var selectedIndex = 0.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
  }

  void changeScreen(int index) {
     selectedIndex.value = index;
  }
}
  class ModelMenuReports{
      String title;

      ModelMenuReports({required this.title});
  }



