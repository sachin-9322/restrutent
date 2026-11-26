import 'dart:convert';
import 'package:get/get.dart';

import 'package:splash_screen_03/repository/Base64.dart';
import 'package:splash_screen_03/services/api_client.dart';

class AuthApi extends GetxService {
  final ApiClient _api = ApiClient();
  final StorageRepository _storage = StorageRepository();

  bool isTokenExpired(String token) {
    if (token.isEmpty) return true;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = parts[1];
      final decoded = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(payload))),
      );

      final exp = decoded['exp'];
      if (exp == null) return true;

      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expiry);
    } catch (e) {
      print("⚠️ Token decode failed: $e");
      return true;
    }
  }

  Future<bool> autoReLoginIfExpired() async {
    final token = _storage.accessToken;

    if (!isTokenExpired(token)) {
      print("✅ Token still valid — no re-login needed");
      return true;
    }

    print("⚠️ Access token expired — attempting to refresh...");

    // 1️⃣ Try Refresh Token First
    final refreshSuccess = await _api.refreshAccessToken();
    if (refreshSuccess) {
      print("✅ Token refreshed successfully via AuthApi");
      return true;
    }

    print("❌ Refresh failed — User must log in manually");
    return false;
  }
}
