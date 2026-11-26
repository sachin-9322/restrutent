import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:objectbox/objectbox.dart';
import 'package:splash_screen_03/model/entity_bill.dart';
import 'package:splash_screen_03/objectbox.g.dart';

class DueOrder {
  final String name;
  final String phone;
  final String orderId;
  final double dueAmount;
  final double receivedAmount;
  final String status;
  final int billId;
  final String billUuid;
  final String paymentInfo; // Payment method info: "Due" or actual methods

  DueOrder({
    required this.name,
    required this.phone,
    required this.orderId,
    required this.dueAmount,
    required this.receivedAmount,
    required this.status,
    required this.billId,
    required this.billUuid,
    required this.paymentInfo,
  });
}

class ControllerDue extends GetxController {
  final RxList<DueOrder> allDueOrders = <DueOrder>[].obs;
  final RxList<DueOrder> filteredDueOrders = <DueOrder>[].obs;

  final RxList<DueOrder> allHistoryOrders = <DueOrder>[].obs;
  final RxList<DueOrder> filteredHistoryOrders = <DueOrder>[].obs;

  final RxInt currentTab = 0.obs;

  final RxString searchText = ''.obs;
  final RxBool isLoading = false.obs;

  final RxInt currentPage = 1.obs;
  final int itemsPerPage = 20;

  final String currencyLabel = '₹';

  @override
  void onInit() {
    super.onInit();
    fetchDueOrders();
  }

