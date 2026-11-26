// controller_sales.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:excel/excel.dart';
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
  final DateTime date; // <-- added date

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
  });
}

class ControllerTodayReports extends GetxController {
  final receipts = <Receipt>[].obs;
  final filteredReceipts = <Receipt>[].obs;
  final pageBills = <EntityOrder>[].obs;
  final currentPage = 1.obs;
  final pageSize = 10.obs;
  final totalCount = 0.obs;
  final selectedIndex = (-1).obs;
  final showColumnColors = true.obs;

  final searchText = ''.obs;
  final showOnlyMatches = false.obs;

  // date filter
  final selectedDateRange = Rxn<DateTimeRange>();

  // order/status filters
  final selectedOrderType = RxnString();
  final selectedBillStatus = RxnString();

  int get totalPages =>
      (totalCount.value / (pageSize.value == 0 ? 1 : pageSize.value))
          .ceil()
          .clamp(1, 9999);

  @override
  void onInit() {
    super.onInit();
    fetchFromBills().then((_) {
      // Default filter: Today
      presetToday();
    });
  }

  // ----- setters for filters -----
  void setOrderType(String? t) {
    selectedOrderType.value = t;
    applyCombinedFilters();
  }

  void setBillStatus(String? s) {
    selectedBillStatus.value = s;
    applyCombinedFilters();
  }

  void setDateRange(DateTimeRange? r) {
    selectedDateRange.value = r;
    applyCombinedFilters();
  }

  void clearFilters() {
    selectedOrderType.value = null;
    selectedBillStatus.value = null;
    // instead of clearing, reset to today
    presetToday();
    clearSearch();
  }

  // preset helpers (optional)
  void presetToday() {
    final start = DateTime.now();
    final s = DateTime(start.year, start.month, start.day, 0, 0, 0);
    final e = DateTime(start.year, start.month, start.day, 23, 59, 59);
    setDateRange(DateTimeRange(start: s, end: e));
  }

