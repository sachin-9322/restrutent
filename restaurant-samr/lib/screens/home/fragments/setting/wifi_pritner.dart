// ===== Required imports =====
// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import 'package:splash_screen_03/captain/login/auth_service.dart';
import 'package:splash_screen_03/model/entity_bill.dart';
import 'package:splash_screen_03/model/entity_kot.dart'; // <-- for KotGroup
import 'package:splash_screen_03/model/entity_printer.dart';
import 'package:splash_screen_03/model/model_restaurant.dart';
import 'package:splash_screen_03/objectbox.g.dart';
import 'package:splash_screen_03/screens/home/fragments/order/controller_order.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/controller_setting.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/raw_pritner_service.dart';

// ===== Small helpers =====
extension _Ascii on String {
  bool get isAscii => RegExp(r'^[\x00-\x7F]*$').hasMatch(this);
}

List<int> _escInit() => [0x1B, 0x40];
List<int> _lf([int n = 1]) => List.filled(n, 0x0A);
List<int> _align(int n) => [0x1B, 0x61, n]; // 0 left, 1 center, 2 right
List<int> _bold(bool on) => [0x1B, 0x45, on ? 0x01 : 0x00];
List<int> _size(int n) => [0x1D, 0x21, n]; // 0x00 normal, 0x11 double W/H
List<int> _cutFull() => [0x1D, 0x56, 0x00];
List<int> _textLn(String s) => [...s.codeUnits, 0x0A];
List<int> _hr(int cpl) => [...List<int>.filled(cpl, 0x2D), 0x0A];
List<int> _pulseDrawer({int pin = 0, int onMs = 120, int offMs = 240}) {
  final t1 = (onMs / 2).clamp(0, 255).round(); // ESC p m t1 t2 (2ms units)
  final t2 = (offMs / 2).clamp(0, 255).round();
  return [0x1B, 0x70, pin, t1, t2];
}

// CPL mapping
int _cplFromSize(String? size) {
  switch ((size ?? '58').trim()) {
    case '80': return 48;
    case '100': return 64;
    case '58':
    default: return 32;
  }
}

// Extract mac from url
String? _macFromUrl(String? url) {
  if (url == null) return null;
  final re = RegExp(r'([0-9A-Fa-f]{2}[:\-]){5}[0-9A-Fa-f]{2}');
  final m = re.firstMatch(url);
  if (m == null) return null;
  return m.group(0)!.replaceAll('-', ':').toUpperCase();
}

// Simple align helpers
String _lr(String left, String right, int cpl) {
  left = left.trim();
  right = right.trim();
  final spaces = cpl - left.length - right.length;
  if (spaces >= 1) return left + ' ' * spaces + right;
  return '$left\n$right';
}

List<String> _wrap(String text, int max) {
  final out = <String>[];
  var s = text.trim();
  while (s.length > max) {
    out.add(s.substring(0, max));
    s = s.substring(max);
  }
  if (s.isNotEmpty) out.add(s);
  return out;
}

// 4-column row (Name | Qty | Rate | Amt)
List<String> _row4(String name, String qty, String rate, String amt, int cpl) {
  final wQty = 4, wRate = 8, wAmt = 8;
  final wName = cpl - (wQty + wRate + wAmt + 3);
  final lines = _wrap(name, wName);

  final out = <String>[];
  for (int i = 0; i < lines.length; i++) {
    final isLast = i == lines.length - 1;
    final nm = lines[i].padRight(wName);
    if (!isLast) {
      out.add(nm);
    } else {
      out.add(
        nm +
        ' ' + qty.padLeft(wQty) +
        ' ' + rate.padLeft(wRate) +
        ' ' + amt.padLeft(wAmt)
      );
    }
  }
  return out;
}

// Name + price extractors
String _getUniversalItemName(dynamic key) {
  if (key == null) return 'N/A';
  try {
    final dynamic n = (key as dynamic).foodName;
    if (n is String && n.isNotEmpty) return n;
  } catch (_) {}
  try {
    final dynamic n = (key as dynamic).name;
    if (n is String && n.isNotEmpty) return n;
  } catch (_) {}
  if (key is Map) {
    return key['foodName']?.toString() ?? key['name']?.toString() ?? 'Unknown';
  }
  return 'Unknown';
}

double _getPrice(dynamic food) {
  if (food == null) return 0.0;
  try {
    if (food is Map) {
      return (food['price'] as num?)?.toDouble() ?? 0.0;
    }
    final dynamic priceField = (food as dynamic).price;
    if (priceField is num) return priceField.toDouble();
    if (priceField is String) return double.tryParse(priceField) ?? 0.0;
    if (priceField is Iterable && priceField.isNotEmpty) {
      final first = priceField.first;
      final p = (first?.price ?? first?.sellPrice ?? first?.amount ?? 0.0);
      if (p is num) return p.toDouble();
      if (p is String) return double.tryParse(p) ?? 0.0;
    }
  } catch (_) {}
  return 0.0;
}

