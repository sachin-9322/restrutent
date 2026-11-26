// controller_food_form.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:splash_screen_03/commons/my_snack_bar.dart';
import 'package:splash_screen_03/model/entity_cateogry_tax.dart';
import 'package:splash_screen_03/model/entity_food.dart';
import 'package:splash_screen_03/model/entity_price.dart';
import 'package:splash_screen_03/model/entity_room_type.dart';
import 'package:splash_screen_03/screens/home/fragments/order/controller_order.dart';
import 'package:splash_screen_03/screens/home/fragments/food_type/controller_food.dart';
import 'package:splash_screen_03/screens/home/fragments/menu/controller_menu.dart';
import 'package:splash_screen_03/utils/sanbar.dart';
import '../../model/entity_kitchen_department.dart';
import '../../model/entity_tax.dart';
import '../../objectbox.g.dart';

class ControllerFoodForm extends GetxController {
  // Boxes
  Box<EntityFood> boxEntityFood = Get.find();
  Box<EntityCategoryTax> boxEntityCategory = Get.find();
  Box<EntityRoomType> boxEntityRoom = Get.find();
  Box<EntityKitchenDepartment> boxKitchenDepartment = Get.find();

  // Rx
  var rxRoomList = <EntityRoomType>[].obs;
  var selectedRoomTypeName = "".obs;

  var rxCategoryList = <EntityCategoryTax>[].obs;
  var selectIsVeg = true.obs;
  var selectedCategoryId = 0.obs;
  var selectedMeatType = Rx<String?>(null);

  var rxPriceList = <EntityPrice>[].obs;
  EntityFood? editingFood;

  // Windows-only image state
  final Rx<String?> rxBase64Image = Rx<String?>(null);
  final Rx<String?> rxImageFileName = Rx<String?>(null);

  // Controllers
  late TextEditingController textEditingControllerFoodName;
  late TextEditingController textEditingControllerFoodCategory;
  late TextEditingController textEditingControllerFoodShortCode;
  late TextEditingController textEditingControllerFoodDescription;
  late TextEditingController textEditingControllerPrepTime;
  late TextEditingController textEditingControllerHSNCode;
  late TextEditingController textEditingControllerStock;
  late TextEditingController textEditingControllerKitchenDepName;

  // Form
  final formKey = GlobalKey<FormState>();

  // Menu
  var selectedMenuId = 0.obs;
  var selectedFoodType = ''.obs;

  // Tax + UI
  var currentTaxUuid = Rx<String?>(null);
  var foodNameForTaxCard = "".obs;

  // store listener reference so we can remove it
  late final VoidCallback _nameListener;

  @override
  void onInit() {
    super.onInit();

    // Init controllers
    textEditingControllerFoodName = TextEditingController();
    textEditingControllerFoodCategory = TextEditingController();
    textEditingControllerFoodShortCode = TextEditingController();
    textEditingControllerFoodDescription = TextEditingController();
    textEditingControllerPrepTime = TextEditingController();
    textEditingControllerHSNCode = TextEditingController();
    textEditingControllerStock = TextEditingController();
    textEditingControllerKitchenDepName = TextEditingController();

    // *** LIVE NAME UPDATE LOGIC ***
    // This listener is key. It updates the 'foodNameForTaxCard' variable
    // in real-time whenever the user types in the food name text field.
    // The UI (specifically the tax card) listens to this variable to stay updated.
    _nameListener = () =>
        foodNameForTaxCard.value = textEditingControllerFoodName.text;
    textEditingControllerFoodName.addListener(_nameListener);

    // Load edit args
    final EntityFood? args = Get.arguments as EntityFood?;
    if (args != null) {
      editingFood = args;

      textEditingControllerFoodName.text = editingFood!.foodName ?? "";
      // Pre-fill the name for the tax card when editing an existing item.
      foodNameForTaxCard.value = editingFood!.foodName ?? "";

      textEditingControllerFoodShortCode.text = editingFood!.shortCode ?? "";
      textEditingControllerFoodCategory.text = editingFood!.categoryName ?? "";
      selectIsVeg.value = editingFood!.isVeg ?? true;
      textEditingControllerFoodDescription.text =
          editingFood!.foodDescription ?? "";
      textEditingControllerPrepTime.text =
          editingFood!.prepTime?.toString() ?? "";
      textEditingControllerHSNCode.text = editingFood!.hsnCode ?? "";
      textEditingControllerStock.text = (editingFood!.stock ?? 0).toString();

      if (editingFood!.kitchen.target != null) {
        textEditingControllerKitchenDepName.text =
            editingFood!.kitchen.target!.name ?? "";
      }
      rxPriceList.assignAll(editingFood!.price.toList());
      currentTaxUuid.value = editingFood!.tax.target?.taxUuid;

      // Preload existing Base64 image (images[0] or imgPath)
      final imgs = editingFood!.images;
      if (imgs != null && imgs.isNotEmpty && (imgs.first).isNotEmpty) {
        rxBase64Image.value = imgs.first;
      } else if ((editingFood!.imgPath ?? '').isNotEmpty) {
        final maybe = editingFood!.imgPath!;
        // simple heuristic to check base64 string
        final looksLikeBase64 =
            RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(maybe) && maybe.length > 100;
        if (looksLikeBase64) rxBase64Image.value = maybe;
      }
    } else {
      currentTaxUuid.value = null;
      // For a new item, the tax card name starts empty. It will be updated by the listener.
      foodNameForTaxCard.value = "";
    }

    getCategoryList();
    getRoomTypeList();
  }

