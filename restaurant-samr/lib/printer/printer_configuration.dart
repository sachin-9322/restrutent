import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:splash_screen_03/captain/login/auth_service.dart';

import 'package:splash_screen_03/model/entity_kot.dart';
import 'package:splash_screen_03/model/entity_bill.dart';
import 'package:splash_screen_03/model/entity_printer.dart';
import 'package:splash_screen_03/model/enum_printer_size.dart';
import 'package:splash_screen_03/model/model_restaurant.dart';
import 'package:splash_screen_03/objectbox.g.dart';
import 'package:splash_screen_03/screens/home/fragments/order/controller_order.dart';

// ======================= Helpers =======================

EnumPrinterSize parsePrinterSize(String? value) {
  final v = (value ?? '').toLowerCase().replaceAll(' ', '');
  if (v.contains('a4')) return EnumPrinterSize.a4;
  if (v.contains('80')) return EnumPrinterSize.mm80;
  if (v.contains('58')) return EnumPrinterSize.mm58;
  return EnumPrinterSize.mm58;
}

double printableWidthMm(EnumPrinterSize size) {
  switch (size) {
    case EnumPrinterSize.mm80:
      return 72.0;
    case EnumPrinterSize.mm58:
      return 48.0;
    case EnumPrinterSize.a4:
      return 210.0;
  }
}

final pw.Font _fontRegular = pw.Font.helvetica();
final pw.Font _fontBold = pw.Font.helveticaBold();

Future<void> kotPrintByConfigType(
  String configType, {
  required KotGroup kot,
  required EntityOrder bill,
  required Map<String, List<MapEntry<dynamic, int>>> groupedItems,
}) async {
  final Box<EntityPrinter> printerBox = Get.find();
  final printerRecord = printerBox
      .query(EntityPrinter_.configType.equals(configType))
      .build()
      .findFirst();

  if (printerRecord == null) {
    debugPrint("🖨️ [KOT Print] No printer record found for configType: $configType");
    return;
  }

  // ✅ New logic: ensure we always have something to print
  Map<String, List<MapEntry<dynamic, int>>> finalGrouped = {};

  // if groupedItems are empty, rebuild from current kot items
  final totalCount = groupedItems.values.fold<int>(0, (p, e) => p + e.length);
  if (totalCount == 0 && kot.items.isNotEmpty) {
    // Build a grouped map directly from kot.items (DB)
    final Map<String, List<MapEntry<dynamic, int>>> kotMap = {};
    for (final item in kot.items) {
      kotMap.putIfAbsent(item.category ?? "Main", () => []);
int getQty(dynamic it) {
  try {
    final q = (it as dynamic).qty;
    if (q is int) return q;
    if (q is double) return q.round();
    if (q is String) return int.tryParse(q) ?? 1;
  } catch (_) {}
  try {
    final q2 = (it as dynamic).quantity;
    if (q2 is int) return q2;
    if (q2 is double) return q2.round();
    if (q2 is String) return int.tryParse(q2) ?? 1;
  } catch (_) {}
  return 1;
}

kotMap[item.category ?? "Main"]!.add(MapEntry(item, getQty(item)));
    }
    print("🧾 KOT ${kot.kotNumber} built grouped items => "
      "${finalGrouped.values.fold<int>(0, (p, e) => p + e.length)} items");

    finalGrouped = kotMap;
    print("🧩 Built groupedItems from kot.items: ${kot.items.length}");
  } else {
    finalGrouped = groupedItems;
  }

  // ✅ Filter groupedItems to only include this KOT’s items
  final filteredGroupedItems = <String, List<MapEntry<dynamic, int>>>{};
  finalGrouped.forEach((key, entries) {
    filteredGroupedItems[key] = entries.where((entry) {
      final eKey = entry.key;
      try {
        final kotNum = (eKey as dynamic).kotNumber;
        return kotNum == null || kotNum == 0 || kotNum == kot.kotNumber;
      } catch (_) {
        return true;
      }
    }).toList();
  });

  // ✅ Force print output
  print("🧩 FINAL_PRINT group counts => "
      "${filteredGroupedItems.entries.map((e) => '${e.key}:${e.value.length}').join(', ')}");


  try {
    final printer = Printer(
      name: printerRecord.printName ?? '',
      url: printerRecord.printUrl ?? '',
      model: printerRecord.printModel ?? '',
      location: printerRecord.printLocation ?? '',
      comment: printerRecord.printComment ?? '',
      isDefault: printerRecord.printDefault ?? false,
      isAvailable: printerRecord.printIsAvailable ?? true,
    );

    final EnumPrinterSize printerWidth = parsePrinterSize(
      printerRecord.printerSize,
    );
    final int copies = (printerRecord.noOfCop ?? 1).clamp(1, 10);

    // ✅ Use filteredGroupedItems
    final pdfBytes = await _buildKotPdf(
      kot: kot,
      bill: bill,
      groupedItems: filteredGroupedItems,
      size: printerWidth,
    );

    for (int i = 0; i < copies; i++) {
      try {
        debugPrint("🖨️ Sending KOT_${kot.kotNumber ?? ''} copy ${i + 1}/$copies...");
        await Future.delayed(const Duration(milliseconds: 300));
        await Printing.directPrintPdf(
          printer: printer,
          onLayout: (format) async => pdfBytes,
          name: 'KOT_${kot.kotNumber ?? ''}.pdf',
        );
      } catch (e, st) {
        debugPrint("⚠️ KOT print error (copy ${i + 1}): $e\n$st");
      }
    }
  } catch (e, st) {
    debugPrint("Error printing $configType: $e\n$st");
  }
}


