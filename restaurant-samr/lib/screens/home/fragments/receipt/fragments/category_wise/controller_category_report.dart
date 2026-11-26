import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:splash_screen_03/objectbox.g.dart';
import 'package:splash_screen_03/model/entity_bill.dart';
// EntityOrderFood is already included in entity_bill.dart ToMany relationship

/// Model for Category Sales Report
class CategorySales {
  final String category;
  final double totalAmount;
  final double soldItems; // Total quantity sold
  final String status;

  CategorySales({
    required this.category,
    required this.totalAmount,
    required this.soldItems,
    required this.status,
  });
}

/// Category-wise Sales Controller
class ControllerCategoryReport extends GetxController {
  final receipts = <CategorySales>[].obs;
  final filteredReceipts = <CategorySales>[].obs;

  final searchText = ''.obs;
  final selectedDateRange = Rxn<DateTimeRange>();

  final currentPage = 1.obs;
  final pageSize = 100.obs; // Show more items for categories
  final totalCount = 0.obs;

  double get totalAmount =>
      filteredReceipts.fold(0.0, (sum, item) => sum + item.totalAmount);

  @override
  void onInit() {
    super.onInit();
    fetchCategorySales();
  }

  // DATE LABELS
  String getDateLabel(DateTimeRange? dr, DateFormat df) {
    if (dr == null) return "All Time";
    final sameDay =
        dr.start.year == dr.end.year &&
        dr.start.month == dr.end.month &&
        dr.start.day == dr.end.day;
    if (sameDay) return df.format(dr.start);
    return "${df.format(dr.start)} - ${df.format(dr.end)}";
  }

  // DATE FILTERS
  void setDateRange(DateTimeRange? r) {
    selectedDateRange.value = r;
    _applyCombinedFilters();
  }

  void clearDateRange() {
    selectedDateRange.value = null;
    _applyCombinedFilters();
  }

  void presetToday() {
    final now = DateTime.now();
    final s = DateTime(now.year, now.month, now.day);
    final e = DateTime(now.year, now.month, now.day, 23, 59, 59);
    setDateRange(DateTimeRange(start: s, end: e));
  }

  void presetYesterday() {
    final now = DateTime.now().subtract(const Duration(days: 1));
    final s = DateTime(now.year, now.month, now.day);
    final e = DateTime(now.year, now.month, now.day, 23, 59, 59);
    setDateRange(DateTimeRange(start: s, end: e));
  }

  void presetLast7Days() {
    final now = DateTime.now();
    final s = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    final e = DateTime(now.year, now.month, now.day, 23, 59, 59);
    setDateRange(DateTimeRange(start: s, end: e));
  }

