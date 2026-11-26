import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/commons/my_snack_bar.dart';
import 'package:splash_screen_03/screens/food_type_form/controller_food_form.dart';
import 'package:splash_screen_03/screens/home/fragments/table_type/controller_table.dart';
import '../../../model/entity_room_type.dart';
import '../../../objectbox.g.dart';
import '../home/fragments/room_type/controller_room.dart';

class ControllerRoomForm extends GetxController {
  late TextEditingController textEditingControllerName;

  late RxBool isActive = false.obs;
  final formKey = GlobalKey<FormState>();

  late Box<EntityRoomType> boxEntityRoomType = Get.find();
  EntityRoomType? editingRoom;

  @override
  void onInit() async {
    textEditingControllerName = TextEditingController();
    super.onInit();
  }

  void submit() {
    String strName = textEditingControllerName.text.trim();

    if (strName.isEmpty) {
      Get.snackbar("Error", "Enter the room type", backgroundColor: Colors.red);
      return;
    }

    if (formKey.currentState!.validate()) {
      //here we use try and on(catch) method because when user enter same room Uuid at that time exception is occurring to overcome this situation we use (UniqueViolationException)

      final duplicateNameExists = boxEntityRoomType
          .query(EntityRoomType_.name.equals(strName))
          .build()
          .find()
          .any((e) => e.id != (editingRoom?.id ?? 0));

      if (duplicateNameExists) {
        MySnackBar.errorSnackBar(
          "Duplicate name",
          "This room type is already exist ,please enter a diffrent one",
        );
        return;
      }

      if (editingRoom == null) {
        final entity = EntityRoomType(name: strName);

        int id = boxEntityRoomType.put(entity);
        debugPrint('Inserted room type with ID: $id');
      } else {
        editingRoom!.name = strName;
        boxEntityRoomType.put(editingRoom!);
        debugPrint("Updated room type with ID:${editingRoom!.id}");
      }

     // textEditingControllerName.clear();
      if (Get.isRegistered<ControllerRoom>()) //After entering the roomName,uid it will refresh the List of Room type
      {
        Get.find<ControllerRoom>().fetchRoomType();
      }
      if(Get.isRegistered<ControllerTable>()){
         Get.find<ControllerTable>().fetchRoomDetails();
      }
      if(Get.isRegistered<ControllerFoodForm>()){
         Get.find<ControllerFoodForm>().getRoomTypeList();
      }
      Get.back();
    }
  }
}
