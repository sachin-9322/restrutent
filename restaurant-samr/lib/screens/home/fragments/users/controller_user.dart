import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:objectbox/objectbox.dart';
import 'package:splash_screen_03/constant/api_constant.dart';
import 'package:splash_screen_03/model/entity_user.dart';
import 'package:splash_screen_03/objectbox.g.dart';
import 'package:splash_screen_03/repository/Base64.dart';
import 'package:splash_screen_03/services/user_api.dart';

class ControllerUser extends GetxController {
  late Box<EntityUser> userBox = Get.find();
  var rxUserList = <EntityUser>[].obs;
  final UserApi _userApi = UserApi();
  final StorageRepository storage = StorageRepository();
var isLoading = false.obs;

@override
void onInit() {
  super.onInit();

  if ((storage.restaurant).isEmpty) {
    print("🚫 No restaurantId → skipping fetchUsers()");
    return;
  }

  fetchUsers();
}

Future<void> fetchUsers() async {
  isLoading.value = true;   // ⬅️ Start loader
  try {
    print("📥 FETCHING USERS FROM API...");

    final response = await _userApi.getUsers();

    if (response.statusCode == 200 && response.body['success'] == true) {
      final list = response.body['data'] as List;
      final mapped = list.map((e) => EntityUserMapper.fromJson(e)).toList();

      rxUserList.assignAll(mapped);
      print("📦 USERS LOADED: ${rxUserList.length}");
    } else {
      print("❌ Failed to fetch users");
      rxUserList.clear();
    }

  } catch (e) {
    print("❌ ERROR in fetchUsers(): $e");
  } finally {
    isLoading.value = false;  // ⬅️ Stop loader
  }
}

static Future<void> _fetchUsersBackgroundTask(Map<String, dynamic> data) async {
  try {
    final String restaurantJson = data["restaurantJson"] ?? "";
    final String token = data["token"] ?? "";

    if (restaurantJson.isEmpty || token.isEmpty) {
      print("❌ Missing restaurant or token inside isolate");
      return;
    }

    // --- PARSE RESTAURANT ID ---
    final rest = jsonDecode(restaurantJson);
    final restaurantId = rest["_id"]?.toString() ?? "";
    if (restaurantId.isEmpty) {
      print("❌ No restaurantId inside isolate");
      return;
    }

    // --- API CALL ---
    final endpoint =
        "${ApiConstant.apiBase}/users?page=1&limit=200&restaurantId=$restaurantId";

    final response = await GetConnect().get(
      endpoint,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200 ||
        response.body == null ||
        response.body["success"] != true) {
      print("❌ Isolate API failed: ${response.statusCode}");
      return;
    }

    final users = response.body["data"] as List;

    // --- OPEN STORE IN ISOLATE ---
    final store = await openStore(directory: "user_fetch_isolate.db");
    final box = Box<EntityUser>(store);

    for (final u in users) {
      final user = EntityUserMapper.fromJson(u);

      user.userName = (user.userName ?? "").trim().toLowerCase();
      box.put(user);
    }

    store.close();
    print("✅ Isolate saved ${users.length} users to local DB");

  } catch (e) {
    print("❌ Isolate Task Error: $e");
  }
}


  // ======================================================
  // 🔢 PIN GENERATOR
  // ======================================================
  String _generatePin() {
    final random = DateTime.now().millisecondsSinceEpoch.remainder(9000) + 1000;
    return random.toString();
  }

  // ======================================================
  // 🔎 GET SERVICE USERS
  // ======================================================
  List<EntityUser> getServiceUsers() {
    return userBox
        .query(EntityUser_.userType.oneOf(['Captain', 'Waiter']))
        .build()
        .find();
  }

  // ======================================================
  // ❌ DELETE USER
  // ======================================================
  void deleteUser(int id) {
    print("🗑 Deleting user objectId: $id");
    userBox.remove(id);
    fetchUsers();
  }
}