// =================== REPLACE BOTH FUNCTIONS BELOW ===================

// Robust printer config decoder
Map<String, dynamic> _decodePrinterConfig(String? raw) {
  if (raw == null || raw.trim().isEmpty) return {};

  // Try normal JSON first
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    // sometimes jsonDecode returns Map<dynamic, dynamic> — normalize to Map<String, dynamic>
    return Map<String, dynamic>.from(decoded as Map);
  } catch (e) {
    debugPrint('Printer config: not plain JSON — will try base64 fallback.');
  }

  // Try Base64 -> utf8 -> JSON
  try {
    final bytes = base64.decode(raw);
    final text = utf8.decode(bytes);
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) return decoded;
    return Map<String, dynamic>.from(decoded as Map);
  } catch (e) {
    debugPrint('Printer config: base64->json decode failed: $e');
  }

  // Try stripping non-ASCII (sometimes there are stray extension bytes)
  try {
    final cleaned = raw.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
    final decoded = jsonDecode(cleaned);
    if (decoded is Map<String, dynamic>) return decoded;
    return Map<String, dynamic>.from(decoded as Map);
  } catch (e) {
    debugPrint('Printer config: cleaned-json decode failed: $e');
  }

  // Last resort: log and return empty config
  debugPrint('Printer config decode ultimately failed. Returning empty map.');
  return {};
}
Future<void> billPrintByConfigType(
  String configType, {
  required List<KotGroup> kots, // CHANGED: Now accepts a list of KOTs
  required EntityOrder bill,
  required Map<String, List<MapEntry<dynamic, int>>> groupedItems,
}) async {
  try {
    final Box<EntityPrinter> printerBox = Get.find();

    final printerRecord = printerBox
        .query(EntityPrinter_.configType.equals(configType))
        .build()
        .findFirst();

    if (printerRecord == null) {
      // Get.snackbar(
      //   "Error",
      //   "$configType printer not found",
      //   snackPosition: SnackPosition.BOTTOM,
      // );
      return;
    }

    final printer = Printer(
      name: printerRecord.printName ?? '',
      url: printerRecord.printUrl ?? '',
      model: printerRecord.printModel ?? '',
      location: printerRecord.printLocation ?? '',
      comment: printerRecord.printComment ?? '',
      isDefault: printerRecord.printDefault ?? false,
      isAvailable: printerRecord.printIsAvailable ?? true,
    );

    final EnumPrinterSize printerWidth = parsePrinterSize(
      printerRecord.printerSize,
    );
    final int copies = (printerRecord.noOfCop ?? 1).clamp(1, 10);

    final pdfBytes = await _buildBillPdf(
      kots: kots, // CHANGED: Pass the entire list to the PDF builder
      bill: bill,
      groupedItems: groupedItems,
      size: printerWidth,
    );

    for (int i = 0; i < copies; i++) {
      await Printing.directPrintPdf(
        printer: printer,
        onLayout: (format) async => pdfBytes,
        name: 'BILL_${bill.orderNumber ?? ''}.pdf',
      );
    }
  } catch (e, st) {
    debugPrint("Error printing $configType: $e\n$st");
  }
}


