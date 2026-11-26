import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/commons/my_snack_bar.dart';
import 'package:splash_screen_03/model/entity_cateogry_tax.dart';
import 'package:splash_screen_03/screens/food_type_form/controller_food_form.dart';
import 'package:splash_screen_03/screens/home/fragments/category_type/controller_category.dart';

import '../../../objectbox.g.dart';

class ControllerCategoryFrom extends GetxController {
  late TextEditingController textEditingControllerCategoryName;
  late TextEditingController textEditingControllerTexPercentage;

  var selectedCategory = 0.obs;
  var selectedRadioValueForExclusive = true.obs;
  final formKey = GlobalKey<FormState>();

  Box<EntityCategoryTax> boxEntityCategory = Get.find();
  EntityCategoryTax? editedCategory;
  //var isCheckedCgstSgst = false.obs;

  @override
  void onInit() {
    textEditingControllerCategoryName = TextEditingController();
   // textEditingControllerTexPercentage = TextEditingController();
    // TODO: implement onInit
    super.onInit();
  }

  void save() {
    String strName = textEditingControllerCategoryName.text.trim();
    //String tax = textEditingControllerTexPercentage.text.trim();
    //double categoryTax = double.parse(tax);

    if (strName.isEmpty) {
      MySnackBar.errorSnackBar("error", "Enter your category Type");
      return;
    }


    if (formKey.currentState!.validate()) {

      final duplicateCategory = boxEntityCategory.query(EntityCategoryTax_.categoryName.equals(strName)).build().find().any((e) => e.id != (editedCategory?.id ?? 0));
      if(duplicateCategory){
        MySnackBar.errorSnackBar("Duplicate Category","This category is already exist,please enter a diffrent one");
        return;
      }
      if (editedCategory == null) {
        final entity = EntityCategoryTax(
            categoryName: strName,
        );
        final id = boxEntityCategory.put(entity);
        debugPrint('Inserted id is:$id');
      } else {
        editedCategory!.categoryName = strName;
        boxEntityCategory.put(editedCategory!);
        debugPrint('Edited category type with Id: ${editedCategory!.id}');
      }

      if (Get.isRegistered<ControllerCategory>()) {
        Get.find<ControllerCategory>().fetchDataFromCategory(); //after saving category we call this method -> getCatogoryList()  becuase we have to show categories in FoodForm while selecting food item
      }
      if(Get.isRegistered<ControllerFoodForm>()){
         Get.find<ControllerFoodForm>().getCategoryList();
      }
      Get.back();
    }
  }
}
