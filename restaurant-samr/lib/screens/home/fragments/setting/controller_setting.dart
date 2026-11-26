import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:printing/printing.dart';
import 'package:splash_screen_03/model/entity_order_type.dart';
import 'package:splash_screen_03/model/entity_printer.dart';
import 'package:splash_screen_03/model/enum_printer_size.dart';
import 'package:splash_screen_03/objectbox.g.dart';
import 'package:splash_screen_03/services/api_client.dart';
import 'package:splash_screen_03/constant/api_constant.dart';
import 'package:splash_screen_03/repository/Base64.dart';

class ControllerSetting extends GetxController {
  final formKey = GlobalKey<FormState>();
  final box = GetStorage();

  late TextEditingController textControllerUserType;
  late TextEditingController textControllerOrderType;
  late TextEditingController textEditingControllerConfigType;

  var orderTypesList = <EntityOrderType>[].obs;
  var printerSystemList = <EntityPrinter>[].obs;
  var kotPrinterDatabaseList = <EntityPrinter>[].obs;
  var billPrinterDatabaseList = <EntityPrinter>[].obs;
  DateTime _combineDateAndTime(DateTime date, TimeOfDay tod) {
    return DateTime(date.year, date.month, date.day, tod.hour, tod.minute);
  }

  var sizes = <String>["58", "80", "100"].obs;

  Box<EntityPrinter> printerBox = Get.find();

  var selectedPrinter = Rxn<EntityPrinter>();
  final selectedSizeEnum = Rxn<EnumPrinterSize>();
  RxInt copies = 1.obs;
  DateTime getNextResetDate(String type, DateTime from) {
    final tod = startDayTime.value;
    // Make sure "from" is aligned to start-of-day boundary time
    final anchor = _combineDateAndTime(from, tod);

    switch (type) {
      case "Daily":
        return anchor.add(const Duration(days: 1));
      case "Weekly":
        return anchor.add(const Duration(days: 7));
      case "Monthly":
        return DateTime(
          anchor.year,
          anchor.month + 1,
          anchor.day,
          tod.hour,
          tod.minute,
        );
      case "Yearly":
        return DateTime(
          anchor.year + 1,
          anchor.month,
          anchor.day,
          tod.hour,
          tod.minute,
        );
      default:
        return anchor.add(const Duration(days: 1));
    }
  }

  void bumpCountersToAtLeast({int? nextOrderNumber, int? nextKotNumber}) {
    bool changed = false;

    // Order number bump
    if (nextOrderNumber != null && nextOrderNumber > 0) {
      final current = orderNumber.value;
      if (nextOrderNumber > current) {
        orderNumber.value = nextOrderNumber;
        box.write('orderNumber', orderNumber.value);
        changed = true;
      }

      final existingFloor = (box.read('serverFloorOrderNext') as int?) ?? 1;
      final newFloor = (nextOrderNumber > existingFloor)
          ? nextOrderNumber
          : existingFloor;
      if (newFloor != existingFloor) {
        box.write('serverFloorOrderNext', newFloor);
      }
    }

    // KOT number bump
    if (nextKotNumber != null && nextKotNumber > 0) {
      final currentK = kotNumber.value;
      if (nextKotNumber > currentK) {
        kotNumber.value = nextKotNumber;
        box.write('kotNumber', kotNumber.value);
        changed = true;
      }

      final existingFloorK = (box.read('serverFloorKotNext') as int?) ?? 1;
      final newFloorK = (nextKotNumber > existingFloorK)
          ? nextKotNumber
          : existingFloorK;
      if (newFloorK != existingFloorK) {
        box.write('serverFloorKotNext', newFloorK);
      }
    }

    if (changed) {
      saveSettings();
      debugPrint(
        '📌 Counters bumped to at least server -> order=${orderNumber.value}, kot=${kotNumber.value}',
      );
    }
  }

  /// ----------------------
  /// Dark mode
  /// ----------------------
  var isDarkMode = false.obs;

