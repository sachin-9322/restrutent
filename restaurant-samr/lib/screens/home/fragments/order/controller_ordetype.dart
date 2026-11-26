import 'package:get/get.dart';
import 'package:splash_screen_03/services/api_client.dart';
import 'package:splash_screen_03/constant/api_constant.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class ControllerOrderType extends GetxController {
  var rxOrderTypes = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchOrderTypes(); // 🔥 Auto-load order types on app startup
  }

  String getLabelById(String? id) {
    if (id == null || id.trim().isEmpty) return "Unknown";

    final found = rxOrderTypes.firstWhereOrNull((e) => e["_id"] == id);

    if (found == null) return "Unknown";

    // ✔ Get the English name correctly
    if (found["name"] is Map && found["name"]["en"] != null) {
      return found["name"]["en"].toString();
    }

    return "Unknown";
  }

  String? getIdByLabel(String label) {
    if (label.trim().isEmpty) return null;
    final found = rxOrderTypes.firstWhereOrNull((e) {
      if (e["name"] is Map && e["name"]["en"] != null) {
        return e["name"]["en"].toString().toLowerCase() ==
            label.trim().toLowerCase();
      }
      return false;
    });
    return found?["_id"]?.toString();
  }

  Future<void> fetchOrderTypes({int retryCount = 0}) async {
    try {
      if (retryCount == 0) isLoading.value = true;

      final api = ApiClient();
      final response = await api.getRequestWithToken(ApiConstant.orderTypes);

      if (response.statusCode == 200 && response.body?["success"] == true) {
        final List list = response.body["data"];

        rxOrderTypes.value = list
            .map((e) => e as Map<String, dynamic>)
            .toList();
        print("✅ Order Types fetched: ${rxOrderTypes.length}");
        isLoading.value = false;
      } else {
        print(
          "❌ Failed to fetch Order Types: ${response.statusCode} - ${response.body}",
        );

        // Retry on 503 or connection error (null status)
        if (retryCount < 3 &&
            (response.statusCode == 503 || response.statusCode == null)) {
          final delay = Duration(seconds: math.pow(2, retryCount).toInt());
          print(
            "⚠️ Retrying in ${delay.inSeconds}s... (Attempt ${retryCount + 1}/3)",
          );
          await Future.delayed(delay);
          await fetchOrderTypes(retryCount: retryCount + 1);
          return; // Exit current stack to avoid double loading state reset
        } else {
          Get.snackbar(
            "Connection Error",
            "Failed to load Order Types. Please check your connection.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
            mainButton: TextButton(
              onPressed: () => fetchOrderTypes(),
              child: const Text("RETRY", style: TextStyle(color: Colors.white)),
            ),
            duration: const Duration(seconds: 5),
          );
        }
        isLoading.value = false;
      }
    } catch (e) {
      print("❌ Exception fetching Order Types: $e");

      if (retryCount < 3) {
        final delay = Duration(seconds: math.pow(2, retryCount).toInt());
        print(
          "⚠️ Exception caught. Retrying in ${delay.inSeconds}s... (Attempt ${retryCount + 1}/3)",
        );
        await Future.delayed(delay);
        await fetchOrderTypes(retryCount: retryCount + 1);
        return;
      }

      isLoading.value = false;
    }
  }
}
