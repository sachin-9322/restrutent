import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/screens/home/fragments/table_type/controller_table.dart';
import '../../../../model/entity_room_type.dart';
import '../../../../objectbox.g.dart';

class ControllerRoom extends GetxController {
  Box<EntityRoomType> boxEntityRoomType = Get.find();
  var rxRoomType = <EntityRoomType>[].obs;

  final formKey = GlobalKey<FormState>();
  late  TextEditingController nameController;

  RxString rxCallBack = "".obs;

  @override
  void onInit() {

    super.onInit();
nameController = TextEditingController();
    fetchRoomType();

  }

  @override
  void onClose() {
    // TODO: implement didispose
    nameController.dispose();
    super.onClose();
  }

  void fetchRoomType() {
    //Here we are fetching all values from database
    rxRoomType.value = boxEntityRoomType.getAll();
  }
void syncRoomTypeFromTableApi(String name) {
  final clean = name.trim();

  if (!boxEntityRoomType.getAll().any((r) => r.name == clean)) {
    boxEntityRoomType.put(EntityRoomType(name: clean, isActive: true));
    fetchRoomType();
  }
}
String getRoomNameByString(String name) {
  try {
    return rxRoomType.firstWhere(
      (rt) => (rt.name ?? '').trim().toLowerCase() == name.trim().toLowerCase()
    ).name!;
  } catch (e) {
    return name; // fallback
  }
}

void removeRoomType(int index) {
  final roomType = rxRoomType[index];
  boxEntityRoomType.remove(roomType.id);

  // Refresh this controller list
  fetchRoomType();

  // 🔥 Refresh table controller list ALSO
  if (Get.isRegistered<ControllerTable>()) {
    final tableCtrl = Get.find<ControllerTable>();
    tableCtrl.fetchRoomDetails();   // <--- IMPORTANT!
  }
}


  void filterRoomTypes(String query) {
    //This query is searching the Room Type 'name' in the database
    final results = boxEntityRoomType.query(EntityRoomType_.name.contains(query, caseSensitive: false))
        .build() //After defining the condition we write .build()
        .find(); //Execute the against database and return the list of matching EntityRoomType
    rxRoomType.value = results;
  }

  void isAvailableOrNot(EntityRoomType room) {
    room.isActive = !room.isActive!;
    boxEntityRoomType.put(room);
    fetchRoomType();
  }

  String getRoomTypeName(int id) {
    try {
      return rxRoomType.firstWhere((rt) => rt.id == id).name!;
    } catch (e) {
      return 'Unknown';
    }
  }
}
