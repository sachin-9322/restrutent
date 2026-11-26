import 'package:get_storage/get_storage.dart';

class Session {
  static String userType() {
    try {
      final box = GetStorage();
      final raw = (box.read('userType') as String? ?? '').trim().toLowerCase();
      if (raw.isEmpty) return 'captain';
      switch (raw) {
        case 'server':
        case 'pos':
        case 'captain':
        case 'kds':
          return raw;
        default:
          return raw; // allow custom roles if you add more later
      }
    } catch (_) {
      return 'captain';
    }
  }

  static String origin() => userType();

  static void setUserType(String raw) {
    try {
      final box = GetStorage();
      box.write('userType', raw.trim().toLowerCase());
    } catch (_) {}
  }
}