  /// ----------------------
  /// Country
  /// ----------------------
  var country = "United Arab Emirates".obs;
  final List<String> countryList = [
    "India",
    "United Arab Emirates",
    "USA",
    "Saudi Arabia",
    "Qatar",
    "Kuwait",
  ];
  final isPrinterConnected = true.obs; // Default to true or false

  // Example method to update status
  void updatePrinterStatus(bool isConnected) {
    isPrinterConnected.value = isConnected;
  }

  /// ----------------------
  /// Timezone
  /// ----------------------
  var timezone = "Asia/Dubai".obs;
  final List<String> timezoneList = [
    "Asia/Dubai",
    "Asia/Kolkata",
    "America/New_York",
    "Europe/London",
    "Asia/Riyadh",
    "Asia/Doha",
  ];

  /// ----------------------
  /// Start and close time
  /// ----------------------
  var startDayTime = TimeOfDay(hour: 4, minute: 0).obs;
  var closeDayTime = TimeOfDay(hour: 22, minute: 39).obs;

  /// ----------------------
  /// Reset options
  /// ----------------------
  var resetBillType = "Daily".obs;
  var resetKotType = "Yearly".obs;
  final List<String> resetBillOptions = [
    "Daily",
    "Weekly",
    "Monthly",
    "Yearly",
  ];
  final List<String> resetKotOptions = ["Daily", "Weekly", "Monthly", "Yearly"];

  /// ----------------------
  /// Currency dropdown
  /// ----------------------
  var currency = "AED - د.إ".obs;
  final List<String> currencyList = [
    "USD - \$",
    "INR - ₹",
    "AED - د.إ",
    "SAR - ﷼",
    "QAR - ر.ق",
  ];
  // Helpers derived from `currency` ("AED - د.إ")
  String get currCode {
    final s = currency.value;
    final i = s.indexOf(' - ');
    return i == -1 ? s.trim() : s.substring(0, i).trim();
  }

  String get currSymbol {
    final s = currency.value;
    final i = s.indexOf(' - ');
    return i == -1 ? s.trim() : s.substring(i + 3).trim();
  }

  String get currLocale {
    switch (currCode) {
      case 'INR':
        return 'en_IN';
      case 'AED':
        return 'en_AE';
      case 'SAR':
        return 'en_SA';
      case 'QAR':
        return 'en_QA';
      case 'USD':
        return 'en_US';
      default:
        return 'en_US';
    }
  }

  String get subunitLabel {
    switch (currCode) {
      case 'AED':
        return 'fils';
      case 'INR':
        return 'paise';
      case 'SAR':
        return 'halala';
      case 'QAR':
        return 'dirham'; // subunit of QAR = dirham
      case 'USD':
      default:
        return '¢';
    }
  }

  // Optional: default denom values per currency (if you also want denoms to switch)
  List<double> get denomValues {
    switch (currCode) {
      case 'INR':
        return [2000, 500, 200, 100, 50, 20, 10, 5, 2, 1, 0.5];
      case 'AED':
        return [1000, 500, 200, 100, 50, 20, 10, 5, 1, 0.5];
      case 'SAR':
        return [500, 200, 100, 50, 20, 10, 5, 1, 0.5];
      case 'QAR':
        return [500, 100, 50, 10, 5, 1, 0.5];
      case 'USD':
      default:
        return [100, 50, 20, 10, 5, 2, 1, 0.25, 0.10, 0.05, 0.01];
    }
  }

  /// ----------------------
  /// Bill and KOT numbers
  /// ----------------------
  var orderNumber = 1.obs;
  var kotNumber = 1.obs;

  /// ----------------------
  /// Next reset dates
  /// ----------------------
  var nextResetBillDate = DateTime.now().obs;
  var nextResetKotDate = DateTime.now().obs;

  final bool _isAdvancing = false; // guard for atomic increments
  // Show "bill actions" (preview/save/settle) on table cards
  final billActionsOnTableEnabled = false.obs; // default off

  bool get showBillIconsOnTable => billActionsOnTableEnabled.value;

