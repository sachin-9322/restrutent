import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:objectbox/objectbox.dart';
import 'package:splash_screen_03/model/entity_user.dart';
import 'package:splash_screen_03/objectbox.g.dart';
import 'package:splash_screen_03/screens/home/fragments/users/controller_user.dart'; // adjust if needed

class ControllerUserForm extends GetxController {
  final formKey = GlobalKey<FormState>();

  // ADDED CONTROLLERS
  final textControllerRestaurantName = TextEditingController();
  final textControllerAddress = TextEditingController();

  final textControllerName = TextEditingController();
  final textControllerPassword = TextEditingController();
  final textControllerType = TextEditingController();
  final textControllerFirst = TextEditingController();
  final textControllerLast = TextEditingController();
  final textControllerCountryCode = TextEditingController();
  final textControllerMobile = TextEditingController();
  final textControllerDob = TextEditingController();
  final textControllerGender = TextEditingController();
  final textControllerIdProofKey = TextEditingController();
  final textControllerIdProofValue = TextEditingController();

  EntityUser? editingUser;

  late Box<EntityUser> userBox = Get.find(); // Get the box instance

  void submitUser() {
    if (formKey.currentState!.validate()) {
      final user = EntityUser(
        // ADDED VALUES
        restaurantName: textControllerRestaurantName.text,
        address: textControllerAddress.text,

        userName: textControllerName.text,
        userPassword: textControllerPassword.text,
        userType: textControllerType.text,
        first: textControllerFirst.text,
        last: textControllerLast.text,
        countryCode: textControllerCountryCode.text,
        mobile: textControllerMobile.text,
        dob: textControllerDob.text,
        gender: textControllerGender.text,
        idProofKey: textControllerIdProofKey.text,
        idProofValue: textControllerIdProofValue.text, backendUserId: 4
      );

      // MODIFIED: Simplified save/update logic
      if (editingUser != null) {
        user.userId = editingUser!.userId;
      }
      userBox.put(user);

      // MODIFIED: Simplified refresh and navigation logic
      if (Get.isRegistered<ControllerUser>()) {
        Get.find<ControllerUser>().fetchUsers();
      }

      // Clear all fields
      textControllerRestaurantName.clear();
      textControllerAddress.clear();
      textControllerName.clear();
      textControllerPassword.clear();
      textControllerType.clear();
      textControllerFirst.clear();
      textControllerLast.clear();
      textControllerCountryCode.clear();
      textControllerMobile.clear();
      textControllerDob.clear();
      textControllerGender.clear();
      textControllerIdProofKey.clear();
      textControllerIdProofValue.clear();

      Get.back(result: true); // Go back once after everything is done
    }
  }
}