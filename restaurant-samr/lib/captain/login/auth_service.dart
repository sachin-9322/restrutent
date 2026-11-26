// lib/captain/login/auth_service.dart
import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:splash_screen_03/constant/api_constant.dart';
import 'package:splash_screen_03/model/entity_user.dart';
import 'package:splash_screen_03/objectbox.g.dart'; // Make sure this import is correct
import 'package:splash_screen_03/repository/Base64.dart';
import 'package:splash_screen_03/services/api_client.dart';
import 'package:splash_screen_03/utils/app_routes.dart';

class AuthService extends GetxService {
  final GetStorage _box = GetStorage();
  late final Box<EntityUser> _userBox;

  final Rx<EntityUser?> currentUser = Rx<EntityUser?>(null);

  bool get isLoggedIn => currentUser.value != null;

  String get restaurantName =>
      currentUser.value?.restaurantName ?? '[Restaurant Name Not Set]';
  String get address => currentUser.value?.address ?? '[Address Not Set]';
  String get userName => currentUser.value?.userName ?? 'Guest';
  String get userType => currentUser.value?.userType ?? 'Unknown';

  Future<AuthService> init() async {
    if (kDebugMode) print('[AuthService] Initializing...');
    // This assumes the Box<EntityUser> is already registered with GetX in main.dart
    _userBox = Get.find<Box<EntityUser>>();

    final userUuid = _box.read<String>('loggedInUserUuid');
    if (kDebugMode) print('[AuthService] Read UUID from storage: $userUuid');

    if (userUuid != null && userUuid.isNotEmpty) {
      if (kDebugMode)
        print('[AuthService] UUID found. Attempting to load user from DB...');
      _loadUserByUuid(userUuid);
    } else {
      if (kDebugMode)
        print('[AuthService] No UUID found. User is not logged in.');
    }
    return this;
  }

  void _loadUserByUuid(String uuid) {
    // It's good practice to handle potential empty UUIDs
    if (uuid.isEmpty) {
      currentUser.value = null;
      return;
    }
    final query = _userBox.query(EntityUser_.userUuid.equals(uuid)).build();
    final user = query.findFirst();
    query.close();

    if (kDebugMode) {
      print(
        '[AuthService] User search in DB complete. Found user: ${user?.userName ?? 'NONE'}',
      );
    }
    currentUser.value = user;
  }

  /// Logs in a user and persists their data for future sessions.
  void loginUser(EntityUser user) {
    if (kDebugMode)
      print(
        '[AuthService] Logging in user: ${user.userName}, UUID: ${user.userUuid}',
      );

    // ================= FIX: THE CRITICAL MISSING STEP =================
    // Persist the complete user object to the ObjectBox database.
    // This will insert the user if they don't exist, or update them if they do.
    _userBox.put(user);
    // =================================================================

    // The UUID is the only piece of information we need to persist in GetStorage
    // to identify the user on the next app launch.
    _box.write('loggedInUserUuid', user.userUuid);

    // Update the current session's user state.
    currentUser.value = user;
  }

  Future<void> logout() async {
    print("[AuthService] Logging out...");

    final storage = StorageRepository();
    final api = ApiClient();

    final sessionId = storage.sessionId;

    if (sessionId.isNotEmpty) {
      print("🔌 Calling Logout API with sessionId: $sessionId");

      final response = await api.postRequestWithToken(ApiConstant.logout, {
        "sessionId": sessionId,
      });

      print("Logout API Status: ${response.statusCode}");
      print("Logout API Body: ${response.body}");
    }

    // 🟢 Preserve shift-start-dialog flag
    final showDialog = storage.readBool(
      'showShiftDialogNextLogin',
      defaultValue: false,
    );

    // LOCAL CLEAN
    final id = currentUser.value?.userId;

    currentUser.value = null;

    storage.clearAll();

    // Restore flag
    storage.writeBool('showShiftDialogNextLogin', showDialog);

    if (id != null && id > 0) {
      _userBox.remove(id);
    }

    Get.offAllNamed(AppRoutes.login);

    Get.snackbar(
      "Logged Out",
      "You have been logged out successfully.",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Fetches the user profile from the API if not available locally.
  Future<void> fetchUserProfile() async {
    if (currentUser.value != null) return;

    final storage = StorageRepository();
    final restaurantId = storage.restaurantId;
    final userId = int.tryParse(storage.userId) ?? 0;

    if (restaurantId.isEmpty || userId == 0) {
      if (kDebugMode)
        print(
          '[AuthService] Missing restaurantId or userId. Cannot fetch profile.',
        );
      return;
    }

    if (kDebugMode) print('[AuthService] Fetching user profile for userId: $userId...');

    try {
      final apiClient = ApiClient();
      // We use the getUsers endpoint which returns a list of users for the restaurant
      final response = await apiClient.getRequestWithToken(ApiConstant.getUsers(restaurantId, limit: 100));

      if (response.statusCode == 200) {
        final data = response.body['data'];
        if (data is List) {
          final userJson = data.firstWhere(
            (u) => (int.tryParse(u['id']?.toString() ?? '0') ?? 0) == userId,
            orElse: () => null,
          );

          if (userJson != null) {
            final user = EntityUserMapper.fromJson(userJson);
            loginUser(user);
            if (kDebugMode)
              print('[AuthService] User profile fetched and updated.');
          } else {
            if (kDebugMode)
              print('[AuthService] User not found in the fetched list.');
          }
        }
      } else {
        if (kDebugMode)
          print(
            '[AuthService] Failed to fetch users. Status: ${response.statusCode}',
          );
      }
    } catch (e) {
      if (kDebugMode) print('[AuthService] Error fetching user profile: $e');
    }
  }
}
