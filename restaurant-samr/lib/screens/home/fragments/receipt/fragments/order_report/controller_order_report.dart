// controller_order_report.dart
import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:splash_screen_03/objectbox.g.dart';
import 'package:splash_screen_03/model/entity_bill.dart';
import 'package:splash_screen_03/model/entity_food.dart';
import 'package:splash_screen_03/screens/home/fragments/order/controller_ordetype.dart';

class Receipt {
  final int billNo;
  final String tableName;
  final String type;
  final String status;
  final String customer;
  final String phone;
  final String deliveryBoy;
  final String payment;
  final double amount;
  final DateTime date;
  final int qty;

  // ✅ NEW optional waiter field
  final String? waiter;

  Receipt({
    required this.billNo,
    required this.tableName,
    required this.type,
    required this.status,
    required this.customer,
    required this.phone,
    required this.deliveryBoy,
    required this.payment,
    required this.amount,
    required this.date,
    required this.qty,
    this.waiter, // ✅ optional parameter
  });
}

class ControllerOrderReport extends GetxController {
  final receipts = <Receipt>[].obs;
  final filteredReceipts = <Receipt>[].obs;
  final pageBills = <EntityOrder>[].obs;
  final currentPage = 1.obs;
  final pageSize = 10.obs;
  final totalCount = 0.obs;
  final selectedIndex = (-1).obs;
  final showColumnColors = true.obs;

  final searchText = ''.obs;

  // date filter
  final selectedDateRange = Rxn<DateTimeRange>();

  int get totalPages =>
      (totalCount.value / (pageSize.value == 0 ? 1 : pageSize.value))
          .ceil()
          .clamp(1, 9999);

  StreamSubscription? _subscription;

  @override
  void onInit() {
    super.onInit();
    // Initial fetch and listen for changes
    final billsBox = Get.find<Box<EntityOrder>>();
    _subscription = billsBox.query().watch(triggerImmediately: true).listen((
      _,
    ) {
      fetchFromBills();
    });
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }

