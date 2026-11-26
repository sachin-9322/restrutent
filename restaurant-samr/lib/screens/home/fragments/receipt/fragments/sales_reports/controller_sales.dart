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
import 'package:splash_screen_03/screens/home/fragments/receipt/fragments/order_report/controller_order_report.dart';

class ControllerSales extends GetxController {
  final receipts = <Receipt>[].obs;
  final filteredReceipts = <Receipt>[].obs;

  // NEW: Grand total for all filtered items (not just the current page).
  // Use this in your UI to display the total sales for the selected filters.
  // Example: Obx(() => Text('Grand Total: ${controller.filteredTotalAmount.value.toStringAsFixed(2)}'))
  final filteredTotalAmount = 0.0.obs;
  List<String> get allWaiters => receipts
      .map((r) => r.waiter)
      .whereType<String>() // ✅ removes nulls
      .where((w) => w.trim().isNotEmpty)
      .toSet()
      .toList();
  void setWaiter(String? waiter) {
    selectedWaiter.value = waiter;
    _applyCombinedFilters();
  }

  final pageBills = <EntityOrder>[].obs;
  final currentPage = 1.obs;
  final pageSize = 10.obs;
  final totalCount = 0.obs;
  final selectedIndex = (-1).obs;
  final showColumnColors = true.obs;
  final selectedWaiter = RxnString();

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
    fetchFromBills();

