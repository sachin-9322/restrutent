import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:objectbox/objectbox.dart';
import 'package:splash_screen_03/captain/login/auth_service.dart';
import 'package:splash_screen_03/repository/Base64.dart';
import 'package:splash_screen_03/screens/home/fragments/order/controller_ordetype.dart';
import 'package:splash_screen_03/screens/home/fragments/order/widget/app_windowListerner.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/raw_pritner_service.dart';
import 'package:window_manager/window_manager.dart';
import 'model/enity_day_report.dart';
import 'model/entity_bill.dart';
import 'model/entity_bill_food.dart';
import 'model/entity_cateogry_tax.dart';
import 'model/entity_expnaess.dart';
import 'model/entity_food.dart';
import 'model/entity_kitchen_department.dart';
import 'model/entity_menu.dart';
import 'model/entity_order_type.dart';
import 'model/entity_payment.dart';
import 'model/entity_printer.dart';
import 'model/entity_room_type.dart';
import 'model/entity_table.dart';
import 'model/entity_tax.dart';
import 'model/entity_user.dart';

import 'repository/day_repo.dart';

import 'kds/fragment/controller_kds.dart';
import 'screens/home/fragments/order/controller_order.dart';
import 'screens/home/fragments/setting/controller_setting.dart';
import 'screens/home/fragments/table_type/controller_table.dart';
import 'services/controller_server.dart';
import 'services/service_db.dart';

import 'screens/AppTranslations/translation.dart';
import 'screens/theme/app_theme.dart';
import 'utils/app_routes.dart';
import 'utils/route_reslover.dart';
import 'utils/sanbar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  final storageRepo = StorageRepository();
  // REQUIRED for Windows close button listener
  // await windowManager.ensureInitialized();

  // // Register window close prevention
  // windowManager.setPreventClose(true);

  // // Attach your listener
  // windowManager.addListener(AppWindowListener());

  final Store store = await ServiceDb().createInstances();
  Get.put(store.box<EntityUser>()); // user box first

  final authService = await Get.putAsync(
    () => AuthService().init(),
    permanent: true,
  );

  _registerOtherDependencies(store);
  await _startConditionalServer(authService);

  // Compute the route once
  final initialRoute = await RouteResolver.determineInitialRoute();

  runApp(MyApp(initialRoute: initialRoute));
}

/// Registers all other dependencies AFTER AuthService is initialized.
void _registerOtherDependencies(Store store) {
  // --- Register Remaining ObjectBox Boxes ---
  Get.put(store.box<EntityFood>());
  Get.put(store.box<EntityRoomType>());
  Get.put(store.box<EntityOrderType>());
  Get.put(store.box<EntityCategoryTax>());
  Get.put(store.box<EntityTable>());
  Get.put(store.box<EntityOrder>());
  Get.put(store.box<EntityTax>());
  Get.put(store.box<EntityKitchenDepartment>());
  Get.put(store.box<EntityMenu>());
  // Assuming these are correct from your original code
  // If they cause errors, ensure the models exist.
  Get.put(store.box<VendorEntity>());
  Get.put(store.box<ExpenseEntity>());
  Get.put(store.box<CategoryEntity>());
  Get.put(store.box<EntityPrinter>());
  Get.put(store.box<EntityDayReport>());
  Get.put(store.box<Payment>());
  Get.put(store.box<EntityOrderFood>());

  // --- Register Repositories ---
  Get.put(DayReportRepo(), permanent: true);
  Get.put(RawBtPrinterService(), permanent: true);

  // --- Register Controllers ---
  Get.put(ControllerTable(), permanent: true);
  Get.put(ControllerOrder(), permanent: true);
  Get.put(ControllerServer(), permanent: true);
  Get.put(KOTController(), permanent: true);
  Get.put(ControllerSetting(), permanent: true);

  Get.put(ControllerOrderType(), permanent: true);
}

/// Starts the TCP server IF the logged-in user is of type 'server'.
Future<void> _startConditionalServer(AuthService authService) async {
  if (authService.isLoggedIn &&
      authService.userType.toLowerCase() == 'server') {
    final controllerServer = Get.find<ControllerServer>();
    await controllerServer.startServer(tcpPort: 4040);
  }
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    final settingController = Get.find<ControllerSetting>();
    return GetMaterialApp(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'RHPOSS Restaurant App',
      translations: AppTranslations(),
      locale: settingController.currentLocale,
      fallbackLocale: const Locale('en', 'US'),
      getPages: AppRoutes.listPages,
      theme: AppThemes.darkTheme,
      darkTheme: AppThemes.lightTheme,
      themeMode: settingController.isDarkMode.value
          ? ThemeMode.dark
          : ThemeMode.light,
      initialRoute: AppRoutes.activityHome,
    );
  }
}

extension LocaleExtension on ControllerSetting {
  Locale get currentLocale {
    return languageList.firstWhere(
      (lang) => lang['name'] == language.value,
      orElse: () => languageList.first,
    )['locale'];
  }
}
