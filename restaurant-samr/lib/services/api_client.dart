import 'package:get/get.dart';
import 'package:splash_screen_03/constant/api_constant.dart';
import 'package:splash_screen_03/repository/Base64.dart';

class ApiClient extends GetConnect {
  ApiClient() {
    httpClient.baseUrl = ApiConstant.baseUrl;
    httpClient.timeout = const Duration(seconds: 15);
    httpClient.errorSafety = true;
  }

  final StorageRepository _storage = StorageRepository();

  // ===========================
  // TOKEN REFRESH
  // ===========================
  Future<bool> refreshAccessToken() async {
    final refreshToken = _storage.refreshToken;

    if (refreshToken.isEmpty) {
      print("❌ No refresh token available");
      return false;
    }

    print("🔄 Attempting to refresh access token...");

    try {
      final response = await post(
        ApiConstant.refreshToken,
        {},
        headers: {
          "Authorization": "Bearer $refreshToken",
          "Content-Type": "application/json",
        },
      );

      print("🔄 Refresh Response Status: ${response.statusCode}");

      if (response.statusCode == 200 &&
          response.body != null &&
          response.body['success'] == true) {
        final data = response.body['data'];

        // Update tokens in storage
        _storage.accessToken = data['accessToken'] ?? "";
        _storage.refreshToken = data['refreshToken'] ?? "";

        print("✅ Token refreshed successfully");
        return true;
      } else {
        print("❌ Token refresh failed: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Token refresh error: $e");
      return false;
    }
  }

  // ===========================
  // NORMAL POST REQUEST
  // ===========================
  Future<Response> postRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final fullUrl = "${httpClient.baseUrl}$endpoint";
    print("➡️ Sending POST to: $fullUrl");

    try {
      final response = await post(endpoint, body);

      if (response.statusCode == null) {
        print("❌ Status: NULL (Connection Error)");
        return const Response(
          statusCode: 503,
          statusText: 'Service Unavailable',
          body: {
            'success': false,
            'message': 'Connection failed. Server unreachable.',
          },
        );
      }

      print("✅ Status: ${response.statusCode}");
      print("✅ Response: ${response.body}");
      return response;
    } catch (e) {
      print("🚨 POST Error: $e");
      return Response(
        statusCode: 500,
        statusText: e.toString(),
        body: {'success': false, 'message': 'Connection error: $e'},
      );
    }
  }

  // ===========================
  // SILENT LOGIN FALLBACK
  // ===========================

  // ==================================================
  // POST WITH TOKEN → AUTO REFRESH ON 401
  // ==================================================
  Future<Response> postRequestWithToken(
    String endpoint,
    Map<String, dynamic> body, {
    bool isRetry = false, // Prevent infinite loops
  }) async {
    final token = _storage.accessToken;

    print("➡️ POST (Auth): ${httpClient.baseUrl}$endpoint");
    // print("🔑 Using Token: $token");

    try {
      final response = await post(
        endpoint,
        body,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == null) {
        print("❌ Status: NULL (Connection Error)");
        return const Response(
          statusCode: 503,
          statusText: 'Service Unavailable',
          body: {
            'success': false,
            'message': 'Connection failed. Server unreachable.',
          },
        );
      }

      print("✅ Status: ${response.statusCode}");
      // print("✅ Response: ${response.body}");

      // 🔄 Auto-refresh on 401 (only once)
      if (response.statusCode == 401 && !isRetry) {
        print("⚠️ 401 Unauthorized - Attempting token refresh...");
        bool refreshed = await refreshAccessToken();

        if (refreshed) {
          print("🔄 Retrying request with new token...");
          return await postRequestWithToken(endpoint, body, isRetry: true);
        } else {
          print("❌ Token refresh failed - returning 401");
        }
      }

      return response;
    } catch (e) {
      print("🚨 POST Auth Error: $e");
      return Response(
        statusCode: 500,
        body: {"success": false, "message": e.toString()},
      );
    }
  }