Future<Uint8List> _buildBillPdf({
  required List<KotGroup> kots,
  required EntityOrder bill,
  required Map<String, List<MapEntry<dynamic, int>>> groupedItems,
  required EnumPrinterSize size,
}) async {
  final pageWidthMm = printableWidthMm(size);
  final pdf = pw.Document();
  final AuthService authService = Get.find();

  // ==================== NEW, FIXED CODE ====================
String? strRest = GetStorage().read('restaurant');
ModelRestaurant? modelRestaurant;

if (strRest != null && strRest.isNotEmpty) {
  try {
    // 👈 THE FIX IS HERE
    // Step 1: Decode the Base64 string to get the raw JSON string.
    final jsonString = utf8.decode(base64.decode(strRest));

    // Step 2: Now decode the actual JSON string.
    modelRestaurant = ModelRestaurant.fromMap(json.decode(jsonString));

  } catch (e) {
    debugPrint("🔴 Failed to decode restaurant data: $e");
    // If decoding fails, we can fall back to direct JSON parsing just in case.
    try {
        modelRestaurant = ModelRestaurant.fromMap(json.decode(strRest));
    } catch (_) {
        debugPrint("🔴 Direct JSON parsing also failed for restaurant data.");
    }
  }
}
final restaurantName = modelRestaurant?.name ?? "SMR Canteen";
final restaurantAddress = modelRestaurant?.address ?? "Dubai";

  
  pw.Font? uReg;
  pw.Font? uBold;
  // This is the special font that contains the Rupee symbol '₹'
  pw.Font? rupeeFont;
  try {
    uReg = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
    );
    uBold = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));

    // === CHANGE 1: Load a font that supports the Rupee Symbol ===
    // Make sure 'Poppins-Bold.ttf' is in your 'assets/fonts/' folder
    // and registered in pubspec.yaml
    rupeeFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Poppins-Bold.ttf'),
    );
  } catch (e) {
    // It's good practice to log the error to see if a font failed to load
    print('Error loading fonts: $e');
  }

  // Fallback to the regular bold font if the special Rupee font fails to load
  final finalBoldFont = uBold ?? _fontBold;
  final finalRupeeFont = rupeeFont ?? finalBoldFont;


  // ... (rest of your existing code is fine)
  final allItems = groupedItems.entries.expand((e) => e.value).toList();

  DateTime billDate = DateTime.now();
  try {
    final created = bill.createdOn;
    if (created is String) {
      billDate = DateTime.tryParse(created) ?? DateTime.now();
    } else if (created is int) {
      billDate = DateTime.fromMillisecondsSinceEpoch(created as int);
    } else if (created is DateTime) {
      billDate = created!;
    }
  } catch (_) {}
  final formattedDate = DateFormat('dd/MM/yyyy').format(billDate.toLocal());
  final formattedTime = DateFormat('hh:mm a').format(billDate.toLocal());

  final NumberFormat money = NumberFormat("#,##0");
  String numOnly(double v) => money.format(v);

  double getPrice(dynamic food) {
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

  int totalQty = 0;
  double totalAmount = 0.0;

  final pageFormat = PdfPageFormat(
    pageWidthMm * PdfPageFormat.mm,
    double.infinity,
    marginAll: 0,
  );

  final double fsTitle = size == EnumPrinterSize.mm58 ? 12 : 14;
  final double fsHeader = size == EnumPrinterSize.mm58 ? 8 : 10;
  final double fsBody = size == EnumPrinterSize.mm58 ? 7 : 9;
  final double fsSmall = size == EnumPrinterSize.mm58 ? 6.5 : 8;

  pdf.addPage(
    pw.Page(
      pageFormat: pageFormat,
      build: (context) {
        final kotNumbers = kots
            .map((k) => k.kotNumber)
            .where((n) => n != null)
            .toSet()
            .toList();
        kotNumbers.sort();
        final kotString = kotNumbers.join(', ');

        return pw.Padding(
          padding: pw.EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ... (All the header text widgets are fine)
              pw.Text(
              restaurantName, // Replaced hardcoded string
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: finalBoldFont, fontSize: fsTitle),
              ),
              pw.SizedBox(height: 4),

              // --- MODIFIED: USE DYNAMIC ADDRESS ---
              pw.Text(
              restaurantAddress, // Replaced hardcoded string
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  font: uReg ?? _fontRegular,
                  fontSize: fsBody,
                  fontWeight: pw.FontWeight.normal,
                ),
              ),

              pw.SizedBox(height: 4),
              pw.Text(
                'Bill No: ${bill.orderNumber ?? '-'}',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: finalBoldFont, fontSize: fsHeader),
              ),

              if (kotString.isNotEmpty) ...[
                pw.SizedBox(height: 6),
                pw.Text(
                  'KOT No(s): $kotString',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: finalBoldFont, fontSize: fsHeader),
                ),
              ],

              pw.SizedBox(height: 4),
              pw.Text(
                '${bill.tableName ?? "Table"} | ${bill.orderTypeId ?? "Dine-In"}',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: uReg ?? _fontRegular, fontSize: fsBody),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Date: $formattedDate',
                    style: pw.TextStyle(font: uReg ?? _fontRegular, fontSize: fsSmall),
                  ),
                  pw.Text(
                    formattedTime,
                    style: pw.TextStyle(font: uReg ?? _fontRegular, fontSize: fsSmall),
                  ),
                ],
              ),
              pw.Text(
                'User: ${ authService.userName ?? "-"}',
                style: pw.TextStyle(font: finalBoldFont, fontSize: fsSmall),
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.6),
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text(
                      'Item',
                      style: pw.TextStyle(font: finalBoldFont, fontSize: fsHeader),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      'Qty',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(font: finalBoldFont, fontSize: fsHeader),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'Rate',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(font: finalBoldFont, fontSize: fsHeader),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'Amt',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(font: finalBoldFont, fontSize: fsHeader),
                    ),
                  ),
                ],
              ),
              pw.Divider(thickness: 0.5),
              ...allItems.map((entry) {
                final qty = entry.value;
                final price = getPrice(entry.key);
                final amount = price * qty;
                totalQty += qty;
                totalAmount += amount;
                final itemName = _getUniversalItemName(entry.key);
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 1.2),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        flex: 4,
                        child: pw.Text(
                          itemName,
                          style: pw.TextStyle(
                            font: uReg ?? _fontRegular,
                            fontSize: fsBody,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          '$qty',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            font: finalBoldFont,
                            fontSize: fsBody,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          numOnly(price),
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            font: uReg ?? _fontRegular,
                            fontSize: fsBody,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          numOnly(amount),
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            font: finalBoldFont,
                            fontSize: fsBody,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              pw.Divider(thickness: 0.6),
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      'Total',
                      style: pw.TextStyle(font: finalBoldFont, fontSize: fsHeader),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      '$totalQty',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(font: finalBoldFont, fontSize: fsHeader),
                    ),
                  ),
                  // === CHANGE 2: Use the Rupee font for the total amount ===
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      'RS ${money.format(totalAmount)}', // Prepend the symbol
                      maxLines: 1,
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        // Use the special font here
                        font: finalRupeeFont,
                        fontSize: fsHeader,
                      ),
                    ),
                  ),
                ],
              ),
              // ... (rest of the widgets are fine)

              pw.Divider(thickness: 0.6),
              pw.SizedBox(height: 6),
              pw.Text(
                'Thank You! Visit Again',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: uReg ?? _fontRegular, fontSize: fsBody),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'https://www.rhposs.com',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  font: uReg ?? _fontRegular,
                  fontSize: fsSmall,
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
  return pdf.save();
}

