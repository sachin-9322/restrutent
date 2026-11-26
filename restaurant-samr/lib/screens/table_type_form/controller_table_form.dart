import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/commons/my_snack_bar.dart';
import 'package:splash_screen_03/model/entity_room_type.dart';
import 'package:splash_screen_03/model/entity_table.dart';
import 'package:splash_screen_03/objectbox.g.dart';
import 'package:splash_screen_03/screens/home/fragments/table_type/controller_table.dart';


class ControllerTableForm extends GetxController {
  late TextEditingController textEditingControllerTableName;
  late TextEditingController textEditingControllerRoomUuid;

  var selectedRoomTypeName = "".obs; //IN the dropDown we are selecting roomTypeName and saving it into the selectRoomTypeName
  var selectedSeats = 0.obs;
  final formKey = GlobalKey<FormState>();

  Box<EntityRoomType> boxEntityRoom = Get.find();
  Box<EntityTable> boxEntityTable = Get.find();

  var rxRoomList = <EntityRoomType>[].obs;
  EntityTable? editTable;

  @override
  void onInit() {
    getRoom();
    textEditingControllerTableName = TextEditingController();
    textEditingControllerRoomUuid = TextEditingController();

    super.onInit();
  }

  void getRoom() {
    rxRoomList.value = boxEntityRoom.getAll();
  }

  void saveTableDetails() {
    String strTableName = textEditingControllerTableName.text.trim();
    String strRoomUuid = textEditingControllerRoomUuid.text.trim();

    if (strTableName.isEmpty) {
      MySnackBar.errorSnackBar("Error", "Enter the table name");
      return;
    }
    if (strRoomUuid.isEmpty) {
      MySnackBar.errorSnackBar("Error", "Enter the room type");
      return;
    }

    if (formKey.currentState!.validate()) {
      if (selectedRoomTypeName.value == "") {
        Get.snackbar("Error", "Please select Room Type");
        return;
      }

      if(editTable == null){
        final entity = EntityTable(
          roomType: selectedRoomTypeName.value,
          tableName: strTableName,
          seats: selectedSeats.value,
          roomUuid: strRoomUuid,
        );
        int id = boxEntityTable.put(entity);
        debugPrint("Inserted table id is:$id");
      }
      else{
        editTable!.roomType = selectedRoomTypeName.value;
        editTable!.tableName = strTableName;
        editTable!.seats = selectedSeats.value;
        editTable!.roomUuid = strRoomUuid;
        boxEntityTable.put(editTable!);
      }

      if (Get.isRegistered<ControllerTable>()) {
        Get.find<ControllerTable>().fetchTableDetails();
        Get.back();
      }
    }
  }

  void submit() {
    if (!formKey.currentState!.validate()) return;

    if (selectedRoomTypeName.value == "") {
      Get.snackbar("Error", "Please select Room Type");
      return;
    }

    // clear form
    textEditingControllerTableName.clear();
    selectedSeats.value = 0;

    Get.back();
  }
}