  // ==================================================
  // PUT WITH TOKEN → AUTO REFRESH ON 401
  // ==================================================
  Future<Response> putRequestWithToken(
    String endpoint,
    Map<String, dynamic> body, {
    bool isRetry = false,
  }) async {
    final token = _storage.accessToken;

    print("➡️ PUT (Auth): ${httpClient.baseUrl}$endpoint");
    // print("🔑 Using Token: $token");

    try {
      final response = await put(
        endpoint,
        body,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == null) {
        print("❌ Status: NULL (Connection Error)");
        return const Response(
          statusCode: 503,
          statusText: 'Service Unavailable',
          body: {
            'success': false,
            'message': 'Connection failed. Server unreachable.',
          },
        );
      }

      print("✅ Status: ${response.statusCode}");
      // print("✅ Response: ${response.body}");

      // 🔄 Auto-refresh on 401 (only once)
      if (response.statusCode == 401 && !isRetry) {
        print("⚠️ 401 Unauthorized - Attempting token refresh...");
        bool refreshed = await refreshAccessToken();

        if (refreshed) {
          print("🔄 Retrying request with new token...");
          return await putRequestWithToken(endpoint, body, isRetry: true);
        } else {
          print("❌ Token refresh failed - returning 401");
        }
      }

      return response;
    } catch (e) {
      print("🚨 PUT Auth Error: $e");
      return Response(
        statusCode: 500,
        body: {"success": false, "message": e.toString()},
      );
    }
  }

  // ==================================================
  // PATCH WITH TOKEN → AUTO REFRESH ON 401
  // ==================================================
  Future<Response> patchRequestWithToken(
    String endpoint,
    Map<String, dynamic> body, {
    bool isRetry = false,
  }) async {
    final token = _storage.accessToken;

    print("➡️ PATCH (Auth): ${httpClient.baseUrl}$endpoint");
    // print("🔑 Using Token: $token");

    try {
      final response = await patch(
        endpoint,
        body,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == null) {
        print("❌ Status: NULL (Connection Error)");
        return const Response(
          statusCode: 503,
          statusText: 'Service Unavailable',
          body: {
            'success': false,
            'message': 'Connection failed. Server unreachable.',
          },
        );
      }

      print("✅ Status: ${response.statusCode}");
      // print("✅ Response: ${response.body}");

      // 🔄 Auto-refresh on 401 (only once)
      if (response.statusCode == 401 && !isRetry) {
        print("⚠️ 401 Unauthorized - Attempting token refresh...");
        bool refreshed = await refreshAccessToken();

        if (refreshed) {
          print("🔄 Retrying request with new token...");
          return await patchRequestWithToken(endpoint, body, isRetry: true);
        } else {
          print("❌ Token refresh failed - returning 401");
        }
      }

      return response;
    } catch (e) {
      print("🚨 PATCH Auth Error: $e");
      return Response(
        statusCode: 500,
        body: {"success": false, "message": e.toString()},
      );
    }
  }

  // ===========================
  // GET WITH TOKEN → AUTO REFRESH ON 401
  // ===========================
  Future<Response> getRequestWithToken(
    String endpoint, {
    bool isRetry = false, // Prevent infinite loops
  }) async {
    final token = _storage.accessToken;
    print("➡️ GET (Auth): ${httpClient.baseUrl}$endpoint");

    try {
      final response = await get(
        endpoint,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == null) {
        print("❌ Status: NULL (Connection Error)");
        return const Response(
          statusCode: 503,
          statusText: 'Service Unavailable',
          body: {
            'success': false,
            'message': 'Connection failed. Server unreachable.',
          },
        );
      }

      print("✅ Status: ${response.statusCode}");
      // print("✅ Response: ${response.body}");

      // 🔄 Auto-refresh on 401 (only once)
      if (response.statusCode == 401 && !isRetry) {
        print("⚠️ 401 Unauthorized - Attempting token refresh...");
        bool refreshed = await refreshAccessToken();

        if (refreshed) {
          print("🔄 Retrying request with new token...");
          return await getRequestWithToken(endpoint, isRetry: true);
        } else {
          print("❌ Token refresh failed - returning 401");
        }
      }

      return response;
    } catch (e) {
      print("🚨 GET Error: $e");
      return Response(
        statusCode: 500,
        body: {'success': false, 'message': 'Connection error: $e'},
      );
    }
  }

  // ===========================
  // TAX PRODUCT GROUPS
  // ===========================
  String getTaxProductGroups(
    String restaurantId, {
    int page = 1,
    int limit = 10,
  }) {
    return "${ApiConstant.apiBase}/tax-product-groups?page=$page&limit=$limit&restaurantId=$restaurantId";
  }
}
