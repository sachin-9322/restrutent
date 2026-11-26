// lib/screens/home/fragments/receipt/receipt_screen.dart
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:objectbox/objectbox.dart';
import 'package:splash_screen_03/model/entity_bill.dart';
import 'package:splash_screen_03/model/entity_receipt.dart';
import 'package:splash_screen_03/objectbox.g.dart';
import 'package:splash_screen_03/screens/home/fragments/receipt/controller_receipt.dart';

class ReceiptScreen extends GetView<ReceiptController> {
  const ReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ReceiptController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final bool isMobile = width < 700;
        final bool isTablet = width >= 700 && width < 1100;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.white,
          body: Padding(
            padding: EdgeInsets.all(isMobile ? 6 : 10),
            child: Column(
              children: [
                _buildFilterHeader(context, isMobile),
                const SizedBox(height: 10),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (controller.filteredReceipts.isEmpty) {
                      return Center(
                        child: Text(
                          controller.searchText.value.isEmpty
                              ? 'No receipts found.'
                              : 'No receipts match your search.',
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
                SizedBox(height: 10),
                _buildFooterBar(isMobile),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🔹 Filter Header
  Widget _buildFilterHeader(BuildContext context, bool isMobile) {
    final cs = Theme.of(context).colorScheme;
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
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 12,
        vertical: isMobile ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // 🔍 Search
          SizedBox(
            width: isMobile ? double.infinity : 250,
            child: TextField(
              onChanged: controller.onSearchChanged,
              style: TextStyle(color: textColor, fontSize: isMobile ? 13 : 14),
              decoration: InputDecoration(
                hintText: 'Search Bill, Table, Customer...',
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

          // 🔽 Order Type
          SizedBox(
            width: isMobile ? 160 : 180,
            child: Obx(
              () => _glassDropdown(
                context,
                hint: 'All Orders',
                value: controller.selectedOrderFilter.value,
                items: const [
                  'All Orders',
                  'Delivery',
                  'Dine In',
                  'Pickup',
                  'Take',
                ],
                onChanged: (v) =>
                    controller.filterByOrderType(v ?? 'All Orders'),
              ),
            ),
          ),

          // 🔽 Status
          SizedBox(
            width: isMobile ? 150 : 170,
            child: Obx(
              () => _glassDropdown(
                context,
                hint: 'All Bills',
                value: controller.selectedStatusFilter.value,
                items: const ['All Bills', 'Pending', 'Settled', 'Cancelled'],
                onChanged: (v) =>
                    controller.filterByStatusType(v ?? 'All Bills'),
              ),
            ),
          ),

          // 🔽 Waiter
          SizedBox(
            width: isMobile ? 150 : 160,
            child: Obx(() {
              final waiters = controller.allWaiters;
              return _glassDropdown(
                context,
                hint: 'All Waiters',
                value: controller.selectedWaiterFilter.value,
                items: ['All Waiters', ...waiters],
                onChanged: (v) => controller.filterByWaiter(v ?? 'All Waiters'),
              );
            }),
          ),

          // 📅 Date Chip
          _dateChip('All Dates', onTap: () {}),
          if (!isMobile) const SizedBox(width: 6),

          // ❌ Clear
          SizedBox(
            height: 40,
            child: TextButton.icon(
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
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          // ⬇ Export
          SizedBox(
            height: 40,
            child: ElevatedButton.icon(
              onPressed: controller.exportReceipts,
              icon: Icon(Icons.download_rounded, size: isMobile ? 16 : 18),
              label: Text(
                'Export',
                style: TextStyle(fontSize: isMobile ? 13 : 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔸 Glass Dropdown
  Widget _glassDropdown(
    BuildContext context, {
    required String hint,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF1C1F25) : Colors.white;
    final Color textColor = isDark ? Colors.white70 : Colors.black87;
    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.1);

    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : hint,
      onChanged: onChanged,
      icon: Icon(
        Icons.arrow_drop_down,
        color: textColor.withOpacity(0.8),
        size: 20,
      ),
      dropdownColor: bgColor,
      style: TextStyle(color: textColor, fontSize: 13),
      decoration: InputDecoration(
        filled: true,
        fillColor: bgColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
      ),
      items: items
          .map(
            (e) => DropdownMenuItem<String>(
              value: e,
              child: Text(e, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
    );
  }

  // 📅 Date Chip
  Widget _dateChip(String text, {VoidCallback? onTap}) {
    final GlobalKey chipKey = GlobalKey();
    return Obx(() {
      final dr = controller.selectedDateRange.value;
      final label = dr == null
          ? 'All Dates'
          : '${DateFormat('dd MMM').format(dr.start)} - ${DateFormat('dd MMM').format(dr.end)}';
      return InkWell(
        key: chipKey,
        onTap: () => _showDateFilterDropdown(chipKey),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: Colors.white60,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showDateFilterDropdown(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    final overlay = Overlay.of(ctx, rootOverlay: true);
    final RenderBox box = ctx.findRenderObject() as RenderBox;
    final Offset position = box.localToGlobal(Offset.zero);
    final Size size = box.size;

    late OverlayEntry dropdown;
    dropdown = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => dropdown.remove(),
                behavior: HitTestBehavior.translucent,
              ),
            ),
            Positioned(
              left: position.dx,
              top: position.dy + size.height + 4,
              width: size.width * 1.4,
              child: Material(
                color: const Color(0xFF1C1F25),
                elevation: 6,
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dateOption('Today', () {
                      controller.presetToday();
                      dropdown.remove();
                    }),
                    _dateOption('Yesterday', () {
                      controller.presetYesterday();
                      dropdown.remove();
                    }),
                    _dateOption('Last 7 Days', () {
                      controller.presetLast7Days();
                      dropdown.remove();
                    }),
                    _dateOption('This Month', () {
                      controller.presetThisMonth();
                      dropdown.remove();
                    }),
                    _dateOption('Last Month', () {
                      controller.presetLastMonth();
                      dropdown.remove();
                    }),
                    const Divider(height: 1, color: Colors.white10),
                    _dateOption('Custom Range', () async {
                      dropdown.remove();
                      final picked = await showDateRangePicker(
                        context: ctx,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: controller.selectedDateRange.value,
                        builder: (context, child) =>
                            Theme(data: ThemeData.dark(), child: child!),
                      );
                      if (picked != null) controller.setDateRange(picked);
                    }),
                    _dateOption('All Time', () {
                      controller.clearDateFilter();
                      dropdown.remove();
                    }),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(dropdown);
  }

  Widget _dateOption(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ),
    );
  }

  // 🧾 DataTable (theme adaptive)
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
                    DataColumn(label: Text('BILL NO')),
                    DataColumn(label: Text('TABLE')),
                    DataColumn(label: Text('TYPE')),
                    DataColumn(label: Text('STATUS')),
                    DataColumn(label: Text('DATE')),
                    DataColumn(label: Text('CUSTOMER')),
                    DataColumn(label: Text('WAITER')),
                    DataColumn(label: Text('PAYMENT')),
                    DataColumn(label: Text('AMOUNT')),
                    DataColumn(label: Text('DUE AMOUNT')),
                    DataColumn(label: Text('')),
                  ],
                  rows: List.generate(controller.filteredReceipts.length, (
                    index,
                  ) {
                    final r = controller.filteredReceipts[index];
                    final bgColor = index.isEven ? rowAltBg : rowBg;

                    return DataRow(
                      color: WidgetStateProperty.all(bgColor),
                      cells: [
                        DataCell(Text('${index + 1}')),
                        DataCell(Text(r.billNo.toString())),
                        DataCell(Text(r.tableName)),
                        DataCell(_typeChip(r.type)),
                        DataCell(_statusChip(r.status)),
                        DataCell(Text(r.dateFormatted ?? '-')),
                        DataCell(Text(r.customer)),
                        DataCell(Text(r.waiter ?? '')),
                        DataCell(Text(r.payment)),
                        DataCell(Text(r.amount.toStringAsFixed(2))),
                        DataCell(_buildDueAmountCell(r, isDark, context)),
                        DataCell(
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: isDark
                                  ? Colors.lightBlueAccent
                                  : Colors.blueAccent,
                              size: 20,
                            ),
                            tooltip: 'Modify Bill',
                            onPressed: () async {
                              try {
                                final Box<EntityOrder> box =
                                    Get.find<Box<EntityOrder>>();
                                EntityOrder? order;
                                if (r.billUuid.isNotEmpty) {
                                  order = box
                                      .query(
                                        EntityOrder_.uuid.equals(r.billUuid),
                                      )
                                      .build()
                                      .findFirst();
                                } else {
                                  order = box
                                      .query(
                                        EntityOrder_.orderId.equals(r.billNo),
                                      )
                                      .build()
                                      .findFirst();
                                }
                                if (order != null) {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => BillModifyDialog(
                                      bill: order!,
                                      ctrl: controller,
                                    ),
                                  );
                                } else {
                                  Get.snackbar(
                                    "Not Found",
                                    "Could not locate bill details for modification.",
                                    backgroundColor: Colors.redAccent
                                        .withOpacity(0.2),
                                    colorText: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  );
                                }
                              } catch (e) {
                                debugPrint("❌ Failed to load EntityOrder: $e");
                              }
                            },
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

  // 🔹 Compact Footer Totals (theme adaptive)
  Widget _buildFooterBar(bool isMobile) {
    final theme = Get.context!.theme;
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      final pageTotal = controller.filteredReceipts.fold<double>(
        0.0,
        (sum, r) => sum + r.amount,
      );
      final grossTotal = controller.grossTotal.value;

      final textSize = isMobile ? 12.5 : 14.5;

      // 🎨 Theme adaptive colors
      final bgColor = isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.grey.shade100.withOpacity(0.9);
      final borderColor = isDark
          ? Colors.white.withOpacity(0.08)
          : Colors.black.withOpacity(0.1);
      final labelColor = isDark ? Colors.white70 : Colors.black87;
      final valueColor = isDark
          ? Colors.lightGreenAccent
          : Colors.green.shade700;
      final iconColor = isDark ? Colors.white70 : Colors.black54;

      final labelStyle = TextStyle(
        color: labelColor,
        fontWeight: FontWeight.bold,
        fontSize: textSize,
      );
      final valueStyle = TextStyle(
        color: valueColor,
        fontWeight: FontWeight.w600,
        fontSize: textSize,
      );

      return Container(
        margin: const EdgeInsets.fromLTRB(10, 4, 10, 8),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 💰 Totals (left side)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Page Total: ${controller.currencyLabel} ${pageTotal.toStringAsFixed(2)}',
                  style: labelStyle,
                ),
                const SizedBox(height: 2),
                Text(
                  'Gross Total: ${controller.currencyLabel} ${grossTotal.toStringAsFixed(2)}',
                  style: valueStyle,
                ),
              ],
            ),

            // 📄 Pagination Controls (right side)
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.chevron_left,
                    color: iconColor,
                    size: isMobile ? 20 : 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: controller.prevPage,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 10),
                  child: Text(
                    'Page ${controller.currentPage.value} of ${controller.totalPages}',
                    style: TextStyle(color: labelColor, fontSize: textSize),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right,
                    color: iconColor,
                    size: isMobile ? 20 : 22,
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

  Widget _typeChip(String type) {
    Color color;
    if (type.toLowerCase().contains('dine')) {
      color = Colors.blueAccent;
    } else if (type.toLowerCase().contains('pickup')) {
      color = Colors.cyanAccent;
    } else if (type.toLowerCase().contains('take')) {
      color = Colors.indigoAccent;
    } else if (type.toLowerCase().contains('delivery')) {
      color = Colors.deepPurpleAccent;
    } else {
      color = Colors.grey;
    }
    return _chip(type, color);
  }

  Widget _statusChip(String status) {
    Color color;
    if (status.toLowerCase().contains('settled')) {
      color = Colors.greenAccent;
    } else if (status.toLowerCase().contains('pending')) {
      color = Colors.orangeAccent;
    } else if (status.toLowerCase().contains('cancel')) {
      color = Colors.redAccent;
    } else {
      color = Colors.blueGrey;
    }
    return _chip(status, color);
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // 🔹 Build Due Amount Cell with View Icon
  Widget _buildDueAmountCell(Receipt r, bool isDark, BuildContext context) {
    // Check if this bill has any payments to show history
    final hasPayments = r.payment != 'Unknown' && r.payment.isNotEmpty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          r.dueAmount > 0
              ? r.dueAmount.toStringAsFixed(2)
              : (hasPayments ? '0.00' : '--'),
          style: TextStyle(
            color: r.dueAmount > 0
                ? (isDark ? Colors.orangeAccent : Colors.orange.shade700)
                : (isDark ? Colors.lightGreenAccent : Colors.green.shade700),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        if (r.dueAmount > 0 || r.hasHistory) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.visibility_outlined,
              color: isDark ? Colors.cyanAccent : Colors.blue.shade700,
              size: 18,
            ),
            tooltip: 'View Transaction History',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _showTransactionHistory(context, r),
          ),
        ],
      ],
    );
  }

  // 🔹 Show Transaction History Dialog
  void _showTransactionHistory(BuildContext context, Receipt receipt) async {
    try {
      final Box<EntityOrder> box = Get.find<Box<EntityOrder>>();
      EntityOrder? order;

      if (receipt.billUuid.isNotEmpty) {
        order = box
            .query(EntityOrder_.uuid.equals(receipt.billUuid))
            .build()
            .findFirst();
      } else {
        order = box
            .query(EntityOrder_.orderId.equals(receipt.billNo))
            .build()
            .findFirst();
      }

      if (order == null) {
        Get.snackbar(
          "Not Found",
          "Could not load transaction details.",
          backgroundColor: Colors.redAccent.withOpacity(0.2),
          colorText: Colors.white,
        );
        return;
      }

      showDialog(
        context: context,
        builder: (ctx) =>
            TransactionHistoryDialog(bill: order!, receipt: receipt),
      );
    } catch (e) {
      debugPrint("❌ Failed to load transaction history: $e");
      Get.snackbar(
        "Error",
        "Failed to load transaction history.",
        backgroundColor: Colors.redAccent.withOpacity(0.2),
        colorText: Colors.white,
      );
    }
  }
}

// ✅ BillModifyDialog remains adaptive
class BillModifyDialog extends StatelessWidget {
  final EntityOrder bill;
  final ReceiptController ctrl;
  final bool isEditable;

  BillModifyDialog({
    super.key,
    required this.bill,
    required this.ctrl,
    this.isEditable = false,
  }) {
    _selectedStatus.value = bill.status ?? '';
  }

  final RxString _selectedStatus = ''.obs;
  final RxString _selectedPayment = ''.obs;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? width * 0.9 : width * 0.45,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '🧾 Modify Bill',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              _sectionHeader('Bill Status'),
              const SizedBox(height: 8),
              Obx(
                () => Row(
                  children: [
                    _statusButton(
                      label: 'Settled',
                      color: Colors.green,
                      selected: _selectedStatus.value == 'Settled',
                      onTap: () => _selectedStatus.value = 'Settled',
                    ),
                    const SizedBox(width: 8),
                    _statusButton(
                      label: 'Cancelled',
                      color: Colors.red,
                      selected: _selectedStatus.value == 'Cancelled',
                      onTap: () => _selectedStatus.value = 'Cancelled',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _sectionHeader('Payment Mode'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _paymentButton('Paytm', Colors.blue),
                  _paymentButton('GooglePay', Colors.green),
                  _paymentButton('Freecharge', Colors.orange),
                  _paymentButton('Card', Colors.indigo),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // ✅ Update bill status
                      bill.status = _selectedStatus.value;

                      // ✅ Update bill payment mode
                      if (_selectedPayment.value.isNotEmpty) {
                        // If you have payments list inside EntityOrder
                        if (bill.payments.isNotEmpty) {
                          for (var p in bill.payments) {
                            p.mode = _selectedPayment.value;
                          }
                        } else {
                          // Or fallback to itemsJson meta if your system stores it there
                          bill.itemsJson = jsonEncode({
                            "meta": {"paymentMode": _selectedPayment.value},
                          });
                        }
                      }

                      // ✅ Refresh and persist
                      ctrl.updateBillStatus(bill);
                      Navigator.of(context).pop();

                      Get.snackbar(
                        "Updated",
                        "Bill updated with ${_selectedStatus.value} & ${_selectedPayment.value}",
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.green.withOpacity(0.3),
                        colorText: Colors.white,
                      );
                    },

                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Apply Changes'),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _statusButton({
    required String label,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? color.withOpacity(0.15) : null,
          side: BorderSide(color: color),
          foregroundColor: color,
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _paymentButton(String label, Color color) {
    return Obx(
      () => OutlinedButton(
        onPressed: () => _selectedPayment.value = label,
        style: OutlinedButton.styleFrom(
          backgroundColor: _selectedPayment.value == label
              ? color.withOpacity(0.15)
              : color.withOpacity(0.05),
          side: BorderSide(color: color.withOpacity(0.6)),
          foregroundColor: color,
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }
}

// 🔹 Transaction History Dialog
class TransactionHistoryDialog extends StatelessWidget {
  final EntityOrder bill;
  final Receipt receipt;

  const TransactionHistoryDialog({
    super.key,
    required this.bill,
    required this.receipt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: isMobile ? width * 0.95 : 500,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1E1E).withOpacity(0.7)
                  : Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                _buildHeader(context, isDark),
                const Divider(height: 1),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBillSummary(context, isDark),
                        const SizedBox(height: 20),
                        Text(
                          "Payment History",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildPaymentList(context, isDark),
                      ],
                    ),
                  ),
                ),

                // Footer
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("Close"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.history_edu,
                color: isDark ? Colors.blueAccent : Colors.blue,
              ),
              const SizedBox(width: 10),
              Text(
                "Transaction History",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: "Close",
          ),
        ],
      ),
    );
  }

  Widget _buildBillSummary(BuildContext context, bool isDark) {
    final style = TextStyle(
      color: isDark ? Colors.white60 : Colors.black54,
      fontSize: 13,
    );
    final valStyle = TextStyle(
      color: isDark ? Colors.white : Colors.black87,
      fontWeight: FontWeight.w600,
      fontSize: 14,
    );

    final totalAmount = bill.totalAmount ?? 0.0;
    final paidAmount = totalAmount - receipt.dueAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _row("Bill No", "#${receipt.billNo}", style, valStyle),
          const SizedBox(height: 8),
          _row("Date", receipt.dateFormatted ?? "N/A", style, valStyle),
          const SizedBox(height: 8),
          _row("Customer", receipt.customer, style, valStyle),
          const Divider(height: 24),
          _row(
            "Total Amount",
            totalAmount.toStringAsFixed(2),
            style,
            valStyle.copyWith(color: Colors.blue),
          ),
          const SizedBox(height: 8),
          _row(
            "Paid Amount",
            paidAmount.toStringAsFixed(2),
            style,
            valStyle.copyWith(color: Colors.green),
          ),
          const SizedBox(height: 8),
          _row(
            "Due Amount",
            receipt.dueAmount.toStringAsFixed(2),
            style,
            valStyle.copyWith(color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, TextStyle lStyle, TextStyle vStyle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: lStyle),
        Text(value, style: vStyle),
      ],
    );
  }

  Widget _buildPaymentList(BuildContext context, bool isDark) {
    if (bill.payments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            "No payment records found.",
            style: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bill.payments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final p = bill.payments[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.mode,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  if (p.utr != null && p.utr!.isNotEmpty)
                    Text(
                      "Ref: ${p.utr}",
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black45,
                      ),
                    ),
                  if (p.date != null)
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(p.date!),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black45,
                      ),
                    ),
                ],
              ),
              Text(
                "+ ${p.price.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
