import 'dart:ui';
import 'package:splash_screen_03/utils/sanbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:objectbox/objectbox.dart';
import 'package:splash_screen_03/model/entity_bill.dart';
import 'package:splash_screen_03/model/entity_payment.dart';
import 'package:splash_screen_03/model/payment_method.dart';
import 'package:splash_screen_03/objectbox.g.dart';
import 'package:splash_screen_03/screens/home/fragments/order/controller_order.dart';
import 'package:splash_screen_03/constant/api_constant.dart';
import 'package:splash_screen_03/services/api_client.dart';
import 'package:splash_screen_03/repository/Base64.dart';
import 'controller_due.dart';

class FragmentDue extends GetView<ControllerDue> {
  const FragmentDue({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ControllerDue());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              _buildSearchHeader(context),
              const SizedBox(height: 10),
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TabBar(
                  onTap: (index) {
                    controller.currentTab.value = index;
                    controller.currentPage.value = 1;
                  },
                  indicatorSize: TabBarIndicatorSize
                      .label, // ✅ Makes indicator width bigger
                  indicator: BoxDecoration(
                    color: const Color(0xFF005D6A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark
                      ? Colors.white54
                      : Colors.black54,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                        ), // ⬅️ increase width
                        child: Text("Due"),
                      ),
                    ),
                    Tab(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text("History"),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Check if current list is empty
                  final isEmpty = controller.currentTab.value == 0
                      ? controller.filteredDueOrders.isEmpty
                      : controller.filteredHistoryOrders.isEmpty;

                  if (isEmpty) {
                    return Center(
                      child: Text(
                        controller.searchText.value.isEmpty
                            ? 'No orders found.'
                            : 'No orders match your search.',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                    );
                  }
                  return _buildGlassTable(context);
                }),
              ),
              const SizedBox(height: 10),
              _buildFooterBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark
        ? const Color(0xFF1C1F25)
        : const Color(0xFFF6F8FA);
    final Color textColor = isDark ? Colors.white70 : Colors.black87;
    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: controller.onSearchChanged,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search Name, Phone, Order ID...',
                hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
                prefixIcon: Icon(
                  Icons.search,
                  color: textColor.withOpacity(0.6),
                  size: 20,
                ),
                filled: true,
                fillColor: bgColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: controller.clearSearch,
            icon: Icon(
              Icons.close,
              color: textColor.withOpacity(0.8),
              size: 18,
            ),
            label: Text(
              'Clear',
              style: TextStyle(color: textColor.withOpacity(0.8)),
            ),
            style: TextButton.styleFrom(
              backgroundColor: bgColor,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: controller.exportToExcel,
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Export', style: TextStyle(fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTable(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color headerBg = isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.grey.withOpacity(0.15);
    final Color rowAltBg = isDark
        ? Colors.white.withOpacity(0.03)
        : Colors.grey.withOpacity(0.06);
    final Color rowBg = isDark
        ? Colors.transparent
        : Colors.white.withOpacity(0.9);
    final Color headerText = isDark ? Colors.white70 : Colors.black87;
    final Color cellText = isDark ? Colors.white70 : Colors.black87;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.shade100.withOpacity(0.85),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width,
              ),
              child: Obx(
                () => DataTable(
                  headingRowColor: WidgetStateProperty.all(headerBg),
                  headingTextStyle: TextStyle(
                    color: headerText,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  dataTextStyle: TextStyle(color: cellText, fontSize: 13),
                  columnSpacing: 24,
                  dividerThickness: 0.2,
                  headingRowHeight: 52,
                  dataRowHeight: 58,
                  columns: const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('NAME')),
                    DataColumn(label: Text('PHONE')),
                    DataColumn(label: Text('ORDER ID')),
                    DataColumn(label: Text('DUE AMOUNT')),
                    DataColumn(label: Text('STATUS')),
                    DataColumn(label: Text('PAY INFO')),
                  ],
                  rows: List.generate(controller.paginatedOrders.length, (
                    index,
                  ) {
                    final order = controller.paginatedOrders[index];
                    final bgColor = index.isEven ? rowAltBg : rowBg;

                    return DataRow(
                      color: WidgetStateProperty.all(bgColor),
                      cells: [
                        DataCell(Text('${index + 1}')),
                        DataCell(Text(order.name)),
                        DataCell(Text(order.phone)),
                        DataCell(Text(order.orderId)),
                        DataCell(
                          Text(
                            '${controller.currencyLabel} ${order.dueAmount.toStringAsFixed(2)}',
                          ),
                        ),
                        DataCell(_statusChip(order.status)),
                        DataCell(
                          controller.currentTab.value == 0
                              ? Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.15),
                                        border: Border.all(
                                          color: Colors.orange.withOpacity(0.6),
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        order.paymentInfo,
                                        style: const TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _showPayDueDialog(context, order),
                                      icon: const Icon(Icons.payment, size: 16),
                                      label: const Text(
                                        'Pay Due',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.15),
                                    border: Border.all(
                                      color: Colors.blue.withOpacity(0.6),
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    order.paymentInfo,
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    if (status.toLowerCase().contains('fulfilled') ||
        status.toLowerCase().contains('booked')) {
      color = Colors.orangeAccent;
    } else if (status.toLowerCase().contains('pending')) {
      color = Colors.yellowAccent;
    } else if (status.toLowerCase().contains('due')) {
      color = Colors.redAccent;
    } else {
      color = Colors.blueGrey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildFooterBar() {
    return Obx(() {
      final pageTotal = controller.paginatedOrders.fold<double>(
        0.0,
        (sum, order) => sum + order.dueAmount,
      );
      final grossTotal =
          (controller.currentTab.value == 0
                  ? controller.filteredDueOrders
                  : controller.filteredHistoryOrders)
              .fold<double>(0.0, (sum, order) => sum + order.dueAmount);

      return Container(
        margin: const EdgeInsets.fromLTRB(10, 4, 10, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Page Total: ${controller.currencyLabel} ${pageTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Gross Total: ${controller.currencyLabel} ${grossTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.lightGreenAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left,
                    color: Colors.white70,
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: controller.prevPage,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'Page ${controller.currentPage.value} of ${controller.totalPages}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.chevron_right,
                    color: Colors.white70,
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: controller.nextPage,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  void _showPayDueDialog(BuildContext context, DueOrder order) async {
    // Get the bill from ObjectBox
    try {
      final Box<EntityOrder> billsBox = Get.find<Box<EntityOrder>>();
      EntityOrder? bill;

      if (order.billUuid.isNotEmpty) {
        bill = billsBox
            .query(EntityOrder_.uuid.equals(order.billUuid))
            .build()
            .findFirst();
      } else {
        bill = billsBox
            .query(EntityOrder_.orderId.equals(order.billId))
            .build()
            .findFirst();
      }

      if (bill == null) {
        showMiniSnackGlobal(
          'Error',
          'Bill not found',
          type: MiniSnackType.error,
        );
        return;
      }

      // Check if customer is added
      final customerName = bill.customerName ?? '';
      final customerPhone = bill.customerMobile ?? '';

      if (customerName.trim().isEmpty || customerPhone.trim().isEmpty) {
        showMiniSnackGlobal(
          'Customer Required',
          'Please add customer details before marking as due payment',
          type: MiniSnackType.warning,
        );
        return;
      }

      // Show Pay Due Dialog
      await showDialog(
        context: context,
        builder: (ctx) => PayDueDialog(bill: bill!, dueOrder: order),
      );

      // Refresh after dialog closes
      controller.refresh();
    } catch (e) {
      debugPrint('❌ Error loading bill: $e');
      showMiniSnackGlobal(
        'Error',
        'Failed to load bill details',
        type: MiniSnackType.error,
      );
    }
  }
}

// Pay Due Dialog
class PayDueDialog extends StatefulWidget {
  final EntityOrder bill;
  final DueOrder dueOrder;

  const PayDueDialog({super.key, required this.bill, required this.dueOrder});

  @override
  State<PayDueDialog> createState() => _PayDueDialogState();
}

class _PayDueDialogState extends State<PayDueDialog> {
  final TextEditingController _amountCtrl = TextEditingController();
  final RxString _selectedPaymentMode = 'Cash'.obs;
  bool _saving = false;

  List<String> get paymentModes =>
      PaymentMethod.values.map((e) => e.label).toList();

  @override
  void initState() {
    super.initState();
    _amountCtrl.text = widget.dueOrder.dueAmount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _onConfirmPayment() async {
    if (_saving) return;

    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      showMiniSnackGlobal(
        'Error',
        'Please enter a valid amount',
        type: MiniSnackType.error,
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final Box<EntityOrder> billsBox = Get.find<Box<EntityOrder>>();

      // Add payment to bill
      widget.bill.payments.add(
        Payment(
          price: amount,
          mode: _selectedPaymentMode.value,
          date: DateTime.now(),
        ),
      );

      // Calculate total paid amount
      final totalPaid = widget.bill.payments.fold<double>(
        0.0,
        (sum, payment) => sum + payment.price,
      );

      // Update bill status if fully paid
      if (totalPaid >= (widget.bill.totalAmount ?? 0)) {
        widget.bill.status = 'settled';
      }

      // Save bill locally
      billsBox.put(widget.bill);

      // ✅ Sync with server
      try {
        final ApiClient apiClient = ApiClient();

        // 1. Check/Recover mongoId
        if (widget.bill.mongoId == null || widget.bill.mongoId!.isEmpty) {
          debugPrint("⚠️ mongoId missing. Attempting to fetch from server...");
          try {
            final storage = StorageRepository();
            final searchUrl =
                "${ApiConstant.apiBase}/bills?billNumber=Bill-${widget.bill.orderNumber}&restaurantId=${storage.restaurantId}";
            debugPrint("🔍 Search Request URL: $searchUrl");
            final searchResp = await apiClient.getRequestWithToken(searchUrl);

            debugPrint(
              "📥 Search Response Status Code: ${searchResp.statusCode}",
            );
            debugPrint("📥 Search Response Body: ${searchResp.body}");

            if (searchResp.statusCode == 200 &&
                searchResp.body?["success"] == true) {
              final List docs = searchResp.body?["data"] ?? [];
              if (docs.isNotEmpty) {
                final serverBill = docs.first;
                final serverId =
                    serverBill["_id"]?.toString() ??
                    serverBill["id"]?.toString();
                if (serverId != null && serverId.isNotEmpty) {
                  widget.bill.mongoId = serverId;
                  widget.bill.isSync = true;
                  billsBox.put(widget.bill);
                  debugPrint("✅ Recovered mongoId: $serverId");
                }
              }
            }
          } catch (e) {
            debugPrint("❌ Failed to recover bill ID: $e");
          }
        }

        // 2. Use PATCH if we have an ID (existing or recovered)
        if (widget.bill.mongoId != null && widget.bill.mongoId!.isNotEmpty) {
          debugPrint("🔄 Patching Bill: ${widget.bill.mongoId}");

          // Map local status to server status (Active, Completed, Cancelled)
          String serverStatus = 'Active'; // Default to Active (Pending)
          String paymentStatus = 'Pending';

          if (totalPaid >= (widget.bill.totalAmount ?? 0)) {
            serverStatus = 'Completed'; // settled -> Completed
            paymentStatus = 'Paid';
          } else if (totalPaid > 0) {
            paymentStatus = 'PartiallyPaid';
          }

          final payload = {
            "status": serverStatus,
            "paymentStatus": paymentStatus,
            "amountPaid": totalPaid,
            "payments": widget.bill.payments
                .map(
                  (p) => {
                    "method": p.mode,
                    "amount": p.price,
                    "transactionId": "",
                  },
                )
                .toList(),
          };

          final patchUrl =
              "${ApiConstant.apiBase}/bills/${widget.bill.mongoId}";
          debugPrint("🔄 PATCH Request URL: $patchUrl");
          debugPrint("🔄 PATCH Request Payload: $payload");

          final response = await apiClient.patchRequestWithToken(
            patchUrl,
            payload,
          );

          debugPrint("📥 PATCH Response Status Code: ${response.statusCode}");
          debugPrint("📥 PATCH Response Body: ${response.body}");

          if (response.statusCode == 200 && response.body?['success'] == true) {
            debugPrint("✅ Bill patched successfully");
            showMiniSnackGlobal(
              'Success',
              'Payment synced successfully',
              type: MiniSnackType.success,
            );
          } else {
            debugPrint("⚠️ Bill patch failed: ${response.body}");
          }
        } else {
          // 3. Fallback to POST if ID still missing (New Bill)
          debugPrint("⚠️ No ID found. Falling back to POST (pushOrder)...");
          if (Get.isRegistered<ControllerOrder>()) {
            final orderCtrl = Get.find<ControllerOrder>();
            await orderCtrl.pushOrder(widget.bill);
          }
        }
      } catch (e) {
        debugPrint('⚠️ Failed to sync payment: $e');
      }

      showMiniSnackGlobal(
        'Success',
        'Payment recorded successfully',
        type: MiniSnackType.success,
      );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('❌ Payment error: $e');
      showMiniSnackGlobal(
        'Error',
        'Failed to process payment: $e',
        type: MiniSnackType.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pay due',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildReadOnlyField(
                'Order Amount:',
                widget.bill.totalAmount?.toStringAsFixed(2) ?? '0.00',
              ),
              const SizedBox(height: 12),
              _buildReadOnlyField(
                'Received Amount:',
                widget.dueOrder.receivedAmount.toStringAsFixed(2),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountCtrl,
                readOnly: _saving,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
                ],
                decoration: InputDecoration(
                  labelText: 'Amount to pay:',
                  labelStyle: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 12),
              Obx(
                () => DropdownButtonFormField<String>(
                  value: _selectedPaymentMode.value,
                  items: paymentModes
                      .map(
                        (mode) =>
                            DropdownMenuItem(value: mode, child: Text(mode)),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (v) => _selectedPaymentMode.value = v ?? 'Cash',
                  decoration: InputDecoration(
                    labelText: 'Pay mode:',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.shade50,
                  ),
                  dropdownColor: isDark
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saving ? null : _onConfirmPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Pay',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.grey.shade200;
    final textColor = isDark ? Colors.white70 : Colors.black87;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(8),
              border: isDark ? Border.all(color: Colors.white12) : null,
            ),
            child: Text(value, style: TextStyle(color: textColor)),
          ),
        ),
      ],
    );
  }
}
