import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/model/entity_tax.dart';
import 'package:objectbox/objectbox.dart'; // Import ObjectBox


class ControllerProductTax extends GetxController {
  var rxTaxList = <EntityTax>[].obs;
   Box<EntityTax> boxEntityTax = Get.find();

  @override
  void onInit() {
    super.onInit();
    fetchTax();
  }

  void fetchTax() {
       rxTaxList.value = boxEntityTax.getAll();
       debugPrint('Taxes Length is:${rxTaxList.length}');
    }

    void removeTaxType(int index){
       final entity = rxTaxList[index];
       boxEntityTax.remove(entity.id);
       fetchTax();
    }


}
