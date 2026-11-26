// controller_kot_repoert.dart
import 'dart:io';
import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:splash_screen_03/model/entity_kot.dart';
import 'package:splash_screen_03/model/entity_bill.dart';
import 'package:splash_screen_03/objectbox.g.dart';
import 'package:splash_screen_03/model/entity_bill_food.dart'; // Ensure this import is correct

class ControllerKotReports extends GetxController {
  final kotReceipts = <KotReceipt>[].obs;
  final filteredKotReceipts = <KotReceipt>[].obs;

  // simple search + date-range
  final searchText = ''.obs;
  final selectedDateRange = Rxn<DateTimeRange>();

  // paging
  final currentPage = 1.obs;
  final pageSize = 25.obs; // You can adjust this value
  final totalCount = 0.obs;

  final DateFormat df = DateFormat('dd MMM yyyy, HH:mm');

  int get totalPages =>
      (totalCount.value / (pageSize.value == 0 ? 1 : pageSize.value))
          .ceil()
          .clamp(1, 9999);

  @override
  void onInit() {
    super.onInit();
    refresh();
  }
// 🔹 Global Date Presets
void presetToday() {
  final now = DateTime.now();
  final s = DateTime(now.year, now.month, now.day, 0, 0, 0);
  final e = DateTime(now.year, now.month, now.day, 23, 59, 59);
  setDateRange(DateTimeRange(start: s, end: e));
}

void presetYesterday() {
  final now = DateTime.now().subtract(const Duration(days: 1));
  final s = DateTime(now.year, now.month, now.day, 0, 0, 0);
  final e = DateTime(now.year, now.month, now.day, 23, 59, 59);
  setDateRange(DateTimeRange(start: s, end: e));
}

void presetLast7Days() {
  final now = DateTime.now();
  final s = now.subtract(const Duration(days: 6));
  final e = DateTime(now.year, now.month, now.day, 23, 59, 59);
  setDateRange(DateTimeRange(start: s, end: e));
}

void presetLast30Days() {
  final now = DateTime.now();
  final s = now.subtract(const Duration(days: 29));
  final e = DateTime(now.year, now.month, now.day, 23, 59, 59);
  setDateRange(DateTimeRange(start: s, end: e));
}

void presetThisMonth() {
  final now = DateTime.now();
  final s = DateTime(now.year, now.month, 1);
  final e = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  setDateRange(DateTimeRange(start: s, end: e));
}

void presetLastMonth() {
  final now = DateTime.now();
  final firstOfThisMonth = DateTime(now.year, now.month, 1);
  final lastMonthEnd = firstOfThisMonth.subtract(const Duration(days: 1));
  final s = DateTime(lastMonthEnd.year, lastMonthEnd.month, 1);
  final e = DateTime(lastMonthEnd.year, lastMonthEnd.month, lastMonthEnd.day, 23, 59, 59);
  setDateRange(DateTimeRange(start: s, end: e));
}

void clearDateFilter() {
  selectedDateRange.value = null;
  _applyCombinedFilters();
}