  void getCategoryList() {
    rxCategoryList.value = boxEntityCategory.getAll();
    if (editingFood != null && (editingFood!.categoryName ?? '').isNotEmpty) {
      final existingCategory = rxCategoryList.firstWhereOrNull(
        (cat) => cat.categoryName == editingFood!.categoryName,
      );
      if (existingCategory != null)
        selectedCategoryId.value = existingCategory.id;
    }
  }

  void getRoomTypeList() {
    rxRoomList.value = boxEntityRoom.getAll();
  }

  void addPriceToTempList(EntityPrice price) => rxPriceList.add(price);
  void removePriceFromTempList(EntityPrice price) => rxPriceList.remove(price);

  void updatePriceInTempList(int index, EntityPrice price) {
    if (index >= 0 && index < rxPriceList.length) {
      rxPriceList[index] = price;
    }
  }

  Future<void> pickImageForWindows(BuildContext context) async {
    if (!GetPlatform.isWindows) {
      showMiniSnack(
        context,
        "Unsupported",
        "Image picker is available only on Windows.",
        type: MiniSnackType.info,
        maxWidth: 320,
        bottomGap: 18,
      );
      return;
    }
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
        allowMultiple: false,
        withData: true,
      );
      if (result == null) return;

      final file = result.files.single;
      Uint8List? bytes = file.bytes; // Use a variable that can be reassigned

      if (bytes == null) {
        showMiniSnack(
          context,
          "Error",
          "Could not read selected file.",
          type: MiniSnackType.error,
          maxWidth: 320,
          bottomGap: 18,
        );
        return;
      }

      // ===================================================================
      // <<< COMPRESSION LOGIC >>>
      // ===================================================================
      const int compressionThreshold = 1024 * 1024; // 1 MB
      const int maxFileSize = 7 * 1024 * 1024; // 7 MB

      if (bytes.length > compressionThreshold) {
        final originalImage = img.decodeImage(bytes);
        if (originalImage != null) {
          img.Image resizedImage;
          if (originalImage.width > 1200) {
            resizedImage = img.copyResize(originalImage, width: 1200);
          } else {
            resizedImage = originalImage;
          }
          bytes = img.encodeJpg(resizedImage, quality: 85);
        }
      }

      if (bytes.length > maxFileSize) {
        showMiniSnack(
          context,
          "Too large",
          "Even after compression, the image is over 7 MB. Please choose a smaller one.",
          type: MiniSnackType.info,
          maxWidth: 320,
          bottomGap: 18,
        );
        return;
      }
      // ===================================================================

