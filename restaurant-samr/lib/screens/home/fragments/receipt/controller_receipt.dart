import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Condition;
import 'package:intl/intl.dart';
import 'package:splash_screen_03/objectbox.g.dart';
import 'package:splash_screen_03/model/entity_bill.dart';
import 'package:splash_screen_03/model/entity_receipt.dart';
import 'package:splash_screen_03/model/entity_payment.dart';
import 'package:splash_screen_03/screens/home/fragments/order/controller_ordetype.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/controller_setting.dart';

class ReceiptController extends GetxController {
  late final Box<EntityOrder> _billsBox;
  late final ControllerSetting _settings;

  final RxBool isLoading = true.obs;
  final RxList<Receipt> filteredReceipts = <Receipt>[].obs;
  final RxList<EntityOrder> pageBills = <EntityOrder>[].obs;

  final RxInt currentPage = 1.obs;
  final RxInt totalCount = 0.obs;
  final int pageSize = 10;
  final RxDouble grossTotal = 0.0.obs;

  final RxString searchText = ''.obs;
  Timer? _debounce;
  StreamSubscription? _boxSubscription;

  int get totalPages => (totalCount.value / pageSize).ceil().clamp(1, 9999);
  String get currencyLabel => _settings.currCode;
  // --- Waiter Filter ---
  final RxString selectedWaiterFilter = 'All Waiters'.obs;

  List<String> get allWaiters {
    final all = _billsBox.getAll();
    return all
        .map((b) => b.waiterName)
        .whereType<String>()
        .where((w) => w.trim().isNotEmpty)
        .toSet()
        .toList();
  }

  void filterByWaiter(String waiter) {
    selectedWaiterFilter.value = waiter;
    _applyCombinedFilters();
  }

  @override
  void onInit() {
    super.onInit();
    try {
      _billsBox = Get.find<Box<EntityOrder>>();
      _settings = Get.find<ControllerSetting>();
    } catch (e) {
      Get.rawSnackbar(
        title: "Initialization Error",
        message: "Could not find required services. Restart the app. ($e)",
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 6),
      );
      isLoading.value = false;
      return;
    }
    fetchFromBills(page: 1);