  // ============== BUG FIX: The refresh method has been corrected ==============
  void refresh({int page = 1}) {
    try {
      currentPage.value = page;
      final Box<EntityOrderFood> kotBox = Get.find<Box<EntityOrderFood>>();
      final allKotItems = kotBox.getAll();

      // 1. Group all food items by their KOT number
      final Map<int, List<EntityOrderFood>> groupedByKotNumber = {};
      for (final item in allKotItems) {
        try {
          final kotNum = (item as dynamic).kotNumber as int?;
          if (kotNum != null && kotNum > 0) {
            (groupedByKotNumber[kotNum] ??= []).add(item);
          }
        } catch (_) {
          // Ignore items without a valid KOT number
        }
      }

      // 2. Convert each group into a single KotReceipt summary
      final allAggregatedReceipts = groupedByKotNumber.entries.map((entry) {
        final kotNumber = entry.key;
        final itemsInKot = entry.value;
        if (itemsInKot.isEmpty) return null;

        final firstItem = itemsInKot.first;
        DateTime created = DateTime.now();
        try {
            // Simplified date parsing
            final cand = (firstItem as dynamic).createdOn?.toString();
            if (cand != null && cand.isNotEmpty) {
                created = DateTime.tryParse(cand) ?? DateTime.fromMillisecondsSinceEpoch(int.tryParse(cand) ?? 0);
            }
        } catch(_) {}
        created = created.toLocal();

        String tableName = (firstItem as dynamic).tableName ?? 'N/A';
        int? orderNumber; // You may need to fetch this from the related EntityOrder if needed
        int kotIdForDialog = (firstItem as dynamic).kotId ?? 0;

        // 3. Calculate totals for the entire KOT group
        int totalQty = 0;
        double totalAmount = 0.0;
        double totalUnitPriceSum = 0.0;
        int unitPriceCount = 0;

        for (final item in itemsInKot) {
          final qty = item.quantity ?? 0;
          final price = item.price ?? 0.0;
          totalQty += qty;
          totalAmount += (price * qty);
          if (price > 0) {
            totalUnitPriceSum += price;
            unitPriceCount++;
          }
        }
        final avgPrice = (unitPriceCount > 0) ? (totalUnitPriceSum / unitPriceCount) : 0.0;
        
        return KotReceipt(
          kotNumber: kotNumber,
          orderNumber: orderNumber,
          tableName: tableName,
          createdOn: created,
          kotId: kotIdForDialog, // Used as a representative ID
          totalQty: totalQty,
          avgPrice: avgPrice,
          totalAmount: totalAmount,
        );
      }).whereType<KotReceipt>().toList();

      // 4. Sort all KOTs by date (newest first)
      allAggregatedReceipts.sort((a, b) => b.createdOn.compareTo(a.createdOn));
      
      // 5. Paginate the aggregated list
      totalCount.value = allAggregatedReceipts.length;
      final start = (page - 1) * pageSize.value;
      final end = (start + pageSize.value).clamp(0, allAggregatedReceipts.length);
      
      // =========================== THE FIX IS HERE ===========================
      // The empty list type was wrong, causing a silent crash.
      // It was <EntityOrderFood>[], now it is correctly <KotReceipt>[].
      final paginatedSlice = (start < end) ? allAggregatedReceipts.sublist(start, end) : <KotReceipt>[];
      // =======================================================================
      
      kotReceipts.assignAll(paginatedSlice);
      _applyCombinedFilters();

    } catch (e, st) {
      // Added better logging to see future errors
      debugPrint('ControllerKotReports.refresh FAILED: $e\n$st');
      kotReceipts.clear();
      filteredKotReceipts.clear();
      totalCount.value = 0;
    }
  }
  
  List<Map<String, dynamic>> getKotItems(EntityOrderFood kot) {
    // ... (this method is unchanged)
    final List<Map<String, dynamic>> items = [];
    try {
      final raw = (kot as dynamic).itemsJson;
      if (raw != null) {
        final dec = jsonDecode(raw.toString());
        if (dec is Map && dec['items'] is List) {
          for (final e in dec['items']) {
            if (e is Map) items.add(Map<String, dynamic>.from(e));
          }
        } else if (dec is List) {
          for (final e in dec) {
            if (e is Map) items.add(Map<String, dynamic>.from(e));
          }
        }
      }
    } catch (_) {
      // ignore parse errors and return empty list
    }
    return items;
  }

