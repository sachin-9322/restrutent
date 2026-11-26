import 'dart:convert';
import 'package:get/get.dart';
import 'package:splash_screen_03/constant/api_constant.dart';
import 'package:splash_screen_03/repository/Base64.dart';
import 'package:splash_screen_03/services/api_client.dart';

class UserApi extends GetxService {
  final ApiClient _api = ApiClient();
  final StorageRepository _storage = StorageRepository();

  /// Fetch users dynamically using stored restaurantId and auth token
  Future<Response> getUsers({int page = 1, int limit = 10}) async {
    final restaurantJson = _storage.restaurant;
    final token = _storage.accessToken;

    if (token.isEmpty) {
      print("🚫 Missing access token — please log in again.");
      return Response(
        statusCode: 401,
        body: {'success': false, 'message': 'Unauthorized — token missing'},
      );
    }

    if (restaurantJson.isEmpty) {
      print("⚠️ No restaurant data found in storage");
      return Response(
        statusCode: 400,
        body: {'success': false, 'message': 'Restaurant ID missing'},
      );
    }

    // ✅ Parse restaurantId from stored JSON (safe JSON decode)
    String restaurantId = '';
    try {
      final Map<String, dynamic> restaurantData = jsonDecode(restaurantJson);
      restaurantId = restaurantData['_id']?.toString() ?? '';
    } catch (e) {
      print("⚠️ Failed to parse restaurant JSON: $e");
    }

    if (restaurantId.isEmpty) {
      print("🚫 Restaurant ID missing inside stored restaurant data.");
      return Response(
        statusCode: 400,
        body: {'success': false, 'message': 'Invalid restaurant ID'},
      );
    }

    // ✅ Build endpoint dynamically
    final endpoint =
        "${ApiConstant.apiBase}/users?page=$page&limit=$limit&restaurantId=$restaurantId";

    print("📡 Fetching users → $endpoint");
    print("🔐 Using token: ${token.substring(0, 20)}...");

    // ✅ GET with Authorization header
    try {
      final response = await _api.httpClient.get(
        endpoint,
        headers: {"Authorization": "Bearer $token"},
      );

      print("✅ Status: ${response.statusCode}");
      print("✅ Response: ${response.body}");
      return response;
    } catch (e) {
      print("🚨 Network Error: $e");
      return Response(
        statusCode: 500,
        body: {'success': false, 'message': 'Connection error: $e'},
      );
    }
  }
}