    // ✅ Listen for database changes to auto-refresh
    _boxSubscription = _billsBox
        .query()
        .watch(triggerImmediately: false)
        .listen((_) {
          fetchFromBills(page: currentPage.value);
        });
  }

  @override
  void onClose() {
    _debounce?.cancel();
    _boxSubscription?.cancel();
    super.onClose();
  }

  /// ✅ Fetch receipts (latest bill first)
  Future<void> fetchFromBills({int page = 1}) async {
    isLoading.value = true;
    try {
      currentPage.value = page;
      final queryText = searchText.value.trim();

      Condition<EntityOrder> statusCondition = EntityOrder_.status
          .equals('booked', caseSensitive: false)
          .or(EntityOrder_.status.equals('settled', caseSensitive: false))
          .or(EntityOrder_.status.equals('due', caseSensitive: false))
          .or(EntityOrder_.status.equals('cancelled', caseSensitive: false));

      if (queryText.isNotEmpty) {
        final billNumber = int.tryParse(queryText);
        var textSearchCondition = EntityOrder_.tableName
            .contains(queryText, caseSensitive: false)
            .or(
              EntityOrder_.customerName.contains(
                queryText,
                caseSensitive: false,
              ),
            )
            .or(EntityOrder_.status.contains(queryText, caseSensitive: false));

        if (billNumber != null) {
          textSearchCondition = textSearchCondition.or(
            EntityOrder_.orderNumber.equals(billNumber),
          );
        }
        statusCondition = statusCondition.and(textSearchCondition);
      }

      // ✅ Build query and sort latest first
      final builder = _billsBox.query(statusCondition)
        ..order(EntityOrder_.orderNumber, flags: Order.descending);
      final query = builder.build();
      final allBills = query.find();
      query.close();

      // ✅ Compute totals
      grossTotal.value = allBills.fold(
        0.0,
        (sum, b) => sum + (b.totalAmount ?? 0.0),
      );

      // ✅ Pagination
      totalCount.value = allBills.length;
      final offset = (page - 1) * pageSize;

      // FILTER: Exclude 'booked' bills that are NOT drafts (i.e. KOT only)
      final validBills = allBills.where(_shouldShowBill).toList();

      // Re-calculate total count based on valid bills
      totalCount.value = validBills.length;

      // Re-calculate gross total based on valid bills
      grossTotal.value = validBills.fold(
        0.0,
        (sum, b) => sum + (b.totalAmount ?? 0.0),
      );

      final pageSubset = validBills.skip(offset).take(pageSize).toList();

      pageBills.assignAll(pageSubset);
      filteredReceipts.assignAll(pageSubset.map(_mapBillToReceipt).toList());
    } catch (e, st) {
      Get.snackbar(
        'Error',
        'Failed to fetch receipts: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      debugPrint('❌ Error fetching receipts: $e\n$st');
    } finally {
      isLoading.value = false;
    }
  }

  // 🔸 Filters
  final RxString selectedOrderFilter = 'All Orders'.obs;
  final RxString selectedStatusFilter = 'All Bills'.obs;

  void filterByOrderType(String type) {
    selectedOrderFilter.value = type;
    if (type == 'All Orders') {
      fetchFromBills(page: 1);
      return;
    }

    final allBills = _billsBox
        .query(
          EntityOrder_.status
              .equals('booked', caseSensitive: false)
              .or(EntityOrder_.status.equals('settled', caseSensitive: false))
              .or(EntityOrder_.status.equals('due', caseSensitive: false))
              .or(
                EntityOrder_.status.equals('cancelled', caseSensitive: false),
              ),
        )
        .order(EntityOrder_.orderNumber, flags: Order.descending)
        .build()
        .find();

    final normalizedType = type.toLowerCase().replaceAll('-', ' ').trim();
    final filtered = allBills
        .where((b) {
          if (!_shouldShowBill(b)) return false; // ✅ Apply KOT filter
          final billType = (b.orderTypeId ?? '')
              .toLowerCase()
              .replaceAll('-', ' ')
              .trim();
          return billType.contains(normalizedType);
        })
        .map(_mapBillToReceipt)
        .toList();

    filteredReceipts.assignAll(filtered);
    totalCount.value = filtered.length;
    update();
  }

  void filterByStatusType(String status) {
    selectedStatusFilter.value = status;
    if (status == 'All Bills') {
      fetchFromBills(page: 1);
      return;
    }

    final allBills = _billsBox
        .query(
          EntityOrder_.status
              .equals('booked', caseSensitive: false)
              .or(EntityOrder_.status.equals('settled', caseSensitive: false))
              .or(EntityOrder_.status.equals('due', caseSensitive: false))
              .or(
                EntityOrder_.status.equals('cancelled', caseSensitive: false),
              ),
        )
        .order(EntityOrder_.orderNumber, flags: Order.descending)
        .build()
        .find();

    final filtered = allBills
        .where(
          (b) => (b.status ?? '').toLowerCase().contains(status.toLowerCase()),
        )
        .where(_shouldShowBill) // ✅ Apply KOT filter
        .map(_mapBillToReceipt)
        .toList();

    filteredReceipts.assignAll(filtered);
    totalCount.value = filtered.length;
    update();
  }

  // --- Date Filtering ---
  final Rxn<DateTimeRange> selectedDateRange = Rxn<DateTimeRange>();

  void setDateRange(DateTimeRange? range) {
    selectedDateRange.value = range;
    _applyCombinedFilters();
  }

  void presetToday() {
    final now = DateTime.now();
    final s = DateTime(now.year, now.month, now.day);
    final e = s
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1));
    setDateRange(DateTimeRange(start: s, end: e));
  }

  void presetYesterday() {
    final now = DateTime.now().subtract(const Duration(days: 1));
    final s = DateTime(now.year, now.month, now.day);
    final e = s
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1));
    setDateRange(DateTimeRange(start: s, end: e));
  }

  void presetLast7Days() {
    final now = DateTime.now();
    final s = now.subtract(const Duration(days: 6));
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
    final firstThis = DateTime(now.year, now.month, 1);
    final lastMonthEnd = firstThis.subtract(const Duration(days: 1));
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

  void clearDateFilter() {
    setDateRange(null);
  }

  /// 🔹 Apply filters (only one active at a time)
  void _applyCombinedFilters() {
    // fetch all receipts
    final allBills = _billsBox
        .query(
          EntityOrder_.status
              .equals('booked', caseSensitive: false)
              .or(EntityOrder_.status.equals('settled', caseSensitive: false))
              .or(EntityOrder_.status.equals('due', caseSensitive: false))
              .or(
                EntityOrder_.status.equals('cancelled', caseSensitive: false),
              ),
        )
        .order(EntityOrder_.orderNumber, flags: Order.descending)
        .build()
        .find();

    final dr = selectedDateRange.value;
    final orderType = selectedOrderFilter.value;
    final billStatus = selectedStatusFilter.value;
    final waiter = selectedWaiterFilter.value;
    final query = searchText.value.trim().toLowerCase();

    // ✅ Apply KOT filter first
    Iterable<EntityOrder> filtered = allBills.where(_shouldShowBill);

    // 🧩 PRIORITY: Search → Waiter → Date → Order Type → Status
    if (query.isNotEmpty) {
      filtered = filtered.where((b) {
        final combined =
            '${b.orderNumber} ${b.tableName} ${b.orderTypeId} ${b.status} ${b.customerName} ${b.customerMobile} ${b.waiterName}'
                .toLowerCase();
        return combined.contains(query);
      });
    } else if (waiter != 'All Waiters') {
      filtered = filtered.where((b) {
        final w = (b.waiterName ?? '').trim().toLowerCase();
        return w.isNotEmpty && w == waiter.toLowerCase();
      });
    } else if (dr != null) {
      filtered = filtered.where((b) {
        final date = DateTime.tryParse(b.createdOn ?? '') ?? DateTime.now();
        return !(date.isBefore(dr.start) || date.isAfter(dr.end));
      });
    } else if (orderType != 'All Orders') {
      filtered = filtered.where(
        (b) => (b.orderTypeId ?? '').toLowerCase().contains(
          orderType.toLowerCase(),
        ),
      );
    } else if (billStatus != 'All Bills') {
      filtered = filtered.where(
        (b) =>
            (b.status ?? '').toLowerCase().contains(billStatus.toLowerCase()),
      );
    }

    final list = filtered.map(_mapBillToReceipt).toList();

    filteredReceipts.assignAll(list);
    totalCount.value = list.length;
    grossTotal.value = filtered.fold(0.0, (sum, b) {
      final amt = b.totalAmount ?? 0.0;
      final status = (b.status ?? '').toLowerCase();
      if (status.contains('cancel')) {
        // Subtract cancelled bills
        return sum - amt;
      } else {
        return sum + amt;
      }
    });
    update();
  }

  // ✅ Helper to filter out KOT-only bills
  bool _shouldShowBill(EntityOrder b) {
    final status = (b.status ?? '').toLowerCase();

    // 1. If NOT booked, always show (settled, due, cancelled)
    if (status != 'booked') return true;

    // 2. If BOOKED, only show if it has 'draft: true' in meta
    try {
      final j = b.itemsJson;
      if (j == null || j.trim().isEmpty) return false;
      final d = jsonDecode(j);
      if (d is Map && d['meta'] is Map) {
        final meta = d['meta'] as Map;
        return meta['draft'] == true;
      }
    } catch (_) {}

    return false; // Booked but no draft flag = KOT only -> Hide
  }

  void filterByStatus(String status) {
    if (status.toLowerCase() == 'all') {
      fetchFromBills(page: 1);
      return;
    }

    filteredReceipts.assignAll(
      pageBills
          .where(
            (b) =>
                (b.status ?? '').toLowerCase().contains(status.toLowerCase()),
          )
          .map(_mapBillToReceipt)
          .toList(),
    );

    update();
  }

  // 🔸 Mapping
  Receipt _mapBillToReceipt(EntityOrder bill) {
    DateTime? dateTime;

    try {
      if (bill.createdOn != null && bill.createdOn!.isNotEmpty) {
        dateTime = DateTime.tryParse(bill.createdOn!);
      }
    } catch (e) {
      debugPrint("⚠️ Error parsing date for bill ${bill.orderNumber}: $e");
    }

    final formattedDate = dateTime != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(dateTime)
        : '-';
    final controllerOT = Get.find<ControllerOrderType>();
    final orderTypeLabel = controllerOT.getLabelById(bill.orderTypeId);

    // ✅ Calculate due amount
    double paidAmount = 0.0;
    if (bill.payments.isNotEmpty) {
      paidAmount = bill.payments.fold(0.0, (sum, p) => sum + p.price);
    }
    final totalAmount = bill.totalAmount ?? 0.0;
    final dueAmount = totalAmount - paidAmount;

    // ✅ Check if bill has history (multiple payments or paid later)
    bool hasHistory = false;
    if (bill.payments.length > 1) {
      hasHistory = true;
    } else if (bill.payments.length == 1) {
      final pDate = bill.payments.first.date;
      final bDate = DateTime.tryParse(bill.createdOn ?? '');
      if (pDate != null && bDate != null) {
        // If payment was made more than 5 minutes after bill creation, consider it history
        if (pDate.difference(bDate).inMinutes.abs() > 5) {
          hasHistory = true;
        }
      }
    }

    return Receipt(
      billNo: bill.orderNumber ?? 0,
      tableName: bill.tableName ?? bill.orderTypeId ?? 'N/A',
      type: orderTypeLabel,
      status: bill.status ?? 'N/A',
      customer: bill.customerName ?? '',
      waiter: bill.waiterName ?? '',
      phone: bill.customerMobile ?? '',
      deliveryBoy: '',
      payment: _composePaymentLabel(bill),
      amount: bill.totalAmount ?? 0.0,
      billUuid: bill.uuid ?? bill.orderId.toString(),
      dateFormatted: formattedDate,
      dueAmount: dueAmount > 0 ? dueAmount : 0.0, // ✅ Add due amount
      hasHistory: hasHistory, // ✅ Pass history flag
    );
  }

  // 🔸 Payment label
  String _composePaymentLabel(EntityOrder bill) {
    try {
      if (bill.payments.isNotEmpty) {
        final modes = bill.payments.map((p) => p.mode).toSet();
        return modes.isEmpty ? 'Unknown' : modes.join(' + ');
      }
    } catch (_) {}

    try {
      if (bill.itemsJson != null && bill.itemsJson!.isNotEmpty) {
        final decoded = jsonDecode(bill.itemsJson!);
        if (decoded is Map && decoded['meta'] is Map) {
          final meta = decoded['meta'] as Map;
          if (meta.containsKey('paymentMode')) {
            return meta['paymentMode'] as String;
          }
          if (meta['payments'] is List) {
            final paymentList = meta['payments'] as List;
            final modes = paymentList
                .map((p) => (p['mop'] ?? 'Unknown') as String)
                .toSet();
            return modes.isNotEmpty ? modes.join(' + ') : 'Unknown';
          }
        }
      }
    } catch (_) {}

    return 'Unknown';
  }

  // 🔹 Pagination
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

  // 🔹 Search Controls
  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      searchText.value = query;
      fetchFromBills(page: 1);
    });
  }

  void clearSearch() {
    searchText.value = '';
    selectedOrderFilter.value = 'All Orders';
    selectedStatusFilter.value = 'All Bills';
    selectedWaiterFilter.value = 'All Waiters';
    selectedDateRange.value = null;
    fetchFromBills(page: 1);
  }

  // 🔹 Update bill status (don’t remove cancelled)
  Future<void> updateBillStatus(EntityOrder updatedBill) async {
    try {
      _billsBox.put(updatedBill);

      final existingIndex = pageBills.indexWhere(
        (b) => b.orderId == updatedBill.orderId,
      );
      if (existingIndex != -1) {
        pageBills[existingIndex] = updatedBill;
      }

      final receiptIndex = filteredReceipts.indexWhere(
        (r) =>
            r.billUuid ==
                (updatedBill.uuid ?? updatedBill.orderId.toString()) ||
            r.billNo == (updatedBill.orderNumber ?? 0),
      );

      if (receiptIndex != -1) {
        filteredReceipts[receiptIndex] = _mapBillToReceipt(updatedBill);
      }

      update();
      Get.snackbar(
        'Updated',
        'Bill status updated to ${updatedBill.status}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.3),
        colorText: Colors.white,
      );
    } catch (e, st) {
      debugPrint('❌ Error updating bill status: $e\n$st');
      Get.snackbar(
        'Error',
        'Failed to update bill status: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    }
  }

  // 🔹 Export
  Future<void> exportReceipts() async {
    Get.snackbar(
      'Export',
      'Exporting receipts...',
      snackPosition: SnackPosition.BOTTOM,
    );
    await Future.delayed(const Duration(seconds: 1));
    Get.snackbar(
      'Done',
      'Receipts exported successfully!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  // 🔹 Delete Bill (true delete, not cancel)
  Future<bool> deleteBill(int billId) async {
    try {
      final success = _billsBox.remove(billId);
      if (success) {
        Get.snackbar(
          'Deleted',
          'Bill deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await fetchFromBills(page: currentPage.value);
        return true;
      } else {
        Get.snackbar(
          'Error',
          'Bill not found',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e, st) {
      Get.snackbar(
        'Error',
        'Failed to delete bill: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      debugPrint('❌ Failed to delete bill: $e\n$st');
      return false;
    }
  }
}
