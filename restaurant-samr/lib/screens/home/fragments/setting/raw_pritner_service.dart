import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:splash_screen_03/model/entity_printer.dart';
import 'package:splash_screen_03/objectbox.g.dart';

// Adjust this import to your actual path
import 'package:splash_screen_03/screens/home/fragments/setting/controller_setting.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/wifi_pritner.dart';

class BtPrinterDevice {
  final String name;
  final String mac;
  BtPrinterDevice({required this.name, required this.mac});
}

class RawBtPrinterService extends GetxService {
  final connected = false.obs;
  final deviceLabel = ''.obs;
  static List<BtPrinterDevice> cachedList = [];
  static DateTime? lastScanTime;
  Future<bool> quickCheckConnection() async {
    try {
      final status = await PrintBluetoothThermal.connectionStatus;
      return status == true;
    } catch (_) {
      return false;
    }
  }

  List<BtPrinterDevice> btList = [];

  Future<void> autoReconnect(String configType) async {
  try {
    // ✅ If already connected, do not reset state
    final currentStatus = await PrintBluetoothThermal.connectionStatus;
    if (connected.value && currentStatus == true) {
      debugPrint('ℹ️ [$configType] Printer already connected — skipping reconnect.');
      return;
    }

    final box = Get.find<Box<EntityPrinter>>();
    final printer = box
        .query(EntityPrinter_.configType.equals(configType))
        .build()
        .findFirst();

    if (printer == null) return;

    final mac = _macFromUrl(printer.printUrl);
    if (mac == null || mac.isEmpty) return;

    debugPrint('🔄 [$configType] Checking saved printer [$mac]...');

    // Try a silent connection check first
    final ok = await PrintBluetoothThermal.connectionStatus;
    if (ok == true) {
      connected.value = true;
      deviceLabel.value = 'BT • ${printer.printName}';
      debugPrint('✅ [$configType] Printer already connected.');
      return;
    }

    // Try reconnect
    final reconnected = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
    if (reconnected == true) {
      connected.value = true;
      deviceLabel.value = 'BT • ${printer.printName}';
      debugPrint('✅ [$configType] Auto-reconnected successfully.');
    } else {
      debugPrint('⚠️ [$configType] Auto-reconnect failed.');
    }
  } catch (e) {
    debugPrint('❌ [$configType] autoReconnect error: $e');
  }
}


  Future<bool> ensureConnected({int timeoutMs = 3000}) async {
    try {
      // ✅ Use your reactive variable safely
      if (connected.value) {
        debugPrint('ℹ️ [BT] Already connected.');
        return true;
      }

      // Try connecting to last saved BILL printer (as a default fallback)
      final box = Get.find<Box<EntityPrinter>>();
      final printer = box
          .query(EntityPrinter_.configType.equals('BILL'))
          .build()
          .findFirst();

      if (printer == null) {
        debugPrint('⚠️ [BT] No saved printer to reconnect.');
        return false;
      }

      final mac = _macFromUrl(printer.printUrl);
      if (mac == null || mac.isEmpty) {
        debugPrint('⚠️ [BT] Invalid MAC address.');
        return false;
      }

      debugPrint('🔹 [BT] Checking connection for [$mac]...');
      final status = await PrintBluetoothThermal.connectionStatus;
      if (status == true) {
        connected.value = true;
        deviceLabel.value = 'BT • ${printer.printName}';
        debugPrint('✅ [BT] Still connected.');
        return true;
      }

      // Try connecting within timeout
      debugPrint('🔄 [BT] Attempting reconnect to [$mac]...');
      final ok = await _connectWithTimeout(mac, timeoutMs: timeoutMs);
      connected.value = ok;
      return ok;
    } catch (e) {
      debugPrint('❌ [BT] ensureConnected error: $e');
      return false;
    }
  }

