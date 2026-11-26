import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MySnackBar {
    //MySnackBar.errorSnackBar('','');
    static void errorSnackBar(error , message)
    {
        Get.snackbar(error, message , backgroundColor: Colors.red , snackPosition: SnackPosition.TOP ,snackStyle: SnackStyle.FLOATING);
    }
    static void successSnackBar(error , message)
    {
        Get.snackbar(error, message, backgroundColor: Colors.grey , snackPosition: SnackPosition.BOTTOM);
    }
    static void warningSnackBar(error , message)
    {

        Get.snackbar(error, message , backgroundColor: Colors.yellowAccent , snackPosition: SnackPosition.BOTTOM,snackStyle: SnackStyle.GROUNDED);
    }

}
