import 'package:get/get.dart';
import 'package:splash_screen_03/constant/api_constant.dart';
import 'package:splash_screen_03/model/entity_cateogry_tax.dart';
import 'package:splash_screen_03/model/entity_food.dart';
import 'package:splash_screen_03/repository/Base64.dart';
import 'package:splash_screen_03/services/api_client.dart';

import '../../../../objectbox.g.dart';

class ControllerFood extends GetxController {
  // --- FIX: Using explicit constants for display name and internal ID ---
  // This is the internal ID used for filtering when "All" is selected.
  static const String ALL_ITEMS_UUID = "ALL";
  // This is the display name shown in the UI's category list.
  static const String ALL_ITEMS_NAME = "All";

  Box<EntityCategoryTax> boxEntityCategory = Get.find();
  Box<EntityFood> boxEntityFood = Get.find();
  final ApiClient apiClient = ApiClient();
  final StorageRepository storage = StorageRepository();

  // Category lists
  var rxMasterCategoryList = <EntityCategoryTax>[].obs;
  var rxDisplayCategoryList = <EntityCategoryTax>[].obs;

  // Food lists
  List<EntityFood> _masterFoodList = [];
  var rxFoodList = <EntityFood>[].obs;

  // Filter states
  // This now correctly stores the ID for filtering ("ALL" or the category name)
  var selectedCategoryUuid = ALL_ITEMS_UUID.obs;
  final _currentSearchQuery = "".obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();

    // Load local data first
    _fetchCategoriesAndPrepareDisplayList();
    _fetchMasterFoodList();
    _applyFilters();

    // Fallback: If no food items found locally, try fetching from API
    if (_masterFoodList.isEmpty) {
      fetchFoodFromApi();
    } else {
      isLoading.value = false;
    }

    ever(selectedCategoryUuid, (_) => _applyFilters());
    ever(_currentSearchQuery, (_) => _applyFilters());
  }

  Future<void> fetchFoodFromApi() async {
    isLoading.value = true;

    final restaurantId = storage.restaurantId;

    if (restaurantId.isEmpty) {
      print("❌ No restaurantId saved");
      isLoading.value = false;
      return;
    }

    final endpoint = ApiConstant.getMenuItems(restaurantId);
    print("🌐 Fetching Menu Items API => $endpoint");

    final response = await apiClient.getRequestWithToken(endpoint);

    if (response.statusCode == 200 &&
        response.body != null &&
        response.body['success'] == true) {
      final List data = response.body['data'] ?? [];

      if (data.isNotEmpty) {
        boxEntityFood.removeAll();
        for (var item in data) {
          try {
            final food = EntityFood.fromJson(item);
            boxEntityFood.put(food);
          } catch (e) {
            print("❌ Error saving food item: $e");
          }
        }
      }
    }

    _fetchMasterFoodList();
    _applyFilters();

    isLoading.value = false;
  }

  void _fetchCategoriesAndPrepareDisplayList() {
    rxMasterCategoryList.value = boxEntityCategory.getAll();

    // --- FIX: Correctly create the "All" category for UI display ---
    // Create a transient object for the UI list with the correct display name.
    // Do NOT overwrite the name with the UUID here.
    final allCategory = EntityCategoryTax(categoryName: ALL_ITEMS_NAME);

    rxDisplayCategoryList.value = [allCategory, ...rxMasterCategoryList];
  }

  void _fetchMasterFoodList() {
    _masterFoodList = boxEntityFood.getAll();
  }

  void refreshFoodData() {
    _fetchCategoriesAndPrepareDisplayList();
    _fetchMasterFoodList();
    _applyFilters();
  }

  void setSearchQuery(String query) {
    _currentSearchQuery.value = query.toLowerCase();
  }

  // --- FIX: Robustly handle category selection ---
  void selectCategory(String? categoryName) {
    // When the UI passes a category name, we map it to the correct filter ID.
    if (categoryName == ALL_ITEMS_NAME) {
      // If the user selected "All", use the special UUID.
      selectedCategoryUuid.value = ALL_ITEMS_UUID;
    } else {
      // For any other category, its name is its ID. If null, default to "All".
      selectedCategoryUuid.value = categoryName ?? ALL_ITEMS_UUID;
    }
  }

  void _applyFilters() {
    List<EntityFood> filteredList = List.from(_masterFoodList);

    // 1. Filter by selected category (this logic remains correct)
    if (selectedCategoryUuid.value != ALL_ITEMS_UUID) {
      filteredList = filteredList
          .where((food) => food.categoryName == selectedCategoryUuid.value)
          .toList();
    }

    // 2. Filter by search query
    if (_currentSearchQuery.value.isNotEmpty) {
      final query = _currentSearchQuery.value;
      filteredList = filteredList.where((food) {
        final foodNameMatch =
            food.foodName?.toLowerCase().contains(query) ?? false;
        final categoryNameMatch =
            food.categoryName?.toLowerCase().contains(query) ?? false;
        return foodNameMatch || categoryNameMatch;
      }).toList();
    }
    rxFoodList.value = filteredList;
  }

  // This function is no longer needed for filtering, but can be kept for display purposes if needed elsewhere.
  String getCategoryName(String? categoryName) {
    if (categoryName == null || categoryName.isEmpty) {
      return 'N/A';
    }
    final category = rxMasterCategoryList.firstWhereOrNull(
      (cat) => cat.categoryName == categoryName,
    );
    return category?.categoryName ?? categoryName;
  }

  void removeFoodAtIndex(int index) {
    if (index < 0 || index >= rxFoodList.length) return;

    final entityToRemove = rxFoodList[index];
    final success = boxEntityFood.remove(entityToRemove.foodId);

    if (success) {
      _fetchMasterFoodList();
      _applyFilters();
    }
  }

  void isActiveOrDeActive(EntityFood food) {
    food.isActive = !(food.isActive ?? false);
    boxEntityFood.put(food);

    _fetchMasterFoodList();
    _applyFilters();
  }
}