  /// Helper: Connect with timeout protection
  Future<bool> _connectWithTimeout(String mac, {int timeoutMs = 3000}) async {
    try {
      final result = await Future.any([
        PrintBluetoothThermal.connect(macPrinterAddress: mac),
        Future.delayed(Duration(milliseconds: timeoutMs), () => false),
      ]);

      if (result == true) {
        debugPrint('✅ [BT] Connected to $mac');
        return true;
      } else {
        debugPrint('⚠️ [BT] Connection timeout or failed for $mac');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [BT] Connect exception: $e');
      return false;
    }
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }

  Future<void> testPrintToBothPrinters() async {
    final RawBtPrinterService svc = Get.find<RawBtPrinterService>();

    try {
      debugPrint('🟦 [TEST] Starting test print to both printers...');

      debugPrint('➡️ [TEST] Connecting to KOT printer...');
      final kotConnected = await svc.connectByConfigType('KOT');
      if (kotConnected) {
        debugPrint('✅ [TEST] Connected to KOT printer.');
        await Future.delayed(const Duration(milliseconds: 300));
        await svc.testPrint(charsPerLine: 32);
        debugPrint('🖨️ [TEST] KOT printer test print done.');
      } else {
        debugPrint('⚠️ [TEST] Failed to connect KOT printer.');
      }

      await Future.delayed(const Duration(seconds: 1));

      debugPrint('➡️ [TEST] Connecting to BILL printer...');
      final billConnected = await svc.connectByConfigType('BILL');
      if (billConnected) {
        debugPrint('✅ [TEST] Connected to BILL printer.');
        await Future.delayed(const Duration(milliseconds: 300));
        await svc.testPrint(charsPerLine: 32);
        debugPrint('🖨️ [TEST] BILL printer test print done.');
      } else {
        debugPrint('⚠️ [TEST] Failed to connect BILL printer.');
      }

      debugPrint('🟩 [TEST] Completed test print for both printers.');
    } catch (e, st) {
      debugPrint('❌ [TEST] Error during test print: $e\n$st');
    } finally {
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  Future<void> printToSavedPrinter({
    required String configType,
    required List<int> bytes,
  }) async {
    try {
      final box = Get.find<Box<EntityPrinter>>();
      final printer = box
          .query(EntityPrinter_.configType.equals(configType))
          .build()
          .findFirst();

      if (printer == null) {
        debugPrint('⚠️ [$configType] No printer found.');
        return;
      }

      final mac = _macFromUrl(printer.printUrl);
      if (mac == null || mac.isEmpty) {
        debugPrint('⚠️ [$configType] Invalid MAC: ${printer.printUrl}');
        return;
      }

      debugPrint('🔹 [$configType] Preparing to print on [$mac]...');

      // 🔄 Always perform a safe reconnect before every print
      try {
        await PrintBluetoothThermal.disconnect;
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (_) {}

      final connectedOk = await PrintBluetoothThermal.connect(
        macPrinterAddress: mac,
      );
      if (!connectedOk) {
        debugPrint('❌ [$configType] Failed to reconnect printer [$mac]');
        connected.value = false;
        return;
      }

      connected.value = true;
      deviceLabel.value = 'BT • ${printer.printName}';
      debugPrint(
        '✅ [$configType] Connected successfully to ${printer.printName}',
      );

      // ✉️ Write bytes with retry protection
      try {
        await Future.delayed(const Duration(milliseconds: 150));
        await PrintBluetoothThermal.writeBytes(bytes);
        debugPrint('🖨️ [$configType] Print success.');
      } catch (e) {
        debugPrint('⚠️ [$configType] Write failed: $e');
        await Future.delayed(const Duration(milliseconds: 200));
        await PrintBluetoothThermal.connect(macPrinterAddress: mac);
        await Future.delayed(const Duration(milliseconds: 200));
        await PrintBluetoothThermal.writeBytes(bytes);
        debugPrint('🖨️ [$configType] Print retried successfully.');
      }

      // 🔚 Disconnect after short delay
      await Future.delayed(const Duration(milliseconds: 250));
      await PrintBluetoothThermal.disconnect;
      connected.value = false;
      deviceLabel.value = '';
      debugPrint('🔹 [$configType] Disconnected cleanly.');
    } catch (e, st) {
      debugPrint('❌ [$configType] Print error: $e\n$st');
      connected.value = false;
    }
  }

  Future<void> _requestBtPermissions() async {
    if (!Platform.isAndroid) return;

    final req = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ];
    await req.request();
  }

  Future<List<BtPrinterDevice>> scanBluetooth({bool force = false}) async {
    await _requestBtPermissions();

    // 🕒 Reuse cached list if it's recent (within 30 seconds)
    if (!force &&
        cachedList.isNotEmpty &&
        lastScanTime != null &&
        DateTime.now().difference(lastScanTime!) <
            const Duration(seconds: 30)) {
      debugPrint('♻️ Using cached Bluetooth list');
      return cachedList;
    }

    final isOn = await PrintBluetoothThermal.bluetoothEnabled;
    if (isOn != true) return [];

    final list = await PrintBluetoothThermal.pairedBluetooths;
    btList = (list as List)
        .map((e) {
          final name = _safeName(e);
          final mac = _safeMac(e);
          return BtPrinterDevice(name: name, mac: mac);
        })
        .where((d) => d.mac.isNotEmpty)
        .toList();

    // ✅ Cache the list
    cachedList = btList;
    lastScanTime = DateTime.now();

    debugPrint('🔹 Scanned and cached ${btList.length} devices');
    return btList;
  }

  String _safeName(dynamic b) {
    try {
      final v = (b as dynamic).name as String?;
      if (v != null && v.isNotEmpty) return v;
    } catch (_) {}
    try {
      final v = (b as dynamic)['name'] as String?;
      if (v != null && v.isNotEmpty) return v;
    } catch (_) {}
    return 'Unknown';
  }

  String _safeMac(dynamic b) {
    try {
      final v = (b as dynamic).macAddress as String?;
      if (v != null && v.isNotEmpty) return v;
    } catch (_) {}
    try {
      final v2 =
          (b as dynamic).macAdress as String?; // misspelling in some builds
      if (v2 != null && v2.isNotEmpty) return v2;
    } catch (_) {}
    try {
      final v3 = (b as dynamic).address as String?; // used by some forks
      if (v3 != null && v3.isNotEmpty) return v3;
    } catch (_) {}
    try {
      final v4 = (b as dynamic)['macAddress'] as String?;
      if (v4 != null && v4.isNotEmpty) return v4;
    } catch (_) {}
    try {
      final v5 = (b as dynamic)['macAdress'] as String?;
      if (v5 != null && v5.isNotEmpty) return v5;
    } catch (_) {}
    try {
      final v6 = (b as dynamic)['address'] as String?;
      if (v6 != null && v6.isNotEmpty) return v6;
    } catch (_) {}
    return '';
  }

  Future<bool> connectBluetooth(BtPrinterDevice d) async {
    await _requestBtPermissions();
    if (d.mac.isEmpty) return false;

    final ok = await PrintBluetoothThermal.connect(macPrinterAddress: d.mac);

    final success = ok == true;
    if (success) {
      connected.value = true;
      deviceLabel.value = 'BT • ${d.name}';
      _notifySetting(true);

      await Future.delayed(const Duration(milliseconds: 150));
    }
    return success;
  }

Future<bool> refreshConnectionStatus() async {
  try {
    final status = await PrintBluetoothThermal.connectionStatus;
    if (status == true) {
      connected.value = true;
    }
    // Only set false if explicitly disconnected (not during rebuilds)
    else if (!connected.value) {
      connected.value = false;
      deviceLabel.value = '';
    }
    _notifySetting(connected.value);
    return connected.value;
  } catch (_) {
    return connected.value;
  }
}


  Future<void> printRaw(List<int> bytes) async {
    if (!connected.value) return;
    try {
      await PrintBluetoothThermal.writeBytes(bytes);
    } catch (e) {}
  }

  Future<void> testPrint({int charsPerLine = 32}) async {
    final b = <int>[];
    b.addAll([0x1B, 0x40]); // ESC @ init
    b.addAll([0x1B, 0x61, 0x01]); // center
    b.addAll([0x1B, 0x45, 0x01]); // bold on
    b.addAll([0x1D, 0x21, 0x11]); // double W/H
    b.addAll('TEST PRINT'.codeUnits);
    b.add(0x0A);
    b.addAll([0x1D, 0x21, 0x00, 0x1B, 0x45, 0x00]); // normal, bold off
    b.addAll(List.filled(charsPerLine, 0x2D));
    b.add(0x0A);
    b.addAll([0x1B, 0x61, 0x00]); // left
    b.addAll('Hello from Flutter (RAW ESC/POS)'.codeUnits);
    b.add(0x0A);
    b.addAll('Line 2: sample content'.codeUnits);
    b.add(0x0A);
    b.add(0x0A);
    b.addAll([0x1B, 0x61, 0x01]); // center
    b.addAll('Thank you!'.codeUnits);
    b.add(0x0A);
    b.addAll(List.filled(charsPerLine, 0x2D));
    b.add(0x0A);
    b.addAll([0x0A, 0x0A, 0x0A]);
    b.addAll([0x1D, 0x56, 0x00]);
    await printRaw(b);
  }

  Future<void> disconnect() async {
    try {
      await PrintBluetoothThermal.disconnect;
    } catch (_) {}
    connected.value = false;
    deviceLabel.value = '';
    _notifySetting(false);
  }

  void _notifySetting(bool status) {
    if (Get.isRegistered<ControllerSetting>()) {
      Get.find<ControllerSetting>().updatePrinterStatus(status);
    }
  }
}

class PrintItem {
  final String name;
  final num qty;
  final num price; // unit price
  const PrintItem({required this.name, this.qty = 1, this.price = 0});
}

int _cplFromSize(String? size) {
  switch ((size ?? '58').trim()) {
    case '80':
      return 48;
    case '100':
      return 64;
    case '58':
    default:
      return 32;
  }
}

String? _macFromUrl(String? url) {
  if (url == null) return null;
  final re = RegExp(r'([0-9A-Fa-f]{2}[:\-]){5}[0-9A-Fa-f]{2}');
  final m = re.firstMatch(url);
  if (m == null) return null;
  return m.group(0)!.replaceAll('-', ':').toUpperCase();
}
