import 'dart:io';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:objectbox/objectbox.dart';
import 'package:path_provider/path_provider.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/controller_setting.dart';
import '../objectbox.g.dart';

/// ✅ Database service for ObjectBox + GetX + GetStorage
class ServiceDb extends GetxService {
  Store? _store;

  /// ✅ Create the ObjectBox store instance
  Future<Store> createInstances() async {
    // Get app support directory (safe, private for app)
    final dir = await getApplicationSupportDirectory();

    // Create store inside /restaurant subfolder
    _store = Store(
      getObjectBoxModel(),
      directory: '${dir.path}/restaurant',
    );

    print('✅ ObjectBox store created at: ${dir.path}/restaurant');
    return _store!;
  }

  /// ✅ Get the existing store (ensure created)
  Store get store {
    if (_store == null || _store!.isClosed()) {
      throw Exception('❌ ObjectBox store not initialized. Call createInstances() first.');
    }
    return _store!;
  }

  /// ✅ Safely close ObjectBox store
  Future<void> closeStore() async {
    if (_store?.isClosed() == false) {
      _store?.close();
      print('🔒 ObjectBox store closed successfully.');
    }
  }

  /// ✅ Safely delete ObjectBox database AND reset counters
  Future<void> deleteDatabase() async {
    final dir = await getApplicationSupportDirectory();
    final dbPath = '${dir.path}/restaurant';
    final dbDir = Directory(dbPath);

    try {
      // 🔒 1. Close store before deleting
      if (_store?.isClosed() == false) {
        _store?.close();
        print('🗃️ Store closed before deletion.');
      }

      await Future.delayed(const Duration(milliseconds: 200));

      // 🗑️ 2. Delete the ObjectBox folder
      if (await dbDir.exists()) {
        await dbDir.delete(recursive: true);
        print('✅ ObjectBox database deleted successfully at $dbPath');
      } else {
        print('⚠️ Database directory not found at $dbPath');
      }

      // 🔄 3. Clear counters from GetStorage
      final box = GetStorage();
      await box.remove('orderNumber');
      await box.remove('kotNumber');
      await box.remove('serverFloorOrderNext');
      await box.remove('serverFloorKotNext');
      print('🧹 Cleared orderNumber and kotNumber from GetStorage.');

      // 🔁 4. Reload live ControllerSetting state if active
      if (Get.isRegistered<ControllerSetting>()) {
        final settingsController = Get.find<ControllerSetting>();
        settingsController.loadSettings(); // Reload from storage
        print('🔄 ControllerSetting state reloaded and reset.');
      }

    } catch (e) {
      print('❌ Failed to delete ObjectBox database: $e');
    }
  }
}
