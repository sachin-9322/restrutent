import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/model/entity_tax.dart';

import '../../objectbox.g.dart';
import '../home/fragments/master_configure/tax_group/controller_tax_product.dart';

class ControllerTaxForm extends GetxController {
  final formKey = GlobalKey<FormState>();

  Box<EntityTax> boxEntityTax = Get.find();

  late TextEditingController textEditingControllerTaxName;
  late TextEditingController textEditingControllerTaxPercentage;

  var isSgstCgst = false.obs;
  var isActive = true.obs;
  var isHideTaxDetail = false.obs;
  var isIncludeInRate = false.obs;

  EntityTax? editTax;

  @override
  void onInit() {
    super.onInit();

    textEditingControllerTaxName = TextEditingController();
    textEditingControllerTaxPercentage = TextEditingController();
  }

  void saveTax() {
    if (formKey.currentState!.validate()) {
      String strName = textEditingControllerTaxName.text;
      String strPercentage = textEditingControllerTaxPercentage.text;
      double? percentage = double.tryParse(strPercentage);

      if (percentage == null) {
        Get.snackbar(
          "Validation Error",
          "Tax percentage must be a valid number.",
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (editTax == null) {
        final entity = EntityTax(
          taxProductName: strName,
          taxPercentage: percentage,
          //taxProductGroup: strProductGroup,
          //taxType: selectedTaxType.value,
          isHideTaxDetail: isHideTaxDetail.value,
          isSgstCgst: isSgstCgst.value,
          isActive: isActive.value,
          isIncludeInRate: isIncludeInRate.value
        );

        final entityId = boxEntityTax.put(entity);
        debugPrint('Inserted tax id is: $entityId');
      } else {
        editTax!.taxProductName = strName;
        editTax!.taxPercentage = percentage;
        //editTax!.taxType = strProductGroup;
        editTax!.isSgstCgst = isSgstCgst.value;
        editTax!.isActive = isActive.value;
        editTax!.isHideTaxDetail = isHideTaxDetail.value;
        editTax!.isIncludeInRate = isIncludeInRate.value;

        final updatedId = boxEntityTax.put(editTax!);
        debugPrint('Updated tax id is:$updatedId');
      }

      if (Get.isRegistered<ControllerProductTax>()) {
        Get.find<ControllerProductTax>().fetchTax();
        Get.back();
      }
    }

    textEditingControllerTaxName.clear();
    textEditingControllerTaxPercentage.clear();
    //selectedTaxType.value = 'Exclusive';
    isSgstCgst.value = false;
    isActive.value = true;
    isHideTaxDetail.value = false;
    isIncludeInRate.value = false;
  }
}
