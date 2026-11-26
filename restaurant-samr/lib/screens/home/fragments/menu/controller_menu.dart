import 'package:get/get.dart';
import 'package:objectbox/objectbox.dart';
import 'package:splash_screen_03/model/entity_menu.dart';

class ControllerMenu extends GetxController {
  late final Box<EntityMenu> boxMenu;

  // Observable list of menus
  var menuList = <EntityMenu>[].obs;

  @override
  void onInit() {
    super.onInit();
    boxMenu = Get.find<Box<EntityMenu>>();
    fetchMenus();
  }

  void fetchMenus() {
    menuList.value = boxMenu.getAll();
  }

  void addMenu(String name) {
    final menu = EntityMenu(name: name);
    boxMenu.put(menu);
    fetchMenus();
    Get.snackbar('Success', 'Menu added');
  }

  void updateMenu(EntityMenu menu, String newName) {
    menu.name = newName;
    boxMenu.put(menu);
    fetchMenus();
    Get.snackbar('Success', 'Menu updated');
  }

  void deleteMenu(EntityMenu menu) {
    boxMenu.remove(menu.id);
    fetchMenus();
    Get.snackbar('Success', 'Menu deleted');
  }
}
