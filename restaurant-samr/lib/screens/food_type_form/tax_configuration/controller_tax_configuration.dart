import 'package:flutter/material.dart'; // Added for Snackbar
import 'package:get/get.dart';
import 'package:objectbox/objectbox.dart';
import 'package:splash_screen_03/model/entity_cateogry_tax.dart';
import 'package:splash_screen_03/model/entity_food.dart';
import 'package:splash_screen_03/model/entity_tax.dart';
import 'package:splash_screen_03/screens/food_type_form/controller_food_form.dart';
import '../../../objectbox.g.dart'; // Assuming objectbox.g.dart is in the lib folder

class ControllerTaxConfiguration extends GetxController {
  static const String ALL_CATEGORIES_ID = "ALL_CATEGORIES_ID_INTERNAL";
  static const String ALL_CATEGORIES_NAME = "All Categories";

  late Box<EntityCategoryTax> _categoryBox;
  late Box<EntityFood> _foodBox;
  late Box<EntityTax> _taxBox;

  var rxMasterCategoryList = <EntityCategoryTax>[].obs;
  var rxDisplayCategoryList = <EntityCategoryTax>[].obs;
  List<EntityFood> _masterFoodList = [];
  var rxDisplayFoodList = <EntityFood>[].obs;
  var selectedCategoryId = ALL_CATEGORIES_ID.obs;

  var rxAvailableTaxes = <EntityTax>[].obs;
  var selectedTaxUuidInBottomSheet = Rx<String?>(null);

  var bottomSheetTaxGroupDisplay = 'N/A'.obs;
  var bottomSheetTaxTypeDisplay = 'N/A'.obs;
  var bottomSheetTaxPercentageDisplay = 'N/A'.obs;

  EntityFood? currentFoodForTaxConfig;
  bool _boxesInitialized = false;

  bool get initialized => _boxesInitialized;

  @override
  void onInit() {
    super.onInit();
    _initializeBoxes();
    if (_boxesInitialized) {
      _loadInitialData();
      _setupBindings();
    } else {
      Get.snackbar(
        "Initialization Failed",
        "Could not initialize necessary data components. Please try again later.",
        snackPosition: SnackPosition.BOTTOM,
      );
      _setDefaultEmptyLists();
    }
  }