Future<EntityPrinter?> _getBillOrKotPrinter() async {
  final box = Get.find<Box<EntityPrinter>>();
  // Prefer BILL
  final bill = box.query(EntityPrinter_.configType.equals('BILL')).build().findFirst();
  if (bill != null) return bill;
  // Fallback to KOT
  final kot = box.query(EntityPrinter_.configType.equals('KOT')).build().findFirst();
  return kot;
}

// ===== Extension without using private members =====
extension DynamicEscPos on RawBtPrinterService {
  Future<EntityPrinter?> _findPrinterRecord(String configType) async {
    try {
      final Box<EntityPrinter> printerBox = Get.find();
      return printerBox
          .query(EntityPrinter_.configType.equals(configType))
          .build()
          .findFirst();
    } catch (_) {
      return null;
    }
  }

  // Local permission helper (replacement for _requestBtPermissions)
  Future<void> _extRequestBtPermissions() async {
    if (!Platform.isAndroid) return;
    final req = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ];
    await req.request();
  }

  // Local notifier (replacement for _notifySetting)
  void _extNotifySetting(bool status) {
    if (Get.isRegistered<ControllerSetting>()) {
      Get.find<ControllerSetting>().updatePrinterStatus(status);
    }
  }

 Future<bool> connectByConfigType(String configType) async {
    try {
      final box = Get.find<Box<EntityPrinter>>();
      final printer = box
          .query(EntityPrinter_.configType.equals(configType))
          .build()
          .findFirst();

      if (printer == null) {
        print('⚠️ No printer saved for type: $configType');
        return false;
      }

      final mac = _macFromUrl(printer.printUrl);
      if (mac == null || mac.isEmpty) {
        print('⚠️ Invalid MAC for printer: ${printer.printUrl}');
        return false;
      }

      // Disconnect any active before connecting new
      await PrintBluetoothThermal.disconnect;

      print('🔹 Connecting to $configType printer [$mac]...');
      final result = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
      connected.value = result == true;
      deviceLabel.value = result ? 'BT • ${printer.printName}' : '';
      return result;
    } catch (e) {
      print('❌ connectByConfigType($configType) failed: $e');
      return false;
    }
  }

   Future<void> printToSavedPrinter({
    required String configType, // 'KOT' or 'BILL'
    required List<int> bytes,
  }) async {
    try {
      await PrintBluetoothThermal.disconnect;
      final box = Get.find<Box<EntityPrinter>>();
      final printer = box
          .query(EntityPrinter_.configType.equals(configType))
          .build()
          .findFirst();

      if (printer == null) {
        print('⚠️ No $configType printer found.');
        return;
      }

      final mac = _macFromUrl(printer.printUrl);
      if (mac == null || mac.isEmpty) {
        print('⚠️ Invalid MAC for printer: ${printer.printUrl}');
        return;
      }

      print('🔹 Connecting to $configType printer: ${printer.printName} [$mac]');
      final ok = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
      if (ok != true) {
        print('❌ Failed to connect $configType printer.');
        return;
      }

      print('✅ Connected to $configType printer, printing...');
      await Future.delayed(const Duration(milliseconds: 200));
      await PrintBluetoothThermal.writeBytes(bytes);
      print('🖨️ Printed successfully on $configType printer.');

      await Future.delayed(const Duration(milliseconds: 200));
      await PrintBluetoothThermal.disconnect;
      print('🔹 Disconnected $configType printer.');
    } catch (e) {
      print('❌ Print failed for $configType printer: $e');
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
 Future<void> printKotEscPosByConfigType({
    String configType = 'KOT',
    required dynamic kot,
    required dynamic bill,
    required Map<String, List<MapEntry<dynamic, int>>> groupedItems,
  }) async {
    final bytes = _safeBuildKotBytes(kot, bill, groupedItems, 32);
    await printToSavedPrinter(configType: configType, bytes: bytes);
  }

// Public: BILL via ESC/POS
Future<void> printBillEscPosByConfigType({
  String configType = 'BILL',
  required List<KotGroup> kots,
  required EntityOrder bill,
  required Map<String, List<MapEntry<dynamic, int>>> groupedItems,
  bool openDrawer = false,
}) async {
  if (!await connectByConfigType(configType)) {
    debugPrint('❌ Failed to connect to printer for $configType');
    return;
  }

  final record = await _findPrinterRecord(configType);
  final cpl = _cplFromSize(record?.printerSize);

  // --- Debug Logs ---
  debugPrint('🔹 Printing BILL...');
  debugPrint('🔹 KOT Count: ${kots.length}');
  debugPrint('🔹 Bill No: ${bill.orderNumber}');
  debugPrint('🔹 GroupedItems Count: ${groupedItems.length}');

  final bytes = _safeBuildBillBytes(kots, bill, groupedItems, cpl);

  debugPrint('🔹 Generated Bytes: ${bytes.length}');
  if (bytes.isEmpty) {
    debugPrint('❌ No bytes generated. BILL print aborted.');
    return;
  }

  await printRaw(bytes);
  debugPrint('✅ BILL print sent successfully (${bytes.length} bytes)');

  if (openDrawer) {
    await printRaw(_pulseDrawer(pin: 0, onMs: 120, offMs: 240));
  }
}
// ===============================================================
// ESC/POS KOT PRINT - Cleaner layout (matches PDF style)
// ===============================================================
List<int> _safeBuildKotBytes(
  KotGroup kot,
  EntityOrder bill,
  Map<String, List<MapEntry<dynamic, int>>> groupedItems,
  int cpl,
) {
  final bytes = <int>[];

  try {
    final items = groupedItems.entries.expand((e) => e.value).toList();
    final totalQty = items.fold<int>(0, (s, e) => s + e.value);

    final kotDate = DateTime.tryParse(kot.createdOn ?? '') ?? DateTime.now();
    final d = DateFormat('dd/MM/yyyy').format(kotDate);
    final t = DateFormat('hh:mm a').format(kotDate);

    bytes.addAll(_escInit());
    bytes.addAll(_align(1));
    bytes.addAll(_bold(true));
    bytes.addAll(_size(0x11));
    bytes.addAll(_textLn('KOT No: ${kot.kotNumber ?? '-'}'));
    bytes.addAll(_size(0x00));
    bytes.addAll(_bold(false));

    bytes.addAll(_textLn('${kot.tableName ?? bill.tableName ?? "Table"} | ${bill.orderTypeId ?? "Dine-In"}'));
    bytes.addAll(_textLn('Date: $d  $t'));
    bytes.addAll(_textLn('User: ${bill.userName ?? "-"}'));
    bytes.addAll(_hr(cpl));

    // Headers
    bytes.addAll(_align(0));
    bytes.addAll(_bold(true));
    bytes.addAll(_textLn(_lr('Item', 'Qty', cpl)));
    bytes.addAll(_bold(false));
    bytes.addAll(_hr(cpl));

    // Items
    for (final entry in items) {
      final name = _getUniversalItemName(entry.key);
      final qty = entry.value.toString();
      final wrapped = _wrap(name, cpl - (qty.length + 3));
      for (int i = 0; i < wrapped.length; i++) {
        final isLast = i == wrapped.length - 1;
        bytes.addAll(_textLn(isLast ? _lr(wrapped[i], qty, cpl) : wrapped[i]));
      }
    }

    bytes.addAll(_hr(cpl));
    bytes.addAll(_bold(true));
    bytes.addAll(_textLn(_lr('Total Qty:', '$totalQty', cpl)));
    bytes.addAll(_bold(false));
    bytes.addAll(_hr(cpl));
    bytes.addAll(_lf(2));
    bytes.addAll(_align(1));
    bytes.addAll(_textLn('Thank You!'));
    bytes.addAll(_cutFull());
  } catch (e) {
    debugPrint('❌ KOT print build error: $e');
  }

  return bytes;
}


List<int> _safeBuildBillBytes(
  List<KotGroup> kots,
  EntityOrder bill,
  Map<String, List<MapEntry<dynamic, int>>> groupedItems,
  int cpl,
) {
  final bytes = <int>[];

  try {
    // Get restaurant info
    final strRest = GetStorage().read('restaurant');
    ModelRestaurant? rest;
    if (strRest is String && strRest.isNotEmpty) {
      rest = ModelRestaurant.fromMap(json.decode(strRest));
    }

    final user = Get.isRegistered<AuthService>()
        ? Get.find<AuthService>().userName
        : '-';

    // Date & time
    final billDate = DateTime.tryParse(bill.createdOn ?? '') ?? DateTime.now();
    final d = DateFormat('dd/MM/yy').format(billDate);
    final t = DateFormat('hh:mm a').format(billDate);

    // Items & totals
    final items = groupedItems.entries.expand((e) => e.value).toList();
    final totalQty = items.fold<int>(0, (s, e) => s + e.value);
    final totalAmt =
        items.fold<double>(0, (s, e) => s + (_getPrice(e.key) * e.value));

    final kotNumbers = kots.map((k) => k.kotNumber).whereType<int>().toList();
    final kotString = kotNumbers.isNotEmpty ? kotNumbers.join(', ') : '';

    final moneyNoDecimal = NumberFormat("#,##0", "en_IN");

    // ===== Start Printing =====
    bytes.addAll(_escInit());
    bytes.addAll(_align(1));
    bytes.addAll(_bold(true));
    bytes.addAll(_size(0x11));
    bytes.addAll(_textLn(_asciiOnly(rest?.name ?? 'Restaurant')));
    bytes.addAll(_size(0x00));
    bytes.addAll(_bold(false));

    if ((rest?.address ?? '').isNotEmpty) {
      bytes.addAll(_textLn(_asciiOnly(rest!.address!)));
    }

    bytes.addAll(_lf(1));
    bytes.addAll(_textLn(_asciiOnly('Bill No: ${bill.orderNumber ?? '-'}')));
    if (kotString.isNotEmpty) {
      bytes.addAll(_textLn(_asciiOnly('KOT(s): $kotString')));
    }

    bytes.addAll(_textLn(_asciiOnly(
        '${bill.tableName ?? "Table"} | ${bill.orderTypeId ?? "Dine-In"}')));
    bytes.addAll(_textLn(_asciiOnly('Date: $d  $t')));
    bytes.addAll(_textLn(_asciiOnly('User: $user')));
    bytes.addAll(_hr(cpl));

    // For 58 mm, use only Qty + Amt (omit Rate)
    final wQty = 4, wAmt = 8;
    final wName = cpl - (wQty + wAmt + 3);

    // Header
    bytes.addAll(_bold(true));
    bytes.addAll(_textLn(_asciiOnly(
        'Item'.padRight(wName) +
            ' ' +
            'Qty'.padLeft(wQty) +
            ' ' +
            'Amt'.padLeft(wAmt))));
    bytes.addAll(_bold(false));
    bytes.addAll(_hr(cpl));

    // Items
    for (final entry in items) {
      final name = _asciiOnly(_getUniversalItemName(entry.key));
      final qty = entry.value;
      final amt = _getPrice(entry.key) * qty;
      final amtStr = moneyNoDecimal.format(amt);

      // word-wrap at word boundaries
      final words = name.split(' ');
      var current = '';
      for (final word in words) {
        if ((current + word).length > wName) {
          bytes.addAll(_textLn(current.trimRight()));
          current = '$word ';
        } else {
          current += '$word ';
        }
      }
      final finalLine = current.trimRight();

      final row = finalLine.padRight(wName) +
          ' ' +
          qty.toString().padLeft(wQty) +
          ' ' +
          amtStr.padLeft(wAmt);
      bytes.addAll(_textLn(row));
    }

    // Totals
    bytes.addAll(_hr(cpl));
    bytes.addAll(_bold(true));
    bytes.addAll(_textLn(
      'Total: $totalQty'.padRight(cpl - 10) +
          'RS'+
          moneyNoDecimal.format(totalAmt).padLeft(0),
    ));
    bytes.addAll(_bold(false));
    bytes.addAll(_hr(cpl));

    // Footer
    bytes.addAll(_align(1));
    bytes.addAll(_textLn('Thank You! Visit Again'));
    bytes.addAll(_textLn('www.rhposs.com'));
    bytes.addAll(_lf(3));
    bytes.addAll(_cutFull());
  } catch (e, st) {
    debugPrint('❌ BILL print build error: $e\n$st');
  }

  return bytes;
}


String _asciiOnly(String s) {
  // Removes all non-ASCII characters to prevent Bluetooth garbling
  return s.replaceAll(RegExp(r'[^\x00-\x7F]'), '');
}



  // Public: Pulse only
  Future<void> openDrawerPulse({
    String? configType,
    int pin = 0,
    int onMs = 120,
    int offMs = 240,
  }) async {
    if (configType != null && !await connectByConfigType(configType)) return;
    await printRaw(_pulseDrawer(pin: pin, onMs: onMs, offMs: offMs));
  }

  // Give the extension its own test method (don’t override the class method)
  Future<void> testPrintEscPos({int charsPerLine = 32}) async {
    final b = <int>[];
    b.addAll(_escInit());
    b.addAll(_align(1));
    b.addAll(_bold(true));
    b.addAll(_size(0x11));
    b.addAll(_textLn('TEST PRINT'));
    b.addAll(_size(0x00));
    b.addAll(_bold(false));
    b.addAll(_hr(charsPerLine));
    b.addAll(_align(0));
    b.addAll(_textLn('Hello from Flutter (Dynamic ESC/POS)'));
    b.addAll(_textLn('Line 2: sample content'));
    b.addAll(_lf(1));
    b.addAll(_align(1));
    b.addAll(_textLn('Thank you!'));
    b.addAll(_hr(charsPerLine));
    b.addAll(_lf(3));
    b.addAll(_cutFull());
    await printRaw(b);
  }

  

}