// =================== END OF REPLACEMENT ===================

// ======================= PDF builders =======================

// =========== FIXED: NEW HELPER FUNCTION TO GET ITEM NAME ============
// This function can get the name from EntityFood, ExtraItem, EntityOrderFood, or a Map.
String _getUniversalItemName(dynamic key) {
  if (key == null) return 'N/A';

  // Try to access 'foodName' (for EntityFood)
  try {
    final dynamic name = (key as dynamic).foodName;
    if (name is String && name.isNotEmpty) return name;
  } catch (_) {}

  // Try to access 'name' (for ExtraItem, EntityOrderFood)
  try {
    final dynamic name = (key as dynamic).name;
    if (name is String && name.isNotEmpty) return name;
  } catch (_) {}

  // Handle if it's a Map
  if (key is Map) {
    return key['foodName']?.toString() ??
        key['name']?.toString() ??
        'Unknown Item';
  }

  // Fallback if all else fails
  return 'Unknown Item';
}
// Replace your existing _buildKotPdf function with this one.

Future<Uint8List> _buildKotPdf({
  required KotGroup kot,
  required EntityOrder bill,
  required Map<String, List<MapEntry<dynamic, int>>> groupedItems,
  required EnumPrinterSize size,
}) async {
  final pageWidthMm = printableWidthMm(size);
  final pdf = pw.Document();

  final pw.Font finalRegularFont = pw.Font.helvetica();
  final pw.Font finalBoldFont = pw.Font.helveticaBold();

  // Get all item entries from the map
  final allItemEntries = groupedItems.entries.expand((e) => e.value).toList();

  // ===================== ✅ THE FIX IS HERE =====================
  // Filter the list to include ONLY items for this specific KOT.
  // An item belongs to this KOT if it's new (kotNumber is null/0)
  // or if its kotNumber matches the one we are printing.
  final filteredEntries = allItemEntries.where((entry) {
    final item = entry.key;
    try {
      // Dynamically access the kotNumber property
      final int? itemKotNumber = (item as dynamic).kotNumber;
      
      // Keep the item if it's new OR if it belongs to the current KOT
      return itemKotNumber == null || itemKotNumber == 0 || itemKotNumber == kot.kotNumber;
    } catch (_) {
      // If the item doesn't have a 'kotNumber' property (like a temporary ExtraItem),
      // it's a new item and should be printed.
      return true;
    }
  }).toList();

  // If after filtering, there are no items, don't generate an empty PDF.
  if (filteredEntries.isEmpty) {
      debugPrint("🖨️ [KOT Print] No new items to print for KOT #${kot.kotNumber}. Aborting PDF generation.");
      // Return an empty Uint8List to prevent printing an empty page.
      return Uint8List(0);
  }
  // ===================== END OF FIX =====================


  // Now, calculate total quantity based on the *filtered* list
  final int totalQty = filteredEntries.fold(0, (sum, e) => sum + e.value);

  DateTime kotDate = DateTime.tryParse(kot.createdOn ?? '') ?? DateTime.now();
  final formattedDate = DateFormat('dd/MM/yyyy').format(kotDate.toLocal());
  final formattedTime = DateFormat('hh:mm a').format(kotDate.toLocal());

  final pageFormat = PdfPageFormat(
    pageWidthMm * PdfPageFormat.mm,
    double.infinity,
    marginAll: 0,
  );

  final double fsTitle = size == EnumPrinterSize.mm58 ? 12 : 14;
  final double fsHeader = size == EnumPrinterSize.mm58 ? 9 : 11;
  final double fsBody = size == EnumPrinterSize.mm58 ? 10 : 12;
  final double fsSmall = size == EnumPrinterSize.mm58 ? 7 : 8;

  pdf.addPage(
    pw.Page(
      pageFormat: pageFormat,
      build: (context) {
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                'KOT No: ${kot.kotNumber ?? '-'}',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: finalBoldFont, fontSize: fsTitle),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                '${kot.tableName ?? bill.tableName ?? "Table"} | ${bill.orderTypeId ?? "Dine-In"}',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: finalRegularFont, fontSize: fsHeader),
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Date: $formattedDate',
                      style: pw.TextStyle(font: finalRegularFont, fontSize: fsSmall)),
                  pw.Text(formattedTime,
                      style: pw.TextStyle(font: finalRegularFont, fontSize: fsSmall)),
                ],
              ),
              pw.Text('User: ${bill.userName ?? "-"}',
                  style: pw.TextStyle(font: finalBoldFont, fontSize: fsSmall)),
              pw.Divider(thickness: 0.6),
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text('Item',
                        style: pw.TextStyle(
                            font: finalBoldFont, fontSize: fsHeader)),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text('Qty',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                            font: finalBoldFont, fontSize: fsHeader)),
                  ),
                ],
              ),
              pw.Divider(thickness: 0.4),

              // ✅ Use the 'filteredEntries' list here instead of the original
              ...filteredEntries.map((entry) {
                final itemName = _getUniversalItemName(entry.key);
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        flex: 4,
                        child: pw.Text(itemName,
                            style: pw.TextStyle(
                                font: finalBoldFont, fontSize: fsBody)),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(entry.value.toString(),
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                                font: finalBoldFont, fontSize: fsBody)),
                      ),
                    ],
                  ),
                );
              }),
              pw.Divider(thickness: 0.6),
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text('Total Qty:',
                        style: pw.TextStyle(
                            font: finalBoldFont, fontSize: fsHeader)),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(totalQty.toString(), // This now uses the filtered total
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                            font: finalBoldFont, fontSize: fsHeader)),
                  ),
                ],
              ),
              pw.Divider(thickness: 0.6),
            ],
          ),
        );
      },
    ),
  );

  return pdf.save();
}
