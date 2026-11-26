// ------------------------------------------------------------
//  FULL UPDATED ControllerPaymnet.dart
//  PART 1 / 3
// ------------------------------------------------------------

import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:splash_screen_03/objectbox.g.dart';
import 'package:splash_screen_03/model/entity_bill.dart';
import 'package:splash_screen_03/model/entity_food.dart';
import 'package:splash_screen_03/model/entity_payment.dart';

/// ------------------------------------------------------------
///  MODEL FOR PAYMENT REPORT ROW
class Receipt {
  final String mode; // Cash / UPI / Card
  final double amount; // total price sum
  final int qty; // number of payments counted
  final String status; // always fulfilled in your UI

  Receipt({
    required this.mode,
    required this.amount,
    required this.qty,
    required this.status,
  });
}

/// ============================================================
///  PAYMENT CONTROLLER
/// ============================================================
class ControllerPaymnet extends GetxController {
  final receipts = <Receipt>[].obs;
  final filteredReceipts = <Receipt>[].obs;

  final searchText = ''.obs;
  final selectedDateRange = Rxn<DateTimeRange>();

  final currentPage = 1.obs;
  final pageSize = 10.obs;
  final totalCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchFromBills();
  }

  // ------------------------------------------------------------
  // DATE LABELS
  // ------------------------------------------------------------
  String getDateLabel(DateTimeRange? dr, DateFormat df) {
    if (dr == null) return "All Time";
    final sameDay =
        dr.start.year == dr.end.year &&
        dr.start.month == dr.end.month &&
        dr.start.day == dr.end.day;
    if (sameDay) return df.format(dr.start);
    return "${df.format(dr.start)} - ${df.format(dr.end)}";
  }

  // ------------------------------------------------------------
  // DATE FILTERS
  // ------------------------------------------------------------
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

  // ------------------------------------------------------------
  // SEARCH + FILTER LOGIC
  // ------------------------------------------------------------
  void _applyCombinedFilters() {
    final q = searchText.value.trim().toLowerCase();

    final results = receipts.where((r) {
      if (q.isNotEmpty) {
        if (!r.mode.toLowerCase().contains(q)) return false;
      }
      return true;
    }).toList();

    filteredReceipts.assignAll(results);
  }

  void applySearch() => _applyCombinedFilters();

  void clearSearch() {
    searchText.value = '';
    _applyCombinedFilters();
  }

  // ------------------------------------------------------------
  // FETCH + GROUP PAYMENTS (MAIN LOGIC)
  // ------------------------------------------------------------
  Future<void> fetchFromBills({int page = 1}) async {
    try {
      final Box<EntityOrder> billsBox = Get.find<Box<EntityOrder>>();
      final allBills = billsBox.getAll();

      final allBillsFiltered = allBills
          .where((b) => (b.status ?? '').toLowerCase() != 'cancelled')
          .toList();

      final Map<String, List<double>> amounts = {};
      final Map<String, int> counts = {};

      for (final bill in allBillsFiltered) {
        String paymentMode = '';
        double billAmount = 0.0;

        // Extract bill amount
        try {
          billAmount = bill.totalAmount ?? 0.0;
        } catch (_) {}

        // 1️⃣ Try ToMany payments first
        if (bill.payments.isNotEmpty) {
          for (final pay in bill.payments) {
            final mode = pay.mode.trim();
            final price = pay.price;

            amounts.putIfAbsent(mode, () => []);
            amounts[mode]!.add(price);
            counts[mode] = (counts[mode] ?? 0) + 1;
          }
        } else {
          // 2️⃣ Fallback: Read from itemsJson -> meta.paymentMode
          try {
            final itemsJson = bill.itemsJson;
            if (itemsJson != null && itemsJson.trim().isNotEmpty) {
              final parsed = jsonDecode(itemsJson);
              if (parsed is Map && parsed['meta'] is Map) {
                final meta = parsed['meta'] as Map;
                paymentMode = meta['paymentMode']?.toString() ?? '';

                if (paymentMode.trim().isNotEmpty && billAmount > 0) {
                  final mode = paymentMode.trim();
                  amounts.putIfAbsent(mode, () => []);
                  amounts[mode]!.add(billAmount);
                  counts[mode] = (counts[mode] ?? 0) + 1;
                }
              }
            }
          } catch (_) {}
        }
      }

      final List<Receipt> output = [];

      for (final entry in amounts.entries) {
        final mode = entry.key;
        final totalAmount = entry.value.fold(0.0, (prev, val) => prev + val);

        output.add(
          Receipt(
            mode: mode,
            amount: totalAmount,
            qty: counts[mode] ?? 0,
            status: "fulfilled",
          ),
        );
      }

      totalCount.value = output.length;

      final start = (page - 1) * pageSize.value;
      final end = (start + pageSize.value).clamp(0, output.length);
      final paginated = (start < end)
          ? output.sublist(start, end)
          : <Receipt>[];

      receipts.assignAll(paginated);
      filteredReceipts.assignAll(paginated);

      _applyCombinedFilters();
      // Removed update() - it was triggering infinite loop with refresh()
    } catch (e) {
      debugPrint("Payment grouping error: $e");
    }
  }

  // ------------------------------------------------------------
  // PAGINATION
  // ------------------------------------------------------------
  int get totalPages =>
      (totalCount.value / pageSize.value).ceil().clamp(1, 99999);

  void nextPage() {
    if (currentPage.value < totalPages) {
      currentPage.value++;
      fetchFromBills(page: currentPage.value);
    }
  }

  void prevPage() {
    if (currentPage.value > 1) {
      currentPage.value--;
      fetchFromBills(page: currentPage.value);
    }
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      currentPage.value = page;
      fetchFromBills(page: page);
    }
  }

  // ------------------------------------------------------------
  // EXPORT TO EXCEL
  // ------------------------------------------------------------
  Future<void> exportFilteredToExcelToDownloads() async {
    if (filteredReceipts.isEmpty) {
      Get.snackbar("Export", "No records to export");
      return;
    }

    final Excel excel = Excel.createExcel();
    final Sheet sheet = excel['Sheet1'];

    final headers = ["S.No", "Payment Mode", "Amount", "Count", "Status"];

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
        TextCellValue(r.mode),
        DoubleCellValue(r.amount),
        IntCellValue(r.qty),
        TextCellValue(r.status),
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
      "${dir!.path}/payment-report-${DateTime.now().millisecondsSinceEpoch}.xlsx",
    );

    await file.writeAsBytes(bytes);

    Get.snackbar("Export complete", file.path);
  }

  // ------------------------------------------------------------
  //  OPTIONAL: refresh helper (call when underlying Box changes)
  // ------------------------------------------------------------
  @override
  Future<void> refresh() async {
    await fetchFromBills(page: currentPage.value);
  }
} // end ControllerPaymnet