  // --- NEW: Added getDateLabel method ---
  String getDateLabel(DateTimeRange? dr, DateFormat df) {
    if (dr == null) {
      return 'All Time';
    }
    final today = DateTime.now();
    final start = dr.start;
    final end = dr.end;
    final sameDay =
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    final isToday =
        sameDay &&
        start.year == today.year &&
        start.month == today.month &&
        start.day == today.day;
    final yesterday = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 1));
    final isYesterday =
        sameDay &&
        start.year == yesterday.year &&
        start.month == yesterday.month &&
        start.day == yesterday.day;

    if (isToday) {
      return 'Today';
    } else if (isYesterday) {
      return 'Yesterday';
    } else if (sameDay) {
      return df.format(dr.start);
    } else {
      return '${df.format(dr.start)} - ${df.format(dr.end)}';
    }
  }

  // ----- setters for filters -----
  void setDateRange(DateTimeRange? r) {
    selectedDateRange.value = r;
    _applyCombinedFilters();
  }

  // --- NEW: Added clearDateRange method ---
  void clearDateRange() {
    setDateRange(null);
  }

  void clearFilters() {
    selectedDateRange.value = null;
    clearSearch();
    _applyCombinedFilters();
  }

  // --- Date preset methods ---
  void presetToday() {
    final start = DateTime.now();
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(start.year, start.month, start.day, 23, 59, 59);
    setDateRange(DateTimeRange(start: s, end: e));
  }

  void presetYesterday() {
    final now = DateTime.now();
    final y = now.subtract(const Duration(days: 1));
    final s = DateTime(y.year, y.month, y.day);
    final e = DateTime(y.year, y.month, y.day, 23, 59, 59);
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

  void _applyCombinedFilters() {
    final q = (searchText.value).trim().toLowerCase();
    final dateRange = selectedDateRange.value;

    final results = receipts.where((r) {
      if (dateRange != null) {
        final dLocal = r.date.toLocal();
        if (dLocal.isBefore(dateRange.start) || dLocal.isAfter(dateRange.end)) {
          return false;
        }
      }

      if (q.isNotEmpty) {
        if (!r.type.toLowerCase().contains(q)) return false;
      }

      return true;
    }).toList();

    filteredReceipts.assignAll(results);
  }

  void selectRow(int index) {
    selectedIndex.value = index;
  }

  // All other methods from your controller remain here...
  // (buildGroupedItemsFromBill, _extractQtyFromBill, colorForStatus, etc.)
  Map<String, List<MapEntry<EntityFood, int>>> buildGroupedItemsFromBill(
    EntityOrder bill,
  ) {
    final Map<String, List<MapEntry<EntityFood, int>>> grouped = {};
    List<dynamic>? items;

    try {
      final itemsJsonStr =
          (bill.itemsJson != null && bill.itemsJson!.trim().isNotEmpty)
          ? bill.itemsJson!
          : _safeGet(bill, 'itemsJson');

      if (itemsJsonStr != null && itemsJsonStr.trim().isNotEmpty) {
        final parsed = jsonDecode(itemsJsonStr);
        if (parsed is List)
          items = parsed;
        else if (parsed is Map) {
          if (parsed['items'] is List)
            items = parsed['items'] as List<dynamic>;
          else if (parsed['data'] is List)
            items = parsed['data'] as List<dynamic>;
        }
      }
    } catch (_) {}

    if (items == null) {
      try {
        // first try concrete field if present
        final orderItemsJsonStr =
            (bill as dynamic).orderItemsJson != null &&
                (bill as dynamic).orderItemsJson.toString().trim().isNotEmpty
            ? (bill as dynamic).orderItemsJson.toString()
            : _safeGet(bill, 'orderItemsJson');

        if (orderItemsJsonStr != null && orderItemsJsonStr.trim().isNotEmpty) {
          final parsed = jsonDecode(orderItemsJsonStr);
          if (parsed is List)
            items = parsed;
          else if (parsed is Map) {
            if (parsed['items'] is List)
              items = parsed['items'] as List<dynamic>;
          }
        } else {
          final dyn = bill as dynamic;
          final oi = dyn.orderItems ?? dyn.order_items;
          if (oi is List) items = oi;
        }
      } catch (_) {}
    }

    if (items == null) {
      return grouped;
    }

    final entries = <MapEntry<EntityFood, int>>[];
    for (final rawEntry in items) {
      try {
        if (rawEntry == null) continue;
        final Map<String, dynamic> e;
        if (rawEntry is Map<String, dynamic>) {
          e = rawEntry;
        } else if (rawEntry is Map) {
          e = Map<String, dynamic>.from(rawEntry);
        } else {
          continue;
        }

        final rawId = e['id'] ?? e['foodId'] ?? e['food_id'] ?? e['item_id'];
        final rawName =
            e['name'] ??
            e['foodName'] ??
            e['food_name'] ??
            e['title'] ??
            e['item'];
        final rawQty = e['qty'] ?? e['quantity'] ?? e['count'] ?? e['q'] ?? 1;
        final rawPrice =
            e['price'] ?? e['sellPrice'] ?? e['amount'] ?? e['rate'] ?? 0.0;

        final int qty = rawQty is int
            ? rawQty
            : int.tryParse(rawQty?.toString() ?? '') ??
                  (rawQty is double ? rawQty.toInt() : 1);

        final int foodIdSafe = rawId is int
            ? rawId
            : (int.tryParse(rawId?.toString() ?? '') ?? 0);
        final String foodNameSafe = rawName?.toString() ?? 'Item';

        final ef = EntityFood(
          foodId: foodIdSafe,
          foodName: foodNameSafe,
          categoryName: null,
        );

        try {
          final double numericPrice = (rawPrice is num)
              ? rawPrice.toDouble()
              : double.tryParse(rawPrice?.toString() ?? '') ?? 0.0;
          (ef as dynamic).price = [
            {
              'price': numericPrice,
              'currency': e['currency'] ?? '',
              'roomType': e['roomType'] ?? '',
            },
          ];
          (ef as dynamic).__orig_amount = e['amount'];
        } catch (_) {}
        entries.add(MapEntry(ef, qty));
      } catch (e, st) {
        debugPrint('Error processing item for bill ${bill.orderId}: $e\n$st');
      }
    }

    if (entries.isNotEmpty) grouped['Items'] = entries;
    return grouped;
  }

  int extractQtyFromBill(EntityOrder b) {
    // 0) Prefer the concrete persistent summary field if present.
    try {
      if (b.totalQty != null && b.totalQty! > 0) return b.totalQty!;
    } catch (_) {}

    // 1) Try dynamic orderItems list (concrete or dynamic)
    try {
      final dyn = b as dynamic;
      // prefer concrete orderItems if present on object
      final dynamicOrderItems = dyn.orderItems ?? dyn.order_items ?? dyn.items;
      if (dynamicOrderItems != null &&
          dynamicOrderItems is List &&
          dynamicOrderItems.isNotEmpty) {
        final sum = dynamicOrderItems.fold<int>(0, (s, it) {
          try {
            if (it == null) return s;
            if (it is Map) {
              final q = it['qty'] ?? it['quantity'] ?? it['count'] ?? 0;
              return s +
                  (q is int ? q : int.tryParse(q?.toString() ?? '') ?? 0);
            } else {
              return s;
            }
          } catch (_) {
            return s;
          }
        });
        if (sum > 0) return sum;
      }
    } catch (_) {}

    // 2) Try explicit summary fields on bill or safe-get
    try {
      final dyn = b as dynamic;
      final candidates = <dynamic>[
        // concrete field first
        b.totalQty,
        // other possible dynamic props
        dyn.totalQuantity,
        dyn.total_items,
        _safeGet(dyn, 'totalQty'),
        _safeGet(dyn, 'totalQuantity'),
        _safeGet(dyn, 'total_items'),
      ];
      for (final c in candidates) {
        if (c == null) continue;
        final parsed = c is int ? c : int.tryParse(c.toString());
        if (parsed != null && parsed > 0) return parsed;
      }
    } catch (_) {}

    // 3) Parse itemsJson / orderItemsJson / metaJson (prefer concrete fields)
    try {
      final dyn = b as dynamic;
      final itemsJsonStr =
          (b.itemsJson != null && b.itemsJson!.trim().isNotEmpty)
          ? b.itemsJson!
          : ((dyn.orderItemsJson != null &&
                    dyn.orderItemsJson.toString().trim().isNotEmpty)
                ? dyn.orderItemsJson.toString()
                : _safeGet(dyn, 'itemsJson') ??
                      _safeGet(dyn, 'orderItemsJson') ??
                      _safeGet(dyn, 'metaJson'));

      if (itemsJsonStr != null && itemsJsonStr.trim().isNotEmpty) {
        final parsed = jsonDecode(itemsJsonStr);
        if (parsed is Map) {
          // meta.totalQty or parsed['items'] list
          if (parsed['meta'] is Map && parsed['meta']['totalQty'] != null) {
            final t = parsed['meta']['totalQty'];
            final parsedT = t is int ? t : int.tryParse(t.toString());
            if (parsedT != null && parsedT > 0) return parsedT;
          }
          if (parsed['items'] is List) {
            final sum = (parsed['items'] as List).fold<int>(0, (s, it) {
              try {
                if (it is Map) {
                  final q = it['qty'] ?? it['quantity'] ?? it['count'] ?? 0;
                  return s +
                      (q is int ? q : int.tryParse(q?.toString() ?? '') ?? 0);
                }
                return s;
              } catch (_) {
                return s;
              }
            });
            if (sum > 0) return sum;
          }
        } else if (parsed is List) {
          final sum = parsed.fold<int>(0, (s, it) {
            try {
              if (it is Map) {
                final q = it['qty'] ?? it['quantity'] ?? it['count'] ?? 0;
                return s +
                    (q is int ? q : int.tryParse(q?.toString() ?? '') ?? 0);
              }
              return s;
            } catch (_) {
              return s;
            }
          });
          if (sum > 0) return sum;
        }
      }
    } catch (_) {}

    // 4) Fallback to grouped items builder (your existing logic)
    try {
      final grouped = buildGroupedItemsFromBill(b);
      final sum = grouped.values
          .expand((l) => l)
          .fold<int>(0, (s, e) => s + e.value);
      if (sum > 0) return sum;
    } catch (_) {}

    // 5) final fallback 0
    return 0;
  }

  Color colorForStatus(String status) {
    final s = status.toLowerCase();
    if (s.contains('settled') ||
        s.contains('ful') ||
        s.contains('complete') ||
        s.contains('done')) {
      return const Color(0xFF2E7D32);
    }
    if (s.contains('cancel') || s.contains('refunded'))
      return Colors.red.shade700;
    if (s.contains('pending')) return Colors.orange.shade700;
    if (s.contains('booked')) return Colors.deepOrange.shade700;
    return Colors.blueGrey.shade700;
  }

  Color colorForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('dine')) return const Color(0xFF546E7A);
    if (t.contains('take') || t.contains('pickup') || t.contains('quick'))
      return Colors.indigo.shade700;
    if (t.contains('delivery')) return Colors.deepPurple.shade700;
    return Colors.grey.shade600;
  }

  String? _safeGet(dynamic dyn, String prop) {
    try {
      if (dyn == null) return null;
      // if it's an object with a map-like interface attempt dynamic access
      try {
        final val = (dyn as dynamic)[prop];
        return val?.toString();
      } catch (_) {
        // try toJson if exists
        try {
          if ((dyn as dynamic).toJson != null) {
            final map = (dyn as dynamic).toJson();
            return map[prop]?.toString();
          }
        } catch (_) {}
        if (dyn is Map) return dyn[prop]?.toString();
      }
    } catch (_) {}
    return null;
  }

  Future<void> fetchFromBills({int page = 1}) async {
    try {
      final Box<EntityOrder> billsBox = Get.find<Box<EntityOrder>>();
      final allBills = billsBox.getAll();

      // 1️⃣ Filter only settled
      final settledBills = allBills
          .where((bill) => (bill.status?.toLowerCase() ?? '') == 'settled')
          .toList();

      // 2️⃣ Convert ALL settled bills into Receipt objects
      final controllerOT = Get.put(ControllerOrderType());
      final mapped = settledBills.map((b) {
        final typeName = controllerOT.getLabelById(b.orderTypeId);
        return Receipt(
          billNo: b.orderNumber ?? 0,
          tableName: b.tableName ?? typeName,
          type: typeName,
          status: b.status ?? 'N/A',
          customer: '',
          phone: '',
          deliveryBoy: '',
          payment: '',
          amount: (b.totalAmount ?? 0).toDouble(),
          date: DateTime.now(),
          qty: extractQtyFromBill(b),
        );
      }).toList();

      // 3️⃣ GROUP ALL bills (NOT pageSlice)
      final Map<String, List<Receipt>> grouped = {};

      for (final r in mapped) {
        final key = r.type.trim().toLowerCase();
        grouped.putIfAbsent(key, () => []);
        grouped[key]!.add(r);
      }

      // 4️⃣ BUILD grouped summary list
      final List<Receipt> groupedSummary = grouped.entries.map((entry) {
        final list = entry.value;

        final totalAmt = list.fold<double>(0.0, (sum, r) => sum + r.amount);
        final count = list.length;

        return Receipt(
          billNo: 0,
          tableName: list.first.tableName,
          type: list.first.type,
          status: list.first.status,
          customer: '',
          phone: '',
          deliveryBoy: '',
          payment: '',
          amount: totalAmt,
          date: list.first.date,
          qty: count,
        );
      }).toList();

      // ⭐️ NOW paginate the GROUPED results
      totalCount.value = groupedSummary.length;
      final start = (page - 1) * pageSize.value;
      final end = (start + pageSize.value).clamp(0, groupedSummary.length);

      final paginated = (start < end)
          ? groupedSummary.sublist(start, end)
          : <Receipt>[];

      receipts.assignAll(paginated);
      filteredReceipts.assignAll(paginated);

      _applyCombinedFilters();
      update();
    } catch (e) {
      print(e);
    }
  }

  void nextPage() {
    if (currentPage.value < totalPages) {
      fetchFromBills(page: currentPage.value + 1);
    }
  }

  void prevPage() {
    if (currentPage.value > 1) {
      fetchFromBills(page: currentPage.value - 1);
    }
  }

  void goToPage(int p) {
    if (p >= 1 && p <= totalPages) fetchFromBills(page: p);
  }

  void applySearch() {
    _applyCombinedFilters();
  }

  void clearSearch() {
    searchText.value = '';
    _applyCombinedFilters();
  }

  Future<void> exportFilteredToExcelToDownloads() async {
    try {
      if (filteredReceipts.isEmpty) {
        Get.snackbar(
          'Export',
          'No records to export',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final Excel excel = Excel.createExcel();
      final String sheetName = excel.getDefaultSheet() ?? 'Sheet1';
      final Sheet sheetObject = excel[sheetName];

      final List<String> header = [
        'S.No',
        'Bill No',
        'Table',
        'Type',
        'Status',
        'Username',
        'Phone',
        'Payment',
        'Amount',
        'Qty',
        'Date',
      ];

      for (int col = 0; col < header.length; col++) {
        final cell = sheetObject.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
        );
        cell.value = TextCellValue(header[col]);
      }

      int rowIndex = 1;
      for (var i = 0; i < filteredReceipts.length; i++, rowIndex++) {
        final r = filteredReceipts[i];
        final List<CellValue?> rowValues = [
          IntCellValue(i + 1),
          IntCellValue(r.billNo),
          TextCellValue(r.tableName),
          TextCellValue(r.type),
          TextCellValue(r.status),
          TextCellValue(r.customer),
          TextCellValue(r.phone),
          TextCellValue(r.payment),
          DoubleCellValue(r.amount),
          IntCellValue(r.qty),
          TextCellValue(
            DateFormat('dd MMM yyyy, HH:mm').format(r.date.toLocal()),
          ),
        ];

        for (int col = 0; col < rowValues.length; col++) {
          final cell = sheetObject.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex),
          );
          cell.value = rowValues[col];
        }
      }

      final List<int>? bytes = excel.encode();
      if (bytes == null || bytes.isEmpty) {
        Get.snackbar(
          'Export',
          'Failed to create Excel file',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      Directory? targetDir;
      try {
        targetDir = await getDownloadsDirectory();
      } catch (_) {
        targetDir = null;
      }
      targetDir ??= await getTemporaryDirectory();

      final String timestamp = DateTime.now().toIso8601String().replaceAll(
        ':',
        '-',
      );
      final String fileName = 'sales-export-$timestamp.xlsx';
      final File outFile = File('${targetDir.path}/$fileName');

      await outFile.writeAsBytes(bytes, flush: true);

      Get.snackbar(
        'Export complete',
        'Saved to: ${outFile.path}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );

      if (Platform.isWindows) {
        try {
          Process.run('explorer', [targetDir.path]);
        } catch (e) {
          debugPrint('Could not open Explorer: $e');
        }
      }
    } catch (e, st) {
      debugPrint('Export failed: $e\n$st');
      Get.snackbar(
        'Export failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