  void presetLast30Days() {
    final now = DateTime.now();
    final s = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 29));
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
    final firstOfThis = DateTime(now.year, now.month, 1);
    final lastMonthEnd = firstOfThis.subtract(const Duration(days: 1));
    final s = DateTime(lastMonthEnd.year, lastMonthEnd.month, 1);
    final e = DateTime(
      lastMonthEnd.year,
      lastMonthEnd.month,
      lastMonthEnd.day,
      23,
      59,
      59,
    );
    setDateRange(DateTimeRange(start: s, end: e));
  }

  // SEARCH + FILTER
  void _applyCombinedFilters() {
    final q = searchText.value.trim().toLowerCase();

    final results = receipts.where((r) {
      if (q.isNotEmpty) {
        if (!r.category.toLowerCase().contains(q)) return false;
      }
      return true;
    }).toList();

    // Sort by amount descending (most selling categories first)
    results.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    filteredReceipts.assignAll(results);
  }

  void applySearch() => _applyCombinedFilters();

  void clearSearch() {
    searchText.value = '';
    _applyCombinedFilters();
  }

  // FETCH CATEGORY-WISE SALES
  Future<void> fetchCategorySales({int page = 1}) async {
    try {
      final Box<EntityOrder> billsBox = Get.find<Box<EntityOrder>>();

      final allBills = billsBox.getAll();

      // Filter bills by date range
      final filteredBills = allBills.where((bill) {
        if ((bill.status ?? '').toLowerCase() == 'cancelled') return false;

        if (selectedDateRange.value != null) {
          try {
            final billDate = DateTime.tryParse(bill.createdOn ?? '');
            if (billDate != null) {
              return billDate.isAfter(selectedDateRange.value!.start) &&
                  billDate.isBefore(selectedDateRange.value!.end);
            }
          } catch (_) {}
        }
        return true;
      }).toList();

      // Map to aggregate category sales
      final Map<String, double> categoryTotals = {};
      final Map<String, double> categoryQuantities = {};

      for (final bill in filteredBills) {
        // Get all food items for this bill
        for (final foodItem in bill.listFood.toList()) {
          final category = (foodItem.category ?? 'Unknown').trim();
          if (category.isEmpty) continue;

          final qty = (foodItem.quantity ?? 0).toDouble();
          final price = foodItem.price ?? 0.0;
          final amount = qty * price;

          categoryTotals[category] = (categoryTotals[category] ?? 0.0) + amount;
          categoryQuantities[category] =
              (categoryQuantities[category] ?? 0.0) + qty;
        }
      }

      // Build output list
      final List<CategorySales> output = [];

      for (final entry in categoryTotals.entries) {
        final cat = entry.key;
        output.add(
          CategorySales(
            category: cat,
            totalAmount: entry.value,
            soldItems: categoryQuantities[cat] ?? 0.0,
            status: "fulfilled",
          ),
        );
      }

      totalCount.value = output.length;

      final start = (page - 1) * pageSize.value;
      final end = (start + pageSize.value).clamp(0, output.length);
      final paginated = (start < end)
          ? output.sublist(start, end)
          : <CategorySales>[];

      receipts.assignAll(paginated);
      filteredReceipts.assignAll(paginated);

      _applyCombinedFilters();
    } catch (e) {
      debugPrint("❌ Category sales error: $e");
    }
  }

  // PAGINATION
  int get totalPages =>
      (totalCount.value / pageSize.value).ceil().clamp(1, 99999);

  void nextPage() {
    if (currentPage.value < totalPages) {
      currentPage.value++;
      fetchCategorySales(page: currentPage.value);
    }
  }

  void prevPage() {
    if (currentPage.value > 1) {
      currentPage.value--;
      fetchCategorySales(page: currentPage.value);
    }
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      currentPage.value = page;
      fetchCategorySales(page: page);
    }
  }

  // EXPORT TO EXCEL
  Future<void> exportFilteredToExcelToDownloads() async {
    if (filteredReceipts.isEmpty) {
      Get.snackbar("Export", "No records to export");
      return;
    }

    final Excel excel = Excel.createExcel();
    final Sheet sheet = excel['Sheet1'];

    final headers = ["S.No", "Category", "Sold Items", "Amount"];

    for (int i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(
        headers[i],
      );
    }

    int row = 1;
    for (int i = 0; i < filteredReceipts.length; i++) {
      final r = filteredReceipts[i];
      final data = [
        IntCellValue(i + 1),
        TextCellValue(r.category),
        DoubleCellValue(r.soldItems),
        DoubleCellValue(r.totalAmount),
      ];

      for (int col = 0; col < data.length; col++) {
        sheet
                .cell(
                  CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
                )
                .value =
            data[col];
      }
      row++;
    }

    final bytes = excel.encode();
    if (bytes == null) return;

    Directory? dir;
    try {
      dir = await getDownloadsDirectory();
    } catch (_) {
      dir = await getTemporaryDirectory();
    }

    final file = File(
      "${dir!.path}/category-sales-${DateTime.now().millisecondsSinceEpoch}.xlsx",
    );

    await file.writeAsBytes(bytes);

    Get.snackbar("Export complete", file.path);
  }

  @override
  Future<void> refresh() async {
    await fetchCategorySales(page: currentPage.value);
  }
}