  void _initializeBoxes() {
    try {
      _categoryBox = Get.find<Box<EntityCategoryTax>>();
      _foodBox = Get.find<Box<EntityFood>>();
      _taxBox = Get.find<Box<EntityTax>>();
      _boxesInitialized = true;
    } catch (e) {
      _boxesInitialized = false;
      Get.snackbar(
        "Critical Error",
        "One or more data boxes are not registered. Please ensure ObjectBox is initialized correctly. Details: $e",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 10),
      );
    }
  }

  void _loadInitialData() {
    if (!_boxesInitialized) return;
    _fetchCategoriesAndPrepareDisplayList();
    _fetchMasterFoodList();
    _fetchAvailableTaxes();
    _applyFilters();
  }

  void _setupBindings() {
    ever(selectedCategoryId, (_) => _applyFilters());
    ever<String?>(selectedTaxUuidInBottomSheet, (String? selectedTaxUuid) {
      final selectedTax = rxAvailableTaxes.firstWhereOrNull(
        (tax) => tax.taxUuid == selectedTaxUuid,
      );
      bottomSheetTaxGroupDisplay.value = selectedTax?.taxProductName ?? 'N/A';
      bottomSheetTaxPercentageDisplay.value =
          selectedTax?.taxPercentage?.toStringAsFixed(1) ?? 'N/A';
      if (selectedTax != null) {
        bottomSheetTaxTypeDisplay.value = (selectedTax.isSgstCgst ?? false) ? "SGST/CGST" : "Regular";
      } else {
        bottomSheetTaxTypeDisplay.value = 'N/A';
      }
    });
  }

  void _setDefaultEmptyLists() {
    rxDisplayCategoryList.assignAll([]);
    rxDisplayFoodList.assignAll([]);
    rxAvailableTaxes.assignAll([]);
  }

  void _fetchCategoriesAndPrepareDisplayList() {
    if (!_boxesInitialized) return;
    try {
      rxMasterCategoryList.value = _categoryBox.getAll();
      final allCategory = EntityCategoryTax(categoryName: ALL_CATEGORIES_NAME);
      rxDisplayCategoryList.value = [allCategory, ...rxMasterCategoryList];
    } catch (e) {
      Get.snackbar("Data Error", "Error fetching categories: $e", snackPosition: SnackPosition.BOTTOM);
      rxDisplayCategoryList.assignAll([]);
    }
  }

  void _fetchMasterFoodList() {
    if (!_boxesInitialized) return;
    try {
      _masterFoodList = _foodBox.getAll();
    } catch (e) {
      Get.snackbar("Data Error", "Error fetching food items: $e", snackPosition: SnackPosition.BOTTOM);
      _masterFoodList = [];
    }
  }

  void _fetchAvailableTaxes() {
    if (!_boxesInitialized) return;
    try {
      final allTaxes = _taxBox.getAll();
      rxAvailableTaxes.assignAll(
        allTaxes..sort((a, b) => (a.taxProductName ?? '').compareTo(b.taxProductName ?? '')),
      );
    } catch (e) {
      Get.snackbar("Data Error", "Error fetching tax configurations: $e", snackPosition: SnackPosition.BOTTOM);
      rxAvailableTaxes.assignAll([]);
    }
  }

  void selectCategory(String? categoryId) {
    selectedCategoryId.value = categoryId ?? ALL_CATEGORIES_ID;
  }

  void _applyFilters() {
    if (!_boxesInitialized) {
      rxDisplayFoodList.assignAll([]);
      return;
    }
    List<EntityFood> filteredList = List.from(_masterFoodList);
    if (selectedCategoryId.value != ALL_CATEGORIES_ID) {
      filteredList = filteredList
          .where((food) => food.categoryName == selectedCategoryId.value)
          .toList();
    }
    rxDisplayFoodList.value = filteredList;
  }

  void prepareForTaxConfiguration(EntityFood food) {
    if (!_boxesInitialized) return;
    currentFoodForTaxConfig = food;

    final String? currentTaxLink = food.tax.target?.taxUuid;
    if (currentTaxLink != null && currentTaxLink.isNotEmpty && rxAvailableTaxes.any((t) => t.taxUuid == currentTaxLink)) {
      selectedTaxUuidInBottomSheet.value = currentTaxLink;
    } else if (rxAvailableTaxes.isNotEmpty) {
      selectedTaxUuidInBottomSheet.value = rxAvailableTaxes.first.taxUuid;
    } else {
      selectedTaxUuidInBottomSheet.value = null;
    }
  }

  void applyTaxSelectionToFood() {
    if (!_boxesInitialized || currentFoodForTaxConfig == null) {
      Get.snackbar(
        "Error",
        "Cannot apply tax: Food item or data not properly initialized.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final selectedTaxEntity = rxAvailableTaxes.firstWhereOrNull(
      (tax) => tax.taxUuid == selectedTaxUuidInBottomSheet.value,
    );

    currentFoodForTaxConfig!.tax.target = selectedTaxEntity;
    
    try {
      _foodBox.put(currentFoodForTaxConfig!); 
      _fetchMasterFoodList(); 
      _applyFilters();        

      // Update ControllerFoodForm's currentTaxUuid for immediate UI reflection in ActivityFoodForm
      if (Get.isRegistered<ControllerFoodForm>()) {
        Get.find<ControllerFoodForm>().currentTaxUuid.value = selectedTaxUuidInBottomSheet.value;
      }

      Get.snackbar(
        "Success",
        "Tax configuration updated for ${currentFoodForTaxConfig!.foodName ?? 'Food Item'}.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Database Error",
        "Could not save tax configuration: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  void clearTaxForFood(EntityFood food) {
    if (!_boxesInitialized) {
      Get.snackbar("Error", "Data not initialized.", snackPosition: SnackPosition.BOTTOM);
      return;
    }
    food.tax.target = null;
    try {
      _foodBox.put(food);
      _fetchMasterFoodList();
      _applyFilters();

      // Update ControllerFoodForm's currentTaxUuid for immediate UI reflection in ActivityFoodForm
      if (Get.isRegistered<ControllerFoodForm>()) {
        Get.find<ControllerFoodForm>().currentTaxUuid.value = null;
      }

      Get.snackbar(
        "Tax Cleared",
        "Tax configuration cleared for ${food.foodName ?? 'Food Item'}.",
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar("Database Error", "Could not clear tax: $e", snackPosition: SnackPosition.BOTTOM);
    }
  }

  void refreshAllData() {
    if (!_boxesInitialized) {
      Get.snackbar(
        "Refresh Error",
        "Cannot refresh: data components not initialized. Attempting to reinitialize...",
        snackPosition: SnackPosition.BOTTOM,
      );
      _initializeBoxes(); 
      if (!_boxesInitialized) {
         Get.snackbar(
          "Refresh Failed",
          "Reinitialization failed. Please check setup.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
    }
    _loadInitialData();
    Get.snackbar(
      "Data Refreshed",
      "Categories, food items, and tax data have been updated.",
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
