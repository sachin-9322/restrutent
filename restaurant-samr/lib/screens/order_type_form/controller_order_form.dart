import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/commons/my_snack_bar.dart';
import 'package:splash_screen_03/model/entity_order_type.dart';
import 'package:splash_screen_03/screens/home/fragments/sub_order_type/controller_sub_order.dart';

import '../../../objectbox.g.dart';

class ControllerOrderForm extends GetxController {
  Box<EntityOrderType> boxOrderType = Get.find();
  final formKey = GlobalKey<FormState>();
  EntityOrderType? editingOrderType;

  late TextEditingController textEditingControllerOrderName;
  @override
  void onInit() {
    textEditingControllerOrderName = TextEditingController();
    super.onInit();
  }

  void save() {
    String strName = textEditingControllerOrderName.text.trim();

    if (strName.isEmpty) {
      MySnackBar.errorSnackBar("Error", "Enter the Order Type");
      return;
    }

    if (formKey.currentState!.validate()) {
      final isDuplicateOrderType = boxOrderType
          .query(EntityOrderType_.name.equals(strName))
          .build()
          .find()
          .any((entity) => entity.id != (editingOrderType?.id ?? 0));

      if (isDuplicateOrderType) {
        MySnackBar.errorSnackBar(
          "Duplicate Order Type",
          "The $strName is already exist",
        );
        return;
      }
      if (editingOrderType == null) {
        final entity = EntityOrderType(name: strName);
        int id = boxOrderType.put(entity);

        debugPrint('Insert id is:$id');
      } else {
        editingOrderType!.name = strName;
        int id = boxOrderType.put(editingOrderType!);
        debugPrint('Updated Order Type inserted at index is:$id');
      }

      if (Get.isRegistered<ControllerSubOrder>()) //After entering the roomName,uid it will refresh the List of Room type
      {
        Get.find<ControllerSubOrder>().fetchDataFromSubOrder(); //refreshing data from database
        Get.back();
      }
    }
  }
}