  void setShowBillIconsOnTable(bool v) {
    billActionsOnTableEnabled.value = v;
    saveSettings();
  }

  /// ----------------------
  /// Order types
  /// ----------------------
  final RxBool saveOrderTypeEnabled = false.obs;
  final RxString defaultOrderType = "Quick Bill".obs;
  final List<String> orderTypes = [
    "Quick Bill",
    "Dine-In",
    "PickUp",
    "Delivery",
  ];

  /// ----------------------
  /// Language
  /// ----------------------
  var language = "English".obs;
  final List<Map<String, dynamic>> languageList = [
    {"name": "English", "locale": const Locale('en', 'US')},
    {"name": "हिन्दी", "locale": const Locale('hi', 'IN')},
    {"name": "العربية", "locale": const Locale('ar', 'AE')},
  ];
  @override
  void onInit() {
    super.onInit();
    loadSettings();
    saveSystemPrinters();
    fetchKotPrinterFromDatabase();
    fetchBillPrinterFromDatabase();

    textControllerUserType = TextEditingController();
    textControllerOrderType = TextEditingController();
    textEditingControllerConfigType = TextEditingController();

    // language/dark mode application...
    final savedLang = box.read('language');
    if (savedLang is String && savedLang.isNotEmpty) {
      language.value = savedLang;
      final langMap = languageList.firstWhere(
        (l) => l['name'] == savedLang,
        orElse: () => languageList.first,
      );
      Get.updateLocale(langMap['locale']);
    }
    final darkModeSaved = box.read('darkMode');
    if (darkModeSaved is bool) isDarkMode.value = darkModeSaved;

    // 🔥 FIX: Check for reset IMMEDIATELY upon load.
    // If we passed the reset time while the app was closed, this will trigger the reset now.
    resetBillIfNeeded();
    resetKotIfNeeded();

    // If user changes reset type or Start Day Time, reseed the next reset dates
    ever<String>(resetBillType, (_) {
      nextResetBillDate.value = _firstNextResetAfterNow(resetBillType.value);
      saveSettings();
    });
    ever<String>(resetKotType, (_) {
      nextResetKotDate.value = _firstNextResetAfterNow(resetKotType.value);
      saveSettings();
    });
    ever<TimeOfDay>(startDayTime, (_) {
      // If Start Day Time shifts, re-anchor both to the next correct boundary
      nextResetBillDate.value = _firstNextResetAfterNow(resetBillType.value);
      nextResetKotDate.value = _firstNextResetAfterNow(resetKotType.value);
      saveSettings();
    });
  }

  //Here we are fetching printer form system drivers
  Future<void> saveSystemPrinters() async {
    try {
      final List<Printer> printers = await Printing.listPrinters();

      // printerBox.removeAll();

      for (final printer in printers) {
        /*String url = "Unknown";
        if (printer.url.startsWith("usb")) {
          url = "USB";
        } else if (printer.url.startsWith("network")) {
          url = "Network";
        } else if (printer.url.startsWith("bluetooth")) {
          url = "Bluetooth";
        }*/ //url type
        debugPrint("Printer details: ${json.encode(printer.toMap())}");

        final entity = EntityPrinter(
          printName: printer.name,
          printModel: printer.model,
          printUrl: printer.url,
          printIsAvailable: printer.isAvailable,
          printComment: printer.comment,
          printDefault: printer.isDefault,
          printLocation: printer.location,
          //comment ,location,model,isAvailable,isDefault,isLocal,
        );
        printerSystemList.add(entity);
        /*final jsonString = jsonEncode(entity.toJson());
        debugPrint("Your Printers Json Data $jsonString");*/
      }
    } catch (e) {
      debugPrint("Error Fetching printers: $e");
      // Get.snackbar(
      //   "Error",
      //   "Failed to Fetch printer list",
      //   snackPosition: SnackPosition.BOTTOM,
      // );
    }
  }