  void presetYesterday() {
    final now = DateTime.now();
    final y = now.subtract(const Duration(days: 1));
    final s = DateTime(y.year, y.month, y.day, 0, 0, 0);
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

  // 🔹 Clears date filter (used for "All Time" option)
  void clearDateFilter() {
    selectedDateRange.value = null;
    applyCombinedFilters();
  }

  List<String> get allOrderTypes =>
      receipts.map((r) => r.type).where((e) => e.isNotEmpty).toSet().toList();

  List<String> get allStatuses =>
      receipts.map((r) => r.status).where((e) => e.isNotEmpty).toSet().toList();

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

  // combined filtering: search text + type + status + date range
  void applyCombinedFilters() {
    final q = (searchText.value ?? '').trim().toLowerCase();
    final orderType = selectedOrderType.value;
    final billStatus = selectedBillStatus.value;
    var dateRange = selectedDateRange.value;

    // if still null (somehow), default to today
    if (dateRange == null) {
      final now = DateTime.now();
      final s = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final e = DateTime(now.year, now.month, now.day, 23, 59, 59);
      dateRange = DateTimeRange(start: s, end: e);
    }

    final results = receipts.where((r) {
      if (orderType != null && orderType.isNotEmpty) {
        if (r.type.toLowerCase() != orderType.toLowerCase()) return false;
      }

      if (billStatus != null && billStatus.isNotEmpty) {
        if (r.status.toLowerCase() != billStatus.toLowerCase()) return false;
      }

      if (dateRange != null) {
        if (r.date.isBefore(dateRange.start) || r.date.isAfter(dateRange.end)) {
          return false;
        }
      }

      if (q.isNotEmpty) {
        final combined =
            '${r.billNo} ${r.tableName} ${r.type} ${r.status} ${r.customer} ${r.phone} ${r.payment}'
                .toLowerCase();
        if (!combined.contains(q)) return false;
      }

      return true;
    }).toList();

    filteredReceipts.assignAll(results);
  }

  void selectRow(int index) {
    selectedIndex.value = index;
  }

  // ... existing buildGroupedItemsFromBill, color helpers, _safeGet remain unchanged ...
  Map<String, List<MapEntry<EntityFood, int>>> buildGroupedItemsFromBill(
    EntityOrder bill,
  ) {
    final Map<String, List<MapEntry<EntityFood, int>>> grouped = {};
    try {
      debugPrint(
        'Inspecting bill id=${bill.orderId} number=${bill.orderNumber}',
      );
    } catch (_) {}
    // (existing robust item parsing — same as your current code)
    List<dynamic>? items;
    try {
      final itemsJsonStr = _safeGet(bill, 'itemsJson');
      if (itemsJsonStr != null && itemsJsonStr.trim().isNotEmpty) {
        try {
          final parsed = jsonDecode(itemsJsonStr);
          if (parsed is List) {
            items = parsed;
          } else if (parsed is Map) {
            if (parsed['items'] is List)
              items = parsed['items'] as List<dynamic>;
            else if (parsed['data'] is List)
              items = parsed['data'] as List<dynamic>;
            else {
              final maybe = parsed.values.firstWhere(
                (v) => v is List,
                orElse: () => null,
              );
              if (maybe is List) items = maybe as List<dynamic>;
            }
          }
        } catch (e, st) {
          debugPrint(
            'itemsJson jsonDecode error for bill ${bill.orderId}: $e\n$st',
          );
        }
      }
    } catch (_) {}

    if (items == null) {
      try {
        final orderItemsJson =
            _safeGet(bill, 'orderItemsJson') ?? _safeGet(bill, 'orderItems');
        if (orderItemsJson != null && orderItemsJson.trim().isNotEmpty) {
          try {
            final parsed = jsonDecode(orderItemsJson);
            if (parsed is List) items = parsed;
          } catch (_) {}
        }
      } catch (_) {}
    }

    if (items == null) {
      try {
        final dyn = bill as dynamic;
        final oi = (dyn as dynamic).orderItems;
        if (oi != null && oi is List) {
          items = oi as List<dynamic>;
          debugPrint('Using dynamic orderItems for bill ${bill.orderId}');
        }
      } catch (_) {}
    }

    if (items == null) {
      debugPrint(
        '⚠️ No items found in bill id=${bill.orderId}, orderNumber=${bill.orderNumber}',
      );
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

  // color helpers (unchanged)
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
      final val = dyn?.toJson != null
          ? (dyn as dynamic)[prop]
          : (dyn is Map
                ? dyn[prop]
                : (dyn == null ? null : (dyn as dynamic)[prop]));
      return val?.toString();
    } catch (_) {
      try {
        final val = dyn?.noSuchMethod != null
            ? (dyn as dynamic).toJson()[prop]
            : null;
        return val?.toString();
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> fetchFromBills({int page = 1}) async {
    try {
      currentPage.value = page;
      final Box<EntityOrder> billsBox = Get.find<Box<EntityOrder>>();
      final allBills = billsBox.getAll();

      // Filter only settled bills (you may change this behavior)
      final settledBills = allBills
          .where((bill) => (bill.status?.toLowerCase() ?? '') == 'settled')
          .toList();

      settledBills.sort((a, b) {
        final ai = a.orderId ?? 0;
        final bi = b.orderId ?? 0;
        return bi.compareTo(ai);
      });

      totalCount.value = settledBills.length;
      final start = (page - 1) * pageSize.value;
      final end = (start + pageSize.value).clamp(0, settledBills.length);
      final pageSlice = (start < end)
          ? settledBills.sublist(start, end)
          : <EntityOrder>[];

      pageBills.assignAll(pageSlice);

      final mapped = pageSlice.map((b) {
        double amount = 0.0;
        try {
          final dyn = b as dynamic;
          if (dyn.totalAmount != null) {
            final ta = dyn.totalAmount;
            if (ta is double)
              amount = ta;
            else if (ta is int)
              amount = ta.toDouble();
            else if (ta is String)
              amount = double.tryParse(ta) ?? 0.0;
          } else {
            final dyn2 = b as dynamic;
            final ta2 = _safeGet(dyn2, 'totalAmount');
            if (ta2 != null) amount = double.tryParse(ta2) ?? 0.0;
          }
        } catch (_) {
          amount = 0.0;
        }

        String customerName = '';
        String customerPhone = '';

        try {
          final dyn = b as dynamic;
          if (b.customerName != null && b.customerName!.trim().isNotEmpty) {
            customerName = b.customerName!.trim();
          }
          if (b.customerMobile != null && b.customerMobile!.trim().isNotEmpty) {
            customerPhone = b.customerMobile!.trim();
          }

          if ((customerName.isEmpty || customerPhone.isEmpty)) {
            try {
              final metaJsonStr = _safeGet(dyn, 'metaJson');
              if (metaJsonStr != null && metaJsonStr.trim().isNotEmpty) {
                final parsedMeta = jsonDecode(metaJsonStr);
                if (parsedMeta is Map) {
                  customerName = customerName.isNotEmpty
                      ? customerName
                      : (parsedMeta['customerName']?.toString() ?? '');
                  customerPhone = customerPhone.isNotEmpty
                      ? customerPhone
                      : (parsedMeta['customerMobile']?.toString() ?? '');
                }
              }
            } catch (_) {}
          }

          if ((customerName.isEmpty || customerPhone.isEmpty)) {
            try {
              final itemsJsonStr = _safeGet(dyn, 'itemsJson');
              if (itemsJsonStr != null && itemsJsonStr.trim().isNotEmpty) {
                final parsed = jsonDecode(itemsJsonStr);
                if (parsed is Map && parsed['meta'] is Map) {
                  customerName = customerName.isNotEmpty
                      ? customerName
                      : (parsed['meta']['customerName']?.toString() ?? '');
                  customerPhone = customerPhone.isNotEmpty
                      ? customerPhone
                      : (parsed['meta']['customerMobile']?.toString() ?? '');
                }
              }
            } catch (_) {}
          }

          if (customerPhone.isEmpty) {
            final possiblePhones = <String?>[
              _safeGet(dyn, 'customerMobile'),
              _safeGet(dyn, 'customerPhone'),
              _safeGet(dyn, 'phone'),
              _safeGet(dyn, 'mobile'),
              _safeGet(dyn, 'phoneNumber'),
            ];
            final firstPhone = possiblePhones.firstWhere(
              (p) => p != null && p.toString().trim().isNotEmpty,
              orElse: () => null,
            );
            customerPhone = firstPhone?.toString() ?? '';
          }

          if (customerName.trim().isEmpty) {
            final possibleName =
                <String?>[
                  _safeGet(dyn, 'customerName'),
                  _safeGet(dyn, 'customer'),
                  _safeGet(dyn, 'userName'),
                  b.userName,
                ].firstWhere(
                  (s) => s != null && s.toString().trim().isNotEmpty,
                  orElse: () => null,
                );
            customerName = possibleName?.toString() ?? (b.userName ?? '');
          }
        } catch (e, st) {
          debugPrint(
            'fetchFromBills: extraction failed for bill ${b.orderId}: $e\n$st',
          );
          customerName = b.userName ?? '';
          customerPhone = '';
        }

        // attempt to read a date from EntityOrder - try common fields
        DateTime billDate = DateTime.now();
        try {
          final dyn = b as dynamic;
          // Try known fields
          final cand =
              dyn.createdAt ??
              dyn.date ??
              dyn.billDate ??
              _safeGet(dyn, 'createdAt') ??
              _safeGet(dyn, 'date') ??
              _safeGet(dyn, 'billDate');
          if (cand != null) {
            if (cand is DateTime) {
              billDate = cand;
            } else if (cand is int) {
              billDate = DateTime.fromMillisecondsSinceEpoch(cand);
            } else {
              // try parse string
              final parsed = DateTime.tryParse(cand.toString());
              if (parsed != null) billDate = parsed;
            }
          }
        } catch (_) {
          // fallback: use now
        }
        final controllerOT = Get.find<ControllerOrderType>();
        final orderTypeLabel = controllerOT.getLabelById(b.orderTypeId);
        return Receipt(
          billNo: b.orderNumber ?? 0,
          tableName: b.tableName ?? (b.orderTypeId ?? 'Unknown'),
          type: orderTypeLabel,
          status: b.status ?? 'N/A',
          customer: customerName.isNotEmpty ? customerName : 'Guest',
          phone: customerPhone,
          deliveryBoy: '',
          payment: '',
          amount: amount,
          date: billDate,
        );
      }).toList();

      receipts.assignAll(mapped);
      filteredReceipts.assignAll(mapped);
      // apply search/filter after loading
      applyCombinedFilters();
    } catch (e, st) {
      debugPrint('Error fetching receipts: $e\n$st');
      receipts.clear();
      pageBills.clear();
      totalCount.value = 0;
      filteredReceipts.clear();
    } finally {
      update();
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

  // search-only fallback (kept for compatibility)
  void applySearch() {
    final q = (searchText.value ?? '').trim().toLowerCase();

    if (q.isEmpty) {
      filteredReceipts.assignAll(receipts);
      return;
    }

    final matches = receipts.where((r) {
      final combined =
          '${r.billNo} ${r.tableName} ${r.type} ${r.status} ${r.customer} ${r.phone} ${r.payment}'
              .toLowerCase();
      return combined.contains(q);
    }).toList();

    if (matches.isEmpty) {
      filteredReceipts.clear();
    } else {
      filteredReceipts.assignAll(matches);
    }
  }

  void clearSearch() {
    searchText.value = '';
    filteredReceipts.assignAll(receipts);
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

      // Header row
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
        'Date',
      ];

      // Row 0 = header
      for (int col = 0; col < header.length; col++) {
        final cell = sheetObject.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
        );
        cell.value = TextCellValue(header[col]); // ✅ wrap in TextCellValue
      }

      // Data rows
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
          TextCellValue(DateFormat('dd MMM yyyy, HH:mm').format(r.date)),
        ];

        for (int col = 0; col < rowValues.length; col++) {
          final cell = sheetObject.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex),
          );
          cell.value = rowValues[col];
        }
      }

      // Encode file
      final List<int>? bytes = excel.encode();
      if (bytes == null || bytes.isEmpty) {
        Get.snackbar(
          'Export',
          'Failed to create Excel file',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Save in Downloads (fallback temp)
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

      // Auto-open folder on Windows
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
