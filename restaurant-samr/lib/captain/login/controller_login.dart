// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/captain/login/auth_service.dart';
import 'package:splash_screen_03/constant/api_constant.dart';
import 'package:splash_screen_03/model/entity_food.dart';
import 'package:splash_screen_03/model/model_restaurant.dart';
import 'package:splash_screen_03/objectbox.g.dart';
import 'package:splash_screen_03/screens/home/fragments/category_type/controller_category.dart';
import 'package:splash_screen_03/screens/home/fragments/day/day_report.dart';
import 'package:splash_screen_03/screens/home/fragments/food_type/controller_food.dart';
import 'package:splash_screen_03/screens/home/fragments/order/controller_ordetype.dart';
import 'package:splash_screen_03/screens/home/fragments/table_type/controller_table.dart';
import 'package:splash_screen_03/screens/home/fragments/users/controller_user.dart';
import 'package:splash_screen_03/services/api_client.dart';
import 'package:splash_screen_03/services/controller_server.dart';
import 'package:splash_screen_03/repository/Base64.dart';
import 'package:splash_screen_03/utils/app_routes.dart';
import 'package:splash_screen_03/utils/sanbar.dart';
import '../../model/entity_user.dart';

class ControllerLogin extends GetxController {
  final username = ''.obs;
  final password = ''.obs;
  final isLoading = false.obs;

  final ControllerServer serverController = Get.put(ControllerServer());
  final AuthService authService = Get.find();
  final ApiClient apiClient = ApiClient();
  final StorageRepository storage = StorageRepository();

  late Box<EntityUser> userBox;

  double kSnackWidth = 320;
  double kSnackBottomGap = 18;

  @override
  void onInit() {
    super.onInit();
    userBox = Get.find<Box<EntityUser>>();
  }

  // -------------------------------
  // ROUTE SELECTOR
  // -------------------------------
  void navigateByRole(String role) {
    role = role.toLowerCase();
    if (role == "captain") {
      Get.offAllNamed(AppRoutes.captainHome);
    } else if (role == "kds") {
      Get.offAllNamed(AppRoutes.activityHomed);
    } else {
      Get.offAllNamed(AppRoutes.activityHome);
    }
  }

