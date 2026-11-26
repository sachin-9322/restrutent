import 'dart:convert';
import 'package:get/get.dart';
import 'package:splash_screen_03/model/entity_cateogry_tax.dart';
import 'package:splash_screen_03/constant/api_constant.dart';
import 'package:splash_screen_03/services/api_client.dart';
import 'package:splash_screen_03/repository/Base64.dart';
import '../../../../objectbox.g.dart';

class ControllerCategory extends GetxController {
  final ApiClient _api = ApiClient();
  final StorageRepository _storage = StorageRepository();

  Box<EntityCategoryTax> boxEntityCategory = Get.find();
  var rxCategoryList = <EntityCategoryTax>[].obs;

@override
void onInit() {
  super.onInit();
  // Load only local data. API call will happen at login.
  fetchDataFromLocal();
}


  /// 🔥 Load categories → API first → fallback local
  Future<void> loadCategories() async {
    final restaurantJson = _storage.restaurant;

    if (restaurantJson.isEmpty) {
      print("⚠️ No restaurant stored → loading local categories only");
      fetchDataFromLocal();
      return;
    }
    final restMap = jsonDecode(restaurantJson);

    // FIX HERE → check _id first
    final restaurantId =
        restMap["_id"]?.toString() ?? restMap["id"]?.toString() ?? "";

    if (restaurantId.isEmpty) {
      print("⚠️ Restaurant ID empty → using local data");
      fetchDataFromLocal();
      return;
    }

    print("🍽 Loading categories for RestaurantID → $restaurantId");

    final apiResponse = await _api.getRequestWithToken(
      ApiConstant.getCategories(restaurantId),
    );

    if (apiResponse.statusCode == 200 &&
        apiResponse.body != null &&
        apiResponse.body["success"] == true) {
      final List<dynamic> data = apiResponse.body["data"] ?? [];

      saveApiCategoriesToLocal(data);
      fetchDataFromLocal();
      print("✅ Categories loaded from API");
      return;
    }

    print("⚠️ API FAILED → loading local categories");
    fetchDataFromLocal();
  }
void loadCategoryAfterLogin() {
  fetchDataFromLocal();
}

void saveApiCategoriesToLocal(List<dynamic> apiList) {
  boxEntityCategory.removeAll();

  for (var item in apiList) {
    final entity = EntityCategoryTax(
      categoryName: 
          item["name"]?["en"] ??
          item["name"]?["ar"] ??
          "Unnamed",
    );

    boxEntityCategory.put(entity);
  }
}

  /// 📦 Load local categories
  void fetchDataFromLocal() {
    rxCategoryList.value = boxEntityCategory.getAll();
  }

  /// 🗑 Delete
  void removeCategoryAtIndex(int index) {
    final entity = rxCategoryList[index];
    boxEntityCategory.remove(entity.id);
    fetchDataFromLocal();
  }

  void fetchDataFromCategory() {
    rxCategoryList.value = boxEntityCategory.getAll();
  }

  /// 🔍 Search
  void filterCategoryTypes(String query) {
    if (query.isEmpty) {
      rxCategoryList.value = boxEntityCategory.getAll();
      return;
    }

    rxCategoryList.value = boxEntityCategory
        .query(
          EntityCategoryTax_.categoryName.contains(query, caseSensitive: false),
        )
        .build()
        .find();
  }
}
