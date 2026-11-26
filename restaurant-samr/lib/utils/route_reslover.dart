import 'package:get/get.dart';
import 'package:splash_screen_03/captain/login/auth_service.dart';
import 'package:splash_screen_03/repository/Base64.dart';
import 'package:splash_screen_03/services/auth_api.dart';
import 'package:splash_screen_03/utils/app_routes.dart';

class RouteResolver {
  /// Determines the initial route (login or specific home screen)
  static Future<String> determineInitialRoute() async {
    final storage = StorageRepository();
    final authService = Get.find<AuthService>();
    final authApi = Get.put(AuthApi(), permanent: true);

    print("🧭 RouteResolver → Checking stored session...");

    final username = storage.username;
    final password = storage.password;
    final token = storage.accessToken;

    // ============================================
    // 1️⃣ Stored Credentials (Online Session)
    // ============================================
    if (username.isNotEmpty && password.isNotEmpty && token.isNotEmpty) {
      print("🧠 Stored credentials found → validating token...");

      final reloginOk = await authApi.autoReLoginIfExpired();

      if (reloginOk) {
        print("✅ Session checked → Selecting correct home screen...");

        return _resolveRouteByUserType(storage.userType);
      } else {
        print("⚠️ Auto re-login failed → Redirect to Login");
        return AppRoutes.login;
      }
    }

    // ============================================
    // 2️⃣ Local User (Offline Mode)
    // ============================================
    if (authService.isLoggedIn) {
      print("✅ Local offline user found → Routing by local userType...");

      return _resolveRouteByUserType(authService.currentUser.value?.userType?? '');
    }

    // No session → go to login
    print("➡️ No session found → Go to Login");
    return AppRoutes.login;
  }

  /// Select home screen based on userType
  static String _resolveRouteByUserType(String rawType) {
    final type = rawType.toLowerCase().trim();

    print("🎭 UserType Detected → $type");

    switch (type) {
      case "brand_admin":
      case "server":
      case "admin":
      case "pos":
        print("🏠 Routing → ActivityHome");
        return AppRoutes.activityHome;

      case "captain":
        print("🧑‍🍳 Routing → ActivityCaptainHome");
        return AppRoutes.captainHome;

      case "kds":
        print("🍽 Routing → ActivityKDSHome");
        return AppRoutes.activityHomed;

      default:
        print("❓ Unknown UserType → route to Login");
        return AppRoutes.login;
    }
  }
}