  void saveAllPrinterDetails() {
    if (selectedPrinter.value == null) return; // must select printer

    final fullPrinter = selectedPrinter.value!;

    final printer = EntityPrinter(
      printName: fullPrinter.printName,
      printModel: fullPrinter.printModel,
      printUrl: fullPrinter.printUrl,
      printIsAvailable: fullPrinter.printIsAvailable,
      printComment: fullPrinter.printComment,
      printDefault: fullPrinter.printDefault,
      printLocation: fullPrinter.printLocation,
      printerSize: selectedSizeEnum.value?.name,
      source: textControllerUserType.text,
      orderType: textControllerOrderType.text,
      noOfCop: copies.value,
      configType: textEditingControllerConfigType.text,
      createdOn: DateTime.now().toIso8601String(),
      createdBy: "System",
      printerUuid: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    printerBox.put(printer);

    textEditingControllerConfigType.text = "";
    textControllerOrderType.text = "";
    textControllerUserType.text = "";
    copies.value = 1;
    selectedSizeEnum.value = null;
    selectedPrinter.value = null;
    debugPrint("Printer detail insert successfully at index ${printer.id}");
    fetchKotPrinterFromDatabase();
    fetchBillPrinterFromDatabase();
  }

  void fetchKotPrinterFromDatabase() {
    final query = printerBox
        .query(EntityPrinter_.configType.equals('KOT'))
        .build();
    final list = query.find();

    kotPrinterDatabaseList.value = list;

    for (var printer in list) {
      debugPrint("kotPrinterDatabaseList: ${json.encode(printer.toMap())}");
    }

    query.close();
  }

  void fetchBillPrinterFromDatabase() {
    final query = printerBox
        .query(EntityPrinter_.configType.equals('BILL'))
        .build();
    final list = query.find();

    billPrinterDatabaseList.value = list;

    query.close();
  }

  void removePrinterAtIndex(EntityPrinter printer) {
    final entity = printerBox.get(printer.id);

    if (entity != null) {
      printerBox.remove(entity.id);
      debugPrint("Removed printer: ${printer.printName}");
    }

    if (printer.configType == "KOT") {
      fetchKotPrinterFromDatabase();
    } else {
      fetchBillPrinterFromDatabase();
    }
  }

  void updatePrinter(EntityPrinter oldPrinter) {
    final updated = EntityPrinter(
      id: oldPrinter.id,
      configType: textEditingControllerConfigType.text,
      printName: selectedPrinter.value?.printName,
      printUrl: selectedPrinter.value?.printUrl,
      source: textControllerUserType.text,
      orderType: textControllerOrderType.text,
      printerSize: selectedSizeEnum.value?.name,
      noOfCop: copies.value,
    );

    printerBox.put(updated); // updates record if ID exists
    fetchKotPrinterFromDatabase(); // refresh list
    fetchBillPrinterFromDatabase();
    Get.snackbar(
      "Success",
      "Printer updated successfully",
      snackPosition: SnackPosition.BOTTOM,
    );
  }
  // In your ControllerSetting...

  /// ----------------------
  /// Load saved settings
  /// ----------------------
  void loadSettings() {
    final bn = box.read('orderNumber'); // This will be null after deletion
    if (bn is int) {
      orderNumber.value = bn;
    } else if (bn is String) {
      orderNumber.value = int.tryParse(bn) ?? 1;
    }
    final rawShowIcons = box.read('billActionsOnTableEnabled');
    if (rawShowIcons is bool) {
      billActionsOnTableEnabled.value = rawShowIcons;
    } else if (rawShowIcons is String) {
      billActionsOnTableEnabled.value = rawShowIcons.toLowerCase() == 'true';
    }

    final c = box.read('country');
    if (c is String && c.isNotEmpty) country.value = c;

    final tz = box.read('timezone');
    if (tz is String && tz.isNotEmpty) timezone.value = tz;

    final startHour = box.read('startHour');
    final startMinute = box.read('startMinute');
    if (startHour is int && startMinute is int) {
      startDayTime.value = TimeOfDay(hour: startHour, minute: startMinute);
    }

    final closeHour = box.read('closeHour');
    final closeMinute = box.read('closeMinute');
    if (closeHour is int && closeMinute is int) {
      closeDayTime.value = TimeOfDay(hour: closeHour, minute: closeMinute);
    }

    final rbt = box.read('resetBillType');
    if (rbt is String && rbt.isNotEmpty) resetBillType.value = rbt;

    final rkt = box.read('resetKotType');
    if (rkt is String && rkt.isNotEmpty) resetKotType.value = rkt;

    final curr = box.read('currency');
    if (curr is String && curr.isNotEmpty) currency.value = curr;

    if (bn is int)
      orderNumber.value = bn;
    else if (bn is String)
      orderNumber.value = int.tryParse(bn) ?? 1;

    final kk = box.read('kotNumber');
    if (kk is int)
      kotNumber.value = kk;
    else if (kk is String)
      kotNumber.value = int.tryParse(kk) ?? 1;

    final nrbd = box.read('nextResetBillDate');
    if (nrbd is String) {
      try {
        nextResetBillDate.value = DateTime.parse(nrbd);
      } catch (_) {}
    }

    final nrkd = box.read('nextResetKotDate');
    if (nrkd is String) {
      try {
        nextResetKotDate.value = DateTime.parse(nrkd);
      } catch (_) {}
    }

    final savedEnabled = box.read('saveOrderTypeEnabled');
    if (savedEnabled is bool)
      saveOrderTypeEnabled.value = savedEnabled;
    else if (savedEnabled is String)
      saveOrderTypeEnabled.value = savedEnabled.toLowerCase() == 'true';

    final savedDefaultOrderType = box.read('defaultOrderType');
    if (savedDefaultOrderType is String && savedDefaultOrderType.isNotEmpty) {
      defaultOrderType.value = orderTypes.contains(savedDefaultOrderType)
          ? savedDefaultOrderType
          : "Dine-In";
    }
  }

  /// ----------------------
  /// Save settings
  /// ----------------------
  void saveSettings() {
    box.write(
      'billActionsOnTableEnabled',
      billActionsOnTableEnabled.value,
    ); // ⬅️ add this

    box.write('country', country.value);
    box.write('timezone', timezone.value);
    box.write('startHour', startDayTime.value.hour);
    box.write('startMinute', startDayTime.value.minute);
    box.write('closeHour', closeDayTime.value.hour);
    box.write('closeMinute', closeDayTime.value.minute);
    box.write('resetBillType', resetBillType.value);
    box.write('resetKotType', resetKotType.value);
    box.write('currency', currency.value);
    box.write('orderNumber', orderNumber.value);
    box.write('kotNumber', kotNumber.value);
    box.write('nextResetBillDate', nextResetBillDate.value.toIso8601String());
    box.write('nextResetKotDate', nextResetKotDate.value.toIso8601String());
    box.write('saveOrderTypeEnabled', saveOrderTypeEnabled.value);
    box.write('defaultOrderType', defaultOrderType.value);
    box.write('language', language.value);
    box.write('darkMode', isDarkMode.value);
  }

  /// ----------------------
  /// Language
  /// ----------------------
  void setLanguage(String langName) {
    language.value = langName;
    final langMap = languageList.firstWhere(
      (l) => l['name'] == langName,
      orElse: () => languageList.first,
    );
    Get.updateLocale(langMap['locale']);
    saveSettings();
  }

  /// ----------------------
  /// Dark mode toggle
  /// ----------------------
  void toggleDarkMode(bool value) {
    isDarkMode.value = value;
    saveSettings();
  }

  void resetBillIfNeeded() {
    final now = DateTime.now();
    var next = nextResetBillDate.value;
    bool didAdvance = false;

    while (!now.isBefore(next)) {
      next = getNextResetDate(resetBillType.value, next);
      didAdvance = true;
    }

    if (didAdvance) {
      // Start from server floor (or 1 if unknown)
      orderNumber.value = serverFloorOrderNext;
      nextResetBillDate.value = next;
      saveSettings();
    }
  }

  void resetKotIfNeeded() {
    final now = DateTime.now();
    var next = nextResetKotDate.value;
    bool didAdvance = false;

    while (!now.isBefore(next)) {
      next = getNextResetDate(resetKotType.value, next);
      didAdvance = true;
    }

    if (didAdvance) {
      kotNumber.value = serverFloorKotNext;
      nextResetKotDate.value = next;
      saveSettings();
    }
  }

  DateTime _firstNextResetAfterNow(String type) {
    final now = DateTime.now();
    var next = _combineDateAndTime(now, startDayTime.value);
    // If we are already at/after today’s boundary, move to the next period until it’s in the future
    while (!now.isBefore(next)) {
      next = getNextResetDate(type, next);
    }
    return next;
  }

  bool _advancingBill = false;
  bool _advancingKot = false;

  Future<int> acquireNextorderNumber() async {
    resetBillIfNeeded();

    // Make sure we never go below server's floor
    if (orderNumber.value < serverFloorOrderNext) {
      orderNumber.value = serverFloorOrderNext;
      box.write('orderNumber', orderNumber.value);
    }

    while (_advancingBill) {
      await Future.delayed(const Duration(milliseconds: 30));
    }
    _advancingBill = true;
    try {
      final current = orderNumber.value; // next to give
      orderNumber.value = current + 1; // advance
      await box.write('orderNumber', orderNumber.value);
      return current;
    } finally {
      _advancingBill = false;
    }
  }

  int get serverFloorOrderNext =>
      (box.read('serverFloorOrderNext') as int?) ?? 1;
  int get serverFloorKotNext => (box.read('serverFloorKotNext') as int?) ?? 1;
  Future<int> acquireNextKotNumber() async {
    resetKotIfNeeded();

    if (kotNumber.value < serverFloorKotNext) {
      kotNumber.value = serverFloorKotNext;
      box.write('kotNumber', kotNumber.value);
    }

    while (_advancingKot) {
      await Future.delayed(const Duration(milliseconds: 30));
    }
    _advancingKot = true;
    try {
      final current = kotNumber.value; // next to give
      kotNumber.value = current + 1; // advance
      await box.write('kotNumber', kotNumber.value);
      return current;
    } finally {
      _advancingKot = false;
    }
  }

  void showSnackBar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      borderRadius: 12,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      maxWidth: 300,
    );
  }

  Future<void> updateRestaurantCountersOnServer() async {
    try {
      final storage = StorageRepository();
      final restId = storage.restaurantId;
      if (restId.isEmpty) return;

      final currentBillCounter = orderNumber.value;
      final currentKotCounter = kotNumber.value;

      // Prepare body
      final Map<String, dynamic> body = {
        "billCounter": currentBillCounter,
        "kotCounter": currentKotCounter,
        "billPrefix": "BILL-", // Default
        "kotPrefix": "KOT-", // Default
      };

      // Extract prefixes if available in stored JSON
      try {
        if (storage.restaurant.isNotEmpty) {
          final restData = jsonDecode(storage.restaurant);
          if (restData['billPrefix'] != null) {
            body['billPrefix'] = restData['billPrefix'];
          }
          if (restData['kotPrefix'] != null) {
            body['kotPrefix'] = restData['kotPrefix'];
          }
        }
      } catch (_) {}

      debugPrint("📤 Patching Restaurant: $body");

      final api = ApiClient();
      final resp = await api.patchRequestWithToken(
        "${ApiConstant.restaurantById}/$restId",
        body,
      );

      if (resp.statusCode == 200 && resp.body?['success'] == true) {
        debugPrint(
          "✅ Restaurant counters updated on server: Bill=$currentBillCounter, KOT=$currentKotCounter",
        );
      } else {
        debugPrint("⚠️ Failed to update counters on server: ${resp.body}");
      }
    } catch (e) {
      debugPrint("❌ Error updating counters on server: $e");
    }
  }
}
