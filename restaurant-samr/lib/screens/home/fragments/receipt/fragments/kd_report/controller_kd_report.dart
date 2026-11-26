import 'dart:async';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:splash_screen_03/objectbox.g.dart';
import 'package:splash_screen_03/model/entity_bill.dart';
import 'package:splash_screen_03/model/entity_food.dart';

/// Bill Report Controller
class ControllerKdReport extends GetxController {
  final Box<EntityOrder> _billBox = Get.find<Box<EntityOrder>>();
  final Box<EntityFood> _foodBox = Get.find<Box<EntityFood>>();

  // Data
  final allBills = <EntityOrder>[].obs;
  final filteredBills = <EntityOrder>[].obs;

  // Aggregated Data for KD Report
  List<Map<String, dynamic>> get departmentSales {
    final Map<String, Map<String, dynamic>> grouped = {};

    for (final bill in filteredBills) {
      // Skip cancelled bills if necessary (optional based on requirements)
      // if (bill.status == 'Cancelled') continue;

      for (final orderFood in bill.listFood) {
        // 1. Find the original food item to get the Department
        final foodItem = _foodBox.get(orderFood.foodId ?? 0);
        final deptName = (foodItem?.kitchenDepartment ?? 'Unknown').trim();

        // Use "Unknown" if empty
        final key = deptName.isEmpty ? 'Unknown' : deptName;

        // 2. Initialize if not present
        if (!grouped.containsKey(key)) {
          grouped[key] = {'department': key, 'count': 0.0, 'amount': 0.0};
        }

        // 3. Aggregate
        // Quantity is int, but we treat as double for safety in reports
        final qty = (orderFood.quantity ?? 0).toDouble();
        final price = orderFood
            .total; // Total price for this line item (qty * unitPrice + tax)

        grouped[key]!['count'] += qty;
        grouped[key]!['amount'] += price;
      }
    }

    // Convert to list
    final list = grouped.values.toList();

    // Sort by Department Name
    list.sort(
      (a, b) =>
          (a['department'] as String).compareTo(b['department'] as String),
    );

    return list;
  }

  // Filters
  final searchText = ''.obs;
  final selectedDateRange = Rxn<DateTimeRange>();

  // Pagination
  final currentPage = 1.obs;
  final pageSize = 50.obs;
  final totalCount = 0.obs;

  // Stream Subscription for Real-time updates
  StreamSubscription<Query<EntityOrder>>? _subscription;

  double get totalAmount =>
      filteredBills.fold(0.0, (sum, item) => sum + (item.totalAmount ?? 0.0));

  @override
  void onInit() {
    super.onInit();
    // Initial Fetch
    _fetchBills();

    // Listen for changes in the box (Real-time updates)
    _subscription = _billBox.query().watch(triggerImmediately: false).listen((
      _,
    ) {
      _fetchBills();
    });
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
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
    final dr = selectedDateRange.value;

    final results = allBills.where((bill) {
      // 1. Status Check (exclude cancelled if needed, or keep all)
      // if ((bill.status ?? '').toLowerCase() == 'cancelled') return false;

      // 2. Date Filter
      if (dr != null) {
        try {
          final billDate = DateTime.tryParse(bill.createdOn ?? '');
          if (billDate != null) {
            if (billDate.isBefore(dr.start) || billDate.isAfter(dr.end)) {
              return false;
            }
          }
        } catch (_) {}
      }

      // 3. Search Filter (Bill No, Order ID)
      if (q.isNotEmpty) {
        final billNo = (bill.orderNumber ?? '').toString().toLowerCase();
        final orderId = bill.orderId.toString().toLowerCase();
        final uuid = bill.uuid.toLowerCase();

        if (!billNo.contains(q) && !orderId.contains(q) && !uuid.contains(q)) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort by Date Descending (Newest first)
    results.sort((a, b) {
      final da = DateTime.tryParse(a.createdOn ?? '') ?? DateTime(0);
      final db = DateTime.tryParse(b.createdOn ?? '') ?? DateTime(0);
      return db.compareTo(da);
    });

    totalCount.value = results.length;

    // Pagination
    final start = (currentPage.value - 1) * pageSize.value;
    final end = (start + pageSize.value).clamp(0, results.length);

    if (start < end) {
      filteredBills.assignAll(results.sublist(start, end));
    } else {
      filteredBills.clear();
    }
  }

  void applySearch() => _applyCombinedFilters();

  void clearSearch() {
    searchText.value = '';
    _applyCombinedFilters();
  }

  // FETCH BILLS
  void _fetchBills() {
    try {
      // Get all bills (could optimize with query if dataset is huge)
      final list = _billBox.getAll();
      allBills.assignAll(list);
      _applyCombinedFilters();
    } catch (e) {
      debugPrint("❌ Bill fetch error: $e");
    }
  }

  // PAGINATION
  int get totalPages =>
      (totalCount.value / pageSize.value).ceil().clamp(1, 99999);

  void nextPage() {
    if (currentPage.value < totalPages) {
      currentPage.value++;
      _applyCombinedFilters();
    }
  }

  void prevPage() {
    if (currentPage.value > 1) {
      currentPage.value--;
      _applyCombinedFilters();
    }
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      currentPage.value = page;
      _applyCombinedFilters();
    }
  }

  // EXPORT TO EXCEL
  Future<void> exportFilteredToExcelToDownloads() async {
    if (filteredBills.isEmpty) {
      Get.snackbar("Export", "No records to export");
      return;
    }

    final Excel excel = Excel.createExcel();
    final Sheet sheet = excel['Sheet1'];

    final headers = [
      "Bill Number",
      "Order Total",
      "Payment",
      "Order Id",
      "User Name",
    ];

    for (int i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(
        headers[i],
      );
    }

    int row = 1;
    for (int i = 0; i < filteredBills.length; i++) {
      final b = filteredBills[i];

      // Payment logic
      String payment = "Unpaid";
      if (b.payments.isNotEmpty) {
        payment = b.payments.map((p) => p.mode).join(", ");
      }

      final data = [
        IntCellValue(b.orderNumber ?? 0),
        DoubleCellValue(b.totalAmount ?? 0.0),
        TextCellValue(payment),
        TextCellValue(b.uuid),
        TextCellValue(b.userName ?? "Unknown"),
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
      "${dir!.path}/bill-report-${DateTime.now().millisecondsSinceEpoch}.xlsx",
    );

    await file.writeAsBytes(bytes);

    Get.snackbar("Export complete", file.path);
  }

  @override
  Future<void> refresh() async {
    _fetchBills();
  }
}