  // -------------------------------
  // LOGIN MAIN FUNCTION
  // -------------------------------
  Future<void> login({String? selectedServer}) async {
    final u = username.value.trim().toLowerCase();
    final p = password.value.trim();

    if (u.isEmpty || p.isEmpty) {
      showMiniSnack(
        Get.context!,
        "Missing Info",
        "Enter username & password.",
        type: MiniSnackType.info,
      );
      return;
    }

    isLoading.value = true;

    try {
      print("==========================================");
      print("🔐 LOGIN ATTEMPT → local first");
      print("User: $u | Pass: $p");
      print("==========================================");

      // ======================================================
      // 1️⃣ LOCAL LOGIN
      // ======================================================
      final q = userBox
          .query(
            EntityUser_.userName.equals(u, caseSensitive: true) &
                (EntityUser_.userPassword.equals(p) |
                    EntityUser_.pin.equals(p)),
          )
          .build();

      final localUser = q.findFirst();
      q.close();

      if (localUser != null) {
        print("✅ LOCAL LOGIN SUCCESS");
        print("Role: ${localUser.userType}");

        authService.loginUser(localUser);

        storage.username = u;
        storage.password = p;
        storage.userType = localUser.userType ?? "";

        // Store restaurant
        if (localUser.restaurantName?.isNotEmpty == true) {
          final r = ModelRestaurant(
            name: localUser.restaurantName,
            address: localUser.address ?? "",
            email: "",
            mobileNumber: "",
            restUuid: "",
          );

          // 🔥 FIX: If we have the ID stored in idProofKey, use it!
          if (localUser.idProofKey?.isNotEmpty == true) {
            r.restUuid = localUser.idProofKey;
          }

          storage.restaurant = json.encode(r.toMap());
        }

        final role = (localUser.userType ?? "").toLowerCase();

        // Start Local Server
        if (["admin", "brand_admin", "server"].contains(role)) {
          print("🟢 Starting local server...");
          await serverController.startServer();
        }

        // START DAY LOGIC
        if (!Get.isRegistered<DayStatusController>()) {
          Get.put(DayStatusController());
        }

        final dayStatus = Get.find<DayStatusController>();

        if (storage.readBool('showShiftDialogNextLogin', defaultValue: false)) {
          await ShiftStartDialog.show();
          storage.writeBool('showShiftDialogNextLogin', false);
        } else {
          final hasOpenDay = await dayStatus.hasOpenDay();
          if (!hasOpenDay) {
            await ShiftStartDialog.show();
          }
        }

        showMiniSnack(
          Get.context!,
          "Welcome Back",
          "Logged in locally as ${localUser.userName}",
          type: MiniSnackType.success,
        );

        navigateByRole(role);
        return;
      }

      // ======================================================
      // 2️⃣ CAPTAIN WRONG PIN CHECK - REMOVED
      // ======================================================
      // We removed the specific check that blocked Captains from API login.
      // Now, if local login fails, it will proceed to API login below.

      // ======================================================
      // 3️⃣ LOGIN VIA API
      // ======================================================
      print("🌎 LOCAL NOT FOUND → API LOGIN");

      final response = await apiClient.postRequest(ApiConstant.login, {
        "username": u,
        "password": p,
      });

      if (response.statusCode == 200 &&
          response.body != null &&
          response.body['success'] == true) {
        final data = response.body['data'];
        final userInfo = data['user'];

        // Store basic info
        storage.username = u;
        storage.password = p;
        storage.accessToken = data['accessToken'] ?? "";
        storage.refreshToken = data['refreshToken'] ?? "";
        storage.sessionId = userInfo['sessionId'] ?? "";
        storage.userId = userInfo['id']?.toString() ?? "";
        storage.userType = userInfo['role']?['name']?['en'] ?? "unknown";

        final role = storage.userType.toLowerCase();

        // Start server
        if (["admin", "brand_admin", "server"].contains(role)) {
          print("🟢 Starting server for API login");
          await serverController.startServer();
        }

        // --------------------- BRAND ID FIX ------------------------
        final brandList = userInfo['brandIds'] as List?;
        print("🏷️ brandIds FULL JSON → ${jsonEncode(brandList)}");

        if (brandList != null && brandList.isNotEmpty) {
          final brandId = brandList.first['id']?.toString() ?? "";
          storage.brandId = brandId;
          print("🏷️ Saved brandId = ${storage.brandId}");
        }

        // --------------------- RESTAURANT ID -----------------------
        final restList = userInfo['restaurantIds'] as List?;
        print("🍽️ restaurantIds FULL JSON → ${jsonEncode(restList)}");
        // --------------------- RESTAURANT ID -----------------------
        print("🍽️ restaurantIds FULL JSON → ${jsonEncode(restList)}");

        if (restList != null && restList.isNotEmpty) {
          final restId = restList.first['id']?.toString() ?? "";

          print("🏬 Restaurant ID Extracted → $restId");

          // 🔥 FETCH FULL RESTAURANT DATA FROM API
          final restResponse = await apiClient.getRequestWithToken(
            "${ApiConstant.restaurantById}/$restId",
          );

          print(
            "🏨 Restaurant API Response → ${jsonEncode(restResponse.body)}",
          );

          if (restResponse.statusCode == 200 &&
              restResponse.body?['success'] == true) {
            final restData = restResponse.body['data'];

            // 🔥 SAVE RESTAURANT JSON IN STORAGE
            storage.restaurant = json.encode(restData);
            storage.isSyncFeature = restData['isSyncFeature'] == true;

            // 🔍 Debug
            print(
              "🔄 RESTAURANT isSyncFeature from API → ${restData['isSyncFeature']}",
            );
            print("🔄 SAVED isSyncFeature → ${storage.isSyncFeature}");

            print("💾 Restaurant JSON saved → ${storage.restaurant}");
          } else {
            print("❌ Failed to fetch restaurant data from API");
          }
        }

        // ======================================================
        // 🔥 CRITICAL FIX: SAVE USER ENTITY FOR OFFLINE LOGIN
        // ======================================================
        try {
          final userEntity = EntityUserMapper.fromJson(userInfo);
          // Ensure password is saved for local login
          userEntity.userPassword = p;
          authService.loginUser(userEntity);
          print("✅ User entity saved for offline login");
        } catch (e) {
          print("❌ Failed to save user entity: $e");
        }
        // ======================================================

        // Success snackbar
        showMiniSnack(
          Get.context!,
          "Login Successful",
          "Welcome ${u.toUpperCase()}",
          type: MiniSnackType.success,
        );

        // ======================================================
        // 🟢 START DAY LOGIC (API LOGIN)
        // ======================================================
        if (!Get.isRegistered<DayStatusController>()) {
          Get.put(DayStatusController());
        }

        final dayStatus = Get.find<DayStatusController>();

        if (storage.readBool('showShiftDialogNextLogin', defaultValue: false)) {
          await ShiftStartDialog.show();
          storage.writeBool('showShiftDialogNextLogin', false);
        } else {
          final hasOpenDay = await dayStatus.hasOpenDay();
          if (!hasOpenDay) {
            await ShiftStartDialog.show();
          }
        }
        // LOAD TABLES ONCE DURING LOGIN
        try {
          print("📡 Fetching tables during login...");

          final restaurantId = storage.restaurantId; // from Saved JSON
          final tableResponse = await apiClient.getRequestWithToken(
            ApiConstant.getTables(restaurantId),
          );

          if (tableResponse.statusCode == 200 &&
              tableResponse.body?["success"] == true) {
            final List<dynamic> list = tableResponse.body["data"];

            final controllerTable = Get.find<ControllerTable>();
            controllerTable.saveApiTablesToLocal(list);
            controllerTable.loadTablesAfterLogin();

            print("✅ Tables loaded during login");
          } else {
            print("⚠️ Couldn’t fetch tables during login → using local data");
          }
        } catch (e) {
          print("⚠️ Table fetch failed during login: $e");
        }

        // LOAD TAX PRODUCT GROUPS
        try {
          print("💰 Fetching tax product groups during login...");
          final restaurantId = storage.restaurantId;
          final taxResponse = await apiClient.getRequestWithToken(
            apiClient.getTaxProductGroups(restaurantId),
          );

          if (taxResponse.statusCode == 200 &&
              taxResponse.body?["success"] == true) {
            final taxData = taxResponse.body["data"];
            // Convert list to map for faster lookup: { "taxGroupId": { ...taxData } }
            final Map<String, dynamic> taxMap = {};
            if (taxData is List) {
              for (final item in taxData) {
                final id = item['_id']?.toString() ?? "";
                if (id.isNotEmpty) {
                  taxMap[id] = item;
                }
              }
            }
            storage.taxProductGroups = jsonEncode(taxMap);
            print("✅ Tax groups loaded and stored: ${taxMap.length} groups");
          } else {
            print("⚠️ Tax group API failed: ${taxResponse.body}");
          }
        } catch (e) {
          print("❌ Tax group fetch failed: $e");
        }

        // LOAD CATEGORIES ONCE DURING LOGIN
        try {
          print("📦 Fetching categories during login...");

          final restaurantId = storage.restaurantId;

          final catResponse = await apiClient.getRequestWithToken(
            ApiConstant.getCategories(restaurantId),
          );

          if (catResponse.statusCode == 200 &&
              catResponse.body?["success"] == true) {
            final List<dynamic> catList = catResponse.body["data"];

            if (!Get.isRegistered<ControllerCategory>()) {
              Get.put(ControllerCategory());
            }
            final categoryController = Get.find<ControllerCategory>();
            categoryController.saveApiCategoriesToLocal(catList);
            categoryController.loadCategoryAfterLogin();

            print("✅ Categories loaded during login");
          } else {
            print("⚠️ Category API failed → using local data");
          }
        } catch (e) {
          print("❌ Category fetch failed during login: $e");
        }

        // LOAD MENU ITEMS ONCE DURING LOGIN (With Pagination)
        try {
          print("🍔 Fetching menu items during login...");
          final restaurantId = storage.restaurantId;

          if (!Get.isRegistered<ControllerFood>()) {
            Get.put(ControllerFood());
          }
          final foodCtrl = Get.find<ControllerFood>();
          foodCtrl.boxEntityFood
              .removeAll(); // Clear existing before fetching new

          int currentPage = 1;
          bool hasNextPage = true;
          int totalFetched = 0;

          while (hasNextPage) {
            print("🍔 Fetching page $currentPage...");
            final menuResponse = await apiClient.getRequestWithToken(
              ApiConstant.getMenuItems(
                restaurantId,
                page: currentPage,
                limit: 100,
              ),
            );

            if (menuResponse.statusCode == 200 &&
                menuResponse.body?["success"] == true) {
              final List data = menuResponse.body["data"] ?? [];
              final meta = menuResponse.body["meta"];

              if (data.isNotEmpty) {
                for (var item in data) {
                  try {
                    final food = EntityFood.fromJson(item);
                    foodCtrl.boxEntityFood.put(food);
                  } catch (e) {
                    print("❌ Error saving food item: $e");
                  }
                }
                totalFetched += data.length;
              }

              // Check pagination
              if (meta != null && meta["hasNextPage"] == true) {
                currentPage++;
              } else {
                hasNextPage = false;
              }
            } else {
              print(
                "⚠️ Menu item API failed on page $currentPage: ${menuResponse.body}",
              );
              hasNextPage = false; // Stop on error
            }
          }

          foodCtrl.refreshFoodData();
          print("✅ Total menu items loaded: $totalFetched");
        } catch (e) {
          print("❌ Menu item fetch failed: $e");
        }

        if (!Get.isRegistered<ControllerOrderType>()) {
          Get.put(ControllerOrderType(), permanent: true);
        }
        await Get.find<ControllerOrderType>().fetchOrderTypes();

        navigateByRole(role);
        return;
      }

      // ======================================================
      // ERROR HANDLING
      // ======================================================
      if (response.statusCode == 401) {
        showMiniSnackGlobal(
          "Unauthorized",
          "Invalid username or password.",
          type: MiniSnackType.error,
        );
      } else if (response.statusCode == 403) {
        final msg =
            response.body?['message'] ??
            "Active session detected. Please logout first.";

        showMiniSnackGlobal(
          "Active Session",
          msg,
          type: MiniSnackType.info,
          maxWidth: kSnackWidth,
          bottomGap: kSnackBottomGap,
        );
      } else {
        showMiniSnackGlobal(
          "Login Failed",
          "Unexpected error: ${response.statusCode ?? 'Unknown'}",
          type: MiniSnackType.error,
          maxWidth: kSnackWidth,
          bottomGap: kSnackBottomGap,
        );
      }
    } catch (e) {
      print("❌ Login Exception: $e");
      showMiniSnackGlobal(
        "Error",
        "Check internet connection.",
        type: MiniSnackType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