  // Fetch bills with pending/due payments
  Future<void> fetchDueOrders() async {
    try {
      isLoading.value = true;
      final Box<EntityOrder> billsBox = Get.find<Box<EntityOrder>>();
      final allBills = billsBox.getAll();

      final List<DueOrder> dueList = [];
      final List<DueOrder> historyList = [];

      for (final bill in allBills) {
        final status = (bill.status ?? '').toLowerCase();

        // Skip cancelled bills
        if (status == 'cancelled') continue;

        final totalAmount = bill.totalAmount ?? 0.0;
        final paidAmount = bill.payments.fold<double>(
          0.0,
          (sum, p) => sum + p.price,
        );
        final dueAmount = totalAmount - paidAmount;

        // Extract customer info
        String customerName = bill.customerName ?? '';
        String customerPhone = bill.customerMobile ?? '';

        if (customerName.trim().isEmpty) {
          try {
            final itemsJson = bill.itemsJson;
            if (itemsJson != null && itemsJson.trim().isNotEmpty) {
              final parsed = jsonDecode(itemsJson);
              if (parsed is Map && parsed['meta'] is Map) {
                final meta = parsed['meta'] as Map;
                customerName = meta['customerName']?.toString() ?? '';
                customerPhone = meta['customerPhone']?.toString() ?? '';
              }
            }
          } catch (_) {}
        }

        // ✅ Determine payment info to display
        String paymentInfo;
        if (dueAmount > 0 &&
            (status == 'due' || status == 'booked' || status == 'pending')) {
          // Bill has outstanding due amount
          paymentInfo = 'Due';
        } else if (bill.payments.isNotEmpty) {
          // Bill is settled, show payment methods used
          final methods = bill.payments.map((p) => p.mode).toSet().toList();
          paymentInfo = methods.join(', ');
        } else {
          paymentInfo = '-';
        }

        final orderObj = DueOrder(
          name: customerName.isEmpty ? 'Guest' : customerName,
          phone: customerPhone.isEmpty ? '-' : customerPhone,
          orderId: bill.orderId.toString(),
          dueAmount: dueAmount > 0 ? dueAmount : 0,
          receivedAmount: paidAmount,
          status: bill.status ?? 'pending',
          billId: bill.orderId,
          billUuid: bill.uuid,
          paymentInfo: paymentInfo,
        );

        // ✅ Better logic: Check for due status explicitly
        final bool isDue =
            (status == 'due' || status == 'booked' || status == 'pending') &&
            dueAmount > 0;
        final bool isSettled = status == 'settled';

        if (isDue) {
          dueList.add(orderObj);
        } else if (isSettled) {
          // ✅ Only show settled orders in History tab
          historyList.add(orderObj);
        }
      }

      // Sort history by orderId descending (newest first)
      historyList.sort(
        (a, b) => int.parse(b.orderId).compareTo(int.parse(a.orderId)),
      );

      allDueOrders.assignAll(dueList);
      allHistoryOrders.assignAll(historyList);

      _applySearch();
    } catch (e) {
      debugPrint("❌ Error fetching due orders: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Search functionality
  void onSearchChanged(String value) {
    searchText.value = value;
    _applySearch();
  }

  void _applySearch() {
    final query = searchText.value.toLowerCase().trim();

    // Filter Due Orders
    if (query.isEmpty) {
      filteredDueOrders.assignAll(allDueOrders);
    } else {
      filteredDueOrders.assignAll(
        allDueOrders.where((order) {
          return order.name.toLowerCase().contains(query) ||
              order.phone.contains(query) ||
              order.orderId.toLowerCase().contains(query);
        }).toList(),
      );
    }

    // Filter History Orders
    if (query.isEmpty) {
      filteredHistoryOrders.assignAll(allHistoryOrders);
    } else {
      filteredHistoryOrders.assignAll(
        allHistoryOrders.where((order) {
          return order.name.toLowerCase().contains(query) ||
              order.phone.contains(query) ||
              order.orderId.toLowerCase().contains(query);
        }).toList(),
      );
    }
  }

  void clearSearch() {
    searchText.value = '';
    _applySearch();
  }

  // Pagination
  int get totalPages {
    final len = currentTab.value == 0
        ? filteredDueOrders.length
        : filteredHistoryOrders.length;
    return (len / itemsPerPage).ceil();
  }

  List<DueOrder> get paginatedOrders {
    final list = currentTab.value == 0
        ? filteredDueOrders
        : filteredHistoryOrders;
    final start = (currentPage.value - 1) * itemsPerPage;
    final end = start + itemsPerPage;
    if (start >= list.length) return [];
    return list.sublist(start, end > list.length ? list.length : end);
  }

  void nextPage() {
    if (currentPage.value < totalPages) {
      currentPage.value++;
    }
  }

  void prevPage() {
    if (currentPage.value > 1) {
      currentPage.value--;
    }
  }

  // Export to Excel
  Future<void> exportToExcel() async {
    try {
      final excel = Excel.createExcel();
      final Sheet sheet = excel['Due Orders'];

      // Header row
      sheet.appendRow([
        TextCellValue('Name'),
        TextCellValue('Phone'),
        TextCellValue('Order ID'),
        TextCellValue('Due Amount'),
        TextCellValue('Received Amount'),
        TextCellValue('Status'),
        TextCellValue('Payment Info'),
      ]);

      // Data rows
      for (final order in filteredDueOrders) {
        sheet.appendRow([
          TextCellValue(order.name),
          TextCellValue(order.phone),
          TextCellValue(order.orderId),
          TextCellValue(order.dueAmount.toStringAsFixed(2)),
          TextCellValue(order.receivedAmount.toStringAsFixed(2)),
          TextCellValue(order.status),
          TextCellValue(order.paymentInfo),
        ]);
      }

      // Save file
      final Directory? dir = await getDownloadsDirectory();
      if (dir == null) {
        Get.snackbar('Error', 'Could not access downloads directory');
        return;
      }

      final String timestamp = DateFormat(
        'yyyyMMdd_HHmmss',
      ).format(DateTime.now());
      final String filePath = '${dir.path}/due_orders_$timestamp.xlsx';
      final File file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      Get.snackbar(
        'Success',
        'Export saved to: $filePath',
        backgroundColor: Colors.green.withOpacity(0.2),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint('❌ Export error: $e');
      Get.snackbar('Error', 'Failed to export: $e');
    }
  }

  @override
  Future<void> refresh() async {
    await fetchDueOrders();
  }
}