  // This method for the details dialog is correct and unchanged.
  List<Map<String, dynamic>> getKotItemsByKotNumber(int kotNumber) {
    try {
      final Box<EntityOrderFood> kotBox = Get.find<Box<EntityOrderFood>>();
      final query = kotBox.query(EntityOrderFood_.kotNumber.equals(kotNumber)).build();
      final kotFoodItems = query.find();
      query.close();

      return kotFoodItems.map((f) {
        final item = f as dynamic;
        return {
          'name': item.name ?? 'Item',
          'foodName': item.name ?? 'Item',
          'qty': item.quantity ?? 1,
          'quantity': item.quantity ?? 1,
          'price': item.price ?? 0.0,
          'amount': (item.price ?? 0.0) * (item.quantity ?? 1.0),
          'status': item.isPrinted ?? false ? 'Printed' : 'Pending',
          'username': item.userName ?? '-',
          'user': item.userName ?? '-',
          'waiter': item.userName ?? '-',
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }
  
  void _applyCombinedFilters() {
    // ... (this method is unchanged)
    final q = (searchText.value).trim().toLowerCase();
    final dr = selectedDateRange.value;

    final results = kotReceipts.where((r) {
      if (dr != null) {
        final start = DateTime(dr.start.year, dr.start.month, dr.start.day, 0, 0, 0);
        final end = DateTime(dr.end.year, dr.end.month, dr.end.day, 23, 59, 59);
        if (r.createdOn.isBefore(start) || r.createdOn.isAfter(end)) return false;
      }

      if (q.isNotEmpty) {
        final combined = '${r.kotNumber} ${r.orderNumber ?? ''} ${r.tableName} ${df.format(r.createdOn)} ${r.totalQty} ${r.totalAmount.toStringAsFixed(2)}'.toLowerCase();
        if (!combined.contains(q)) return false;
      }
      return true;
    }).toList();

    filteredKotReceipts.assignAll(results);
  }

  void applySearch(String query) {
    searchText.value = query;
    _applyCombinedFilters();
  }

  void setDateRange(DateTimeRange? r) {
    selectedDateRange.value = r;
    _applyCombinedFilters();
  }

  void clearFilters() {
    searchText.value = '';
    selectedDateRange.value = null;
    _applyCombinedFilters();
  }

  void nextPage() {
    if (currentPage.value < totalPages) refresh(page: currentPage.value + 1);
  }

  void prevPage() {
    if (currentPage.value > 1) refresh(page: currentPage.value - 1);
  }

  Future<void> exportFilteredToExcelToDownloads() async {
    // ... (this method is unchanged)
    try {
      if (filteredKotReceipts.isEmpty) {
        Get.snackbar('Export', 'No KOT records to export', snackPosition: SnackPosition.BOTTOM);
        return;
      }

      final Excel excel = Excel.createExcel();
      final String sheetName = excel.getDefaultSheet() ?? 'Sheet1';
      final Sheet sheetObject = excel[sheetName];

      final header = ['S.No', 'KOT No', 'Bill No', 'Table', 'Qty', 'Price (avg)', 'Total', 'Created On'];
      for (int col = 0; col < header.length; col++) {
        final cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
        cell.value = TextCellValue(header[col]);
      }

      final DateFormat outDf = DateFormat('dd MMM yyyy, HH:mm');

      for (int i = 0; i < filteredKotReceipts.length; i++) {
        final r = filteredKotReceipts[i];
        final row = [
          IntCellValue(i + 1),
          IntCellValue(r.kotNumber),
          TextCellValue(r.orderNumber?.toString() ?? '-'),
          TextCellValue(r.tableName),
          IntCellValue(r.totalQty),
          TextCellValue(r.avgPrice.toStringAsFixed(2)),
          TextCellValue(r.totalAmount.toStringAsFixed(2)),
          TextCellValue(outDf.format(r.createdOn)),
        ];

        for (int col = 0; col < row.length; col++) {
          final cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: i + 1));
          cell.value = row[col];
        }
      }

      final List<int>? bytes = excel.encode();
      if (bytes == null || bytes.isEmpty) {
        Get.snackbar('Export', 'Failed to create Excel file', snackPosition: SnackPosition.BOTTOM);
        return;
      }

      Directory? targetDir;
      try {
        targetDir = await getDownloadsDirectory();
      } catch (_) {
        targetDir = null;
      }
      targetDir ??= await getTemporaryDirectory();

      final String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final String fileName = 'kot-export-$timestamp.xlsx';
      final File outFile = File('${targetDir.path}/$fileName');

      await outFile.writeAsBytes(bytes, flush: true);

      Get.snackbar('Export complete', 'Saved to: ${outFile.path}', snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 4));

      if (Platform.isWindows) {
        try {
          Process.run('explorer', [targetDir.path]);
        } catch (_) {}
      }
    } catch (e, st) {
      debugPrint('KOT export failed: $e\n$st');
      Get.snackbar('Export failed', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }
  
  EntityOrderFood? getKotById(int kotId) {
    // ... (this method is unchanged)
    try {
      final Box<EntityOrderFood> kotBox = Get.find<Box<EntityOrderFood>>();
      return kotBox.get(kotId);
    } catch (_) {
      return null;
    }
  }

  Future<void> migrateFillKotTableNames() async {/* ... */}
}