    // ✅ Listen to order type changes to refresh "Unknown" labels
    if (Get.isRegistered<ControllerOrderType>()) {
      final otCtrl = Get.find<ControllerOrderType>();
      ever(otCtrl.rxOrderTypes, (_) {
        fetchFromBills();
      });
    }
  }

  // ----- setters for filters -----
  void setOrderType(String? t) {
    selectedOrderType.value = t;
    _applyCombinedFilters();
  }

  void setBillStatus(String? s) {
    selectedBillStatus.value = s;
    _applyCombinedFilters();
  }

  void setDateRange(DateTimeRange? r) {
    selectedDateRange.value = r;
    _applyCombinedFilters();
  }

  void clearFilters() {
    selectedOrderType.value = null;
    selectedBillStatus.value = null;
    selectedDateRange.value = null;
    selectedWaiter.value = null; // ✅ reset waiter filter
    clearSearch(); // ✅ resets search and applies filters
    _applyCombinedFilters(); // ✅ reapply filters to show all
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

  // in ControllerSales
  void setSearch(String v) {
    searchText.value = v;
    _applyCombinedFilters();
  }

  void _applyCombinedFilters() {
    final q = (searchText.value ?? '').trim().toLowerCase();
    final orderType = selectedOrderType.value;
    final billStatus = selectedBillStatus.value;
    final dateRange = selectedDateRange.value;
    final waiterFilter = selectedWaiter.value?.trim();

    final results = receipts.where((r) {
      // 1️⃣ Order type filter
      if (orderType != null && orderType.isNotEmpty) {
        if (r.type.toLowerCase() != orderType.toLowerCase()) return false;
      }

      // 2️⃣ Bill status filter
      if (billStatus != null && billStatus.isNotEmpty) {
        if (r.status.toLowerCase() != billStatus.toLowerCase()) return false;
      }

      // 3️⃣ Date range filter
      if (dateRange != null) {
        final dLocal = r.date.toLocal();
        if (dLocal.isBefore(dateRange.start) || dLocal.isAfter(dateRange.end)) {
          return false;
        }
      }

      // 4️⃣ Waiter filter (skip nulls/empty)
      if (waiterFilter != null && waiterFilter.isNotEmpty) {
        if (r.waiter == null || r.waiter!.trim().isEmpty) return false;
        if (r.waiter!.trim().toLowerCase() != waiterFilter.toLowerCase()) {
          return false;
        }
      }

      // 5️⃣ Search text filter
      if (q.isNotEmpty) {
        final combined =
            '${r.billNo} ${r.tableName} ${r.type} ${r.status} ${r.customer} ${r.phone} ${r.payment} ${r.waiter}'
                .toLowerCase();
        if (!combined.contains(q)) return false;
      }

      return true;
    }).toList();

    filteredReceipts.assignAll(results);

    // 💰 Recalculate total for all filtered items
    filteredTotalAmount.value = results.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );
  }

  void selectRow(int index) {
    selectedIndex.value = index;
  }

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
              if (maybe is List) items = maybe;
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
          items = oi;
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

  // In ControllerSales
  Future<void> fetchFromBills({int page = 1}) async {
    try {
      currentPage.value = page;
      final Box<EntityOrder> billsBox = Get.find<Box<EntityOrder>>();
      final allBills = billsBox.getAll();

      // Show Pending(booked), Due, and Settled in Sales
      final visibleBills = allBills.where((b) {
        final s = (b.status ?? '').toLowerCase();
        if (s == 'booked') {
          // Only show booked bills if they are explicitly saved (draft)
          return _hasSavedBillPreview(b);
        }
        return s == 'settled' || s == 'due';
      }).toList();

      // Sort newest first
      visibleBills.sort((a, b) {
        final ai = a.orderId ?? 0;
        final bi = b.orderId ?? 0;
        return bi.compareTo(ai);
      });

      totalCount.value = visibleBills.length;

      // ✅ Map ALL bills (not just a single page)
      final mappedAll = visibleBills.map((b) {
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
            final ta2 = _safeGet(dyn, 'totalAmount');
            if (ta2 != null) amount = double.tryParse(ta2) ?? 0.0;
          }
        } catch (_) {
          amount = 0.0;
        }

        // Extract customer info
        String customerName = '';
        String customerPhone = '';
        try {
          if (b.customerName != null && b.customerName!.trim().isNotEmpty) {
            customerName = b.customerName!.trim();
          }
          if (b.customerMobile != null && b.customerMobile!.trim().isNotEmpty) {
            customerPhone = b.customerMobile!.trim();
          }
        } catch (_) {}

        // Payment mode
        String paymentMode = '';

        try {
          // 1️⃣ Payment list from objectbox “payments”
          if (b.payments.isNotEmpty) {
            final modes = b.payments.map((p) => p.mode).toSet();
            paymentMode = modes.join(', ');
          }

          // 2️⃣ If still empty, try meta.paymentMode from itemsJson
          if (paymentMode.trim().isEmpty) {
            final raw = (b as dynamic).itemsJson;
            if (raw != null && raw.toString().trim().isNotEmpty) {
              final parsed = jsonDecode(raw);
              if (parsed is Map && parsed['meta'] is Map) {
                final meta = parsed['meta'] as Map;
                final pm = meta['paymentMode']?.toString() ?? '';
                if (pm.trim().isNotEmpty) paymentMode = pm.trim();
              }
            }
          }

          // 3️⃣ Default if still empty
          if (paymentMode.trim().isEmpty) {
            paymentMode = 'Cash';
          }
        } catch (_) {
          paymentMode = 'Cash';
        }

        // Map DB status -> display label
        final rawStatus = (b.status ?? '').toLowerCase();
        final displayStatus = rawStatus == 'booked' ? 'pending' : rawStatus;
        final controllerOT = Get.find<ControllerOrderType>();
        final orderTypeLabel = controllerOT.getLabelById(b.orderTypeId);
        // Date handling
        final billDate = _extractBillDate(b);
        final safeDate = (billDate ?? DateTime.now()).toLocal();
        return Receipt(
          billNo: b.orderNumber ?? 0,
          tableName: b.tableName ?? (b.orderTypeId ?? 'Unknown'),
          type: orderTypeLabel,
          status: displayStatus,
          customer: customerName.isNotEmpty ? customerName : 'Guest',
          phone: customerPhone,
          waiter: b.waiterName ?? '', // ✅ Show waiter name if available
          deliveryBoy: '',
          payment: paymentMode.trim().isNotEmpty ? paymentMode.trim() : 'N/A',
          amount: amount,
          date: safeDate,
          qty: 0,
        );
      }).toList();

      // ✅ Assign all receipts (full dataset)
      receipts.assignAll(mappedAll);

      // ✅ Apply filters globally (all pages)
      _applyCombinedFilters();

      // ⚡ Optional: still maintain current page slice for DataTable display
      final start = (page - 1) * pageSize.value;
      final end = (start + pageSize.value).clamp(0, filteredReceipts.length);
      final currentPageItems = (start < end)
          ? filteredReceipts.sublist(start, end)
          : <Receipt>[];

      // Display only this page (but filters already applied globally)
      filteredReceipts.assignAll(currentPageItems);
    } catch (e, st) {
      debugPrint('Error fetching receipts: $e\n$st');
      receipts.clear();
      pageBills.clear();
      totalCount.value = 0;
      filteredReceipts.clear();
      filteredTotalAmount.value = 0.0;
    } finally {
      update();
    }
  }

  // If you don't already have this helper:
  DateTime? _extractBillDate(EntityOrder b) {
    DateTime? parse(String? iso) {
      if (iso == null || iso.trim().isEmpty) return null;
      return DateTime.tryParse(iso);
    }

    return parse(b.endTime) ?? parse(b.createdOn) ?? parse(b.startTime);
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
      // --- MODIFIED ---
      // Recalculate total for all items
      filteredTotalAmount.value = receipts.fold(
        0.0,
        (sum, item) => sum + item.amount,
      );
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
    // --- MODIFIED ---
    // Calculate total for matched items
    filteredTotalAmount.value = matches.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );
  }

  bool _hasSavedBillPreview(EntityOrder b) {
    try {
      final j = (b as dynamic).itemsJson as String?;
      if (j == null || j.trim().isEmpty) return false;
      final d = jsonDecode(j);
      if (d is Map && d['meta'] is Map) {
        final meta = d['meta'] as Map;
        return meta['draft'] == true; // Only show when Save Bill was done
      }
    } catch (_) {}
    return false;
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

      // Header row
      final List<String> header = [
        'S.No',
        'Bill No',
        'Table',
        'Type',
        'Status',
        'Customer',
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
        cell.value = TextCellValue(header[col]);
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
          // Date (format using local time)
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
        RegExp(r'[:.]'),
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

  // Add inside ControllerSales (anywhere in the class)

  static const List<String> _knownDateKeys = [
    'billDateTime',
    'createdAt',
    'created_on',
    'createdOn',
    'billDate',
    'date',
    'orderDate',
    'orderTime',
    'orderOn',
    'timestamp',
    'time',
    'timeStamp',
    'addedOn',
    'settledOn',
    'updatedAt',
    'updated_on',
    'closedOn',
  ];

  String? _firstNonEmpty(List<String?> xs) {
    for (final s in xs) {
      if (s != null &&
          s.trim().isNotEmpty &&
          s.trim().toLowerCase() != 'null') {
        return s;
      }
    }
    return null;
  }

  DateTime? _parseDateFlexible(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v.toLocal();

    final s = v.toString().trim();
    if (s.isEmpty || s == '0' || s.toLowerCase() == 'null') return null;

    // pure numeric? (seconds/ms/microseconds since epoch)
    if (RegExp(r'^\d+$').hasMatch(s)) {
      final n = int.tryParse(s);
      if (n != null) {
        if (s.length <= 10) {
          // seconds
          return DateTime.fromMillisecondsSinceEpoch(
            n * 1000,
            isUtc: true,
          ).toLocal();
        } else if (s.length == 13) {
          // milliseconds
          return DateTime.fromMillisecondsSinceEpoch(n, isUtc: true).toLocal();
        } else if (s.length >= 16) {
          // microseconds (best-effort)
          try {
            return DateTime.fromMicrosecondsSinceEpoch(
              n,
              isUtc: true,
            ).toLocal();
          } catch (_) {}
        }
      }
    }

    // ISO/RFC formats
    final iso = DateTime.tryParse(s);
    if (iso != null) return iso.toLocal();

    // Common custom formats
    const patterns = [
      'dd/MM/yyyy HH:mm:ss',
      'dd/MM/yyyy HH:mm',
      'dd/MM/yyyy',
      'dd-MM-yyyy HH:mm:ss',
      'dd-MM-yyyy HH:mm',
      'dd-MM-yyyy',
      'yyyy-MM-dd HH:mm:ss',
      'yyyy-MM-dd HH:mm',
      'yyyy-MM-dd',
      'MM/dd/yyyy HH:mm:ss',
      'MM/dd/yyyy HH:mm',
      'MM/dd/yyyy',
    ];
    for (final p in patterns) {
      try {
        // Parse as UTC to avoid timezone ambiguities, then convert to local
        final dt = DateFormat(p).parse(s, true).toLocal();
        return dt;
      } catch (_) {}
    }

    return null;
  }

  DateTime? _scanMapForDate(Map map) {
    // Prefer more specific keys first
    final keys = map.keys.map((e) => e.toString()).toList()
      ..sort((a, b) {
        int rank(String k) {
          k = k.toLowerCase();
          if (k.contains('bill') || k.contains('created')) return 0;
          if (k.contains('order')) return 1;
          if (k.contains('date') || k.contains('time')) return 2;
          return 3;
        }

        return rank(a).compareTo(rank(b));
      });

    for (final k in keys) {
      final dt = _parseDateFlexible(map[k]);
      if (dt != null) return dt;
    }
    return null;
  }
}
