import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/model/entity_order_type.dart';
import 'package:splash_screen_03/objectbox.g.dart';

class ControllerSubOrder extends GetxController{
  Box<EntityOrderType>boxOrderType = Get.find();  //done
  var rxOrderList = <EntityOrderType>[].obs;

   EntityOrderType? editedOrderType;

  @override
  void onInit() {
    // TODO: implement onInit

    fetchDataFromSubOrder();
    super.onInit();
  }

  void fetchDataFromSubOrder(){
       rxOrderList.value = boxOrderType.getAll();
  }

  void removeOrderTypeAtIndex(int index){
     final orderType= rxOrderList[index];
    final id = boxOrderType.remove(orderType.id);
    debugPrint('Deleted Order Type index is: $id');
     fetchDataFromSubOrder();
  }

  void filterOrderTypes(String query){
    final results = boxOrderType
        .query(EntityOrderType_.name.contains(query, caseSensitive: false)).build()                                  //After defining the condition we write .build()
        .find();                                  //Execute the against database and return the list of matching EntityOrderType
    rxOrderList.value = results;
  }
}