      rxBase64Image.value = base64Encode(bytes);
      rxImageFileName.value = file.name;
    } catch (e) {
      showMiniSnack(
        context,
        "Error",
        "Failed to pick or process image: $e",
        type: MiniSnackType.error,
        maxWidth: 320,
        bottomGap: 18,
      );
    }
  }

  void clearPickedImage() {
    rxBase64Image.value = null;
    rxImageFileName.value = null;
  }

  void saveFoodDetails(BuildContext context) {
    if (!formKey.currentState!.validate()) {
      showMiniSnack(
        context,
        "Validation Error",
        "Please fill all required fields correctly.",
        type: MiniSnackType.info,
        maxWidth: 320,
        bottomGap: 18,
      );
      return;
    }

    if (rxPriceList.isEmpty) {
      showMiniSnack(
        context,
        "Price Required",
        "Please add at least one price for the food item.",
        type: MiniSnackType.info,
        maxWidth: 320,
        bottomGap: 18,
      );
      return;
    }

    final strFoodName = textEditingControllerFoodName.text.trim();
    final strFoodCategoryName = textEditingControllerFoodCategory.text.trim();
    final strFoodShortCode = textEditingControllerFoodShortCode.text.trim();
    final strFoodDescription = textEditingControllerFoodDescription.text.trim();
    final strPrepTime = textEditingControllerPrepTime.text.trim();
    final strHSNCode = textEditingControllerHSNCode.text.trim();
    final kitchenName = textEditingControllerKitchenDepName.text.trim();
    final strStock = textEditingControllerStock.text.trim();

    if (strFoodCategoryName.isEmpty) {
      showMiniSnack(
        context,
        "Info",
        "Select a food category",
        type: MiniSnackType.info,
        maxWidth: 320,
        bottomGap: 18,
      );
      return;
    }

    final existingSameName = boxEntityFood
        .query(EntityFood_.foodName.equals(strFoodName))
        .build()
        .find();
    final isDuplicate = existingSameName.any(
      (e) => e.foodId != (editingFood?.foodId ?? 0),
    );
    if (isDuplicate) {
      showMiniSnack(
        context,
        "Duplicate Name",
        "'$strFoodName' food type already exists.",
        type: MiniSnackType.error,
        maxWidth: 320,
        bottomGap: 18,
      );
      return;
    }

    EntityKitchenDepartment? kitchen;
    if (kitchenName.isNotEmpty) {
      kitchen = boxKitchenDepartment
          .query(EntityKitchenDepartment_.name.equals(kitchenName))
          .build()
          .findFirst();
      kitchen ??= EntityKitchenDepartment(name: kitchenName);
    }

    String? selectedMenuName;
    if (selectedMenuId.value != 0 && Get.isRegistered<ControllerMenu>()) {
      final menuController = Get.find<ControllerMenu>();
      final selectedMenu = menuController.menuList.firstWhereOrNull(
        (menu) => menu.id == selectedMenuId.value,
      );
      selectedMenuName = selectedMenu?.name;
    }

    EntityFood foodToSave;
    if (editingFood == null) {
      foodToSave = EntityFood(
        categoryName: strFoodCategoryName,
        foodName: strFoodName,
        isVeg: selectIsVeg.value,
        shortCode: strFoodShortCode,
        foodDescription: strFoodDescription,
        prepTime: double.tryParse(strPrepTime),
        hsnCode: strHSNCode,
        foodType: selectIsVeg.value ? null : selectedMeatType.value,
        menu: selectedMenuName,
      );
      foodToSave.isActive = true;
    } else {
      foodToSave = editingFood!;
      foodToSave
        ..foodName = strFoodName
        ..categoryName = strFoodCategoryName
        ..isVeg = selectIsVeg.value
        ..shortCode = strFoodShortCode
        ..foodDescription = strFoodDescription
        ..prepTime = double.tryParse(strPrepTime)
        ..hsnCode = strHSNCode
        ..foodType = selectIsVeg.value ? null : selectedMeatType.value
        ..menu = selectedMenuName;
      if (foodToSave.isActive == null) {
        foodToSave.isActive = true;
      }
    }

    foodToSave.stock = double.tryParse(strStock);

    foodToSave.kitchen.target = kitchen;
    if (currentTaxUuid.value != null) {
      final taxBox = Get.find<Box<EntityTax>>();
      final selectedTaxEntity = taxBox
          .query(EntityTax_.taxUuid.equals(currentTaxUuid.value!))
          .build()
          .findFirst();
      foodToSave.tax.target = selectedTaxEntity;
    } else {
      foodToSave.tax.target = null;
    }

    foodToSave.price.clear();
    foodToSave.price.addAll(rxPriceList);

    if (rxBase64Image.value != null && rxBase64Image.value!.isNotEmpty) {
      foodToSave.images = [rxBase64Image.value!];
      foodToSave.imgPath = rxBase64Image.value!;
    } else {
      foodToSave.images = [];
      foodToSave.imgPath = null;
    }

    final id = boxEntityFood.put(foodToSave);
    debugPrint(
      editingFood == null
          ? "Inserted food Id is: $id"
          : "Updated food Id is: ${foodToSave.foodId}",
    );

    if (editingFood == null) {
      textEditingControllerFoodName.clear();
      textEditingControllerFoodShortCode.clear();
      textEditingControllerFoodCategory.clear();
      selectedCategoryId.value = 0;
      selectedMeatType.value = null;
      rxPriceList.clear();
      textEditingControllerFoodDescription.clear();
      textEditingControllerPrepTime.clear();
      textEditingControllerHSNCode.clear();
      textEditingControllerStock.clear();
      textEditingControllerKitchenDepName.clear();
      currentTaxUuid.value = null;
      foodNameForTaxCard.value = "";
      rxBase64Image.value = null;
      rxImageFileName.value = null;
    }

    if (Get.isRegistered<ControllerFood>()) {
      try {
        Get.find<ControllerFood>().refreshFoodData();
      } catch (_) {}
    }
    if (Get.isRegistered<ControllerOrder>()) {
      try {
        Get.find<ControllerOrder>().refreshFoodList();
      } catch (_) {}
    }

    Get.back();
  }

  @override
  void onClose() {
    textEditingControllerFoodName.removeListener(_nameListener);
    textEditingControllerFoodName.dispose();
    textEditingControllerFoodCategory.dispose();
    textEditingControllerFoodShortCode.dispose();
    textEditingControllerFoodDescription.dispose();
    textEditingControllerPrepTime.dispose();
    textEditingControllerHSNCode.dispose();
    textEditingControllerStock.dispose();
    textEditingControllerKitchenDepName.dispose();
    super.onClose();
  }
}