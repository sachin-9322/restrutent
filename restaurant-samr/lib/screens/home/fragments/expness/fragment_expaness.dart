// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:splash_screen_03/model/entity_expnaess.dart';
import 'package:splash_screen_03/screens/home/fragments/expness/controller_expness.dart';

class ExpenseDashboard extends StatelessWidget {
  const ExpenseDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final ExpenseController controller = Get.put(ExpenseController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final bool isMobile = width < 700;
            final bool isTablet = width >= 700 && width < 1100;

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 20,
                vertical: isMobile ? 10 : 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Header Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          "Expense Dashboard",
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 18 : 22,
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => showAddMultipleExpensesDialog(
                                context, controller),
                            icon: const Icon(Icons.add),
                            label: Text(
                              "Add Expenses",
                              style: TextStyle(fontSize: isMobile ? 13 : 14),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 14 : 18,
                                vertical: isMobile ? 10 : 12,
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                showAddVendorDialog(context, controller),
                            icon: const Icon(Icons.storefront_outlined),
                            label: Text(
                              "Add Vendor",
                              style: TextStyle(fontSize: isMobile ? 13 : 14),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 14 : 18,
                                vertical: isMobile ? 10 : 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 🔹 Summary Cards Row
                  SizedBox(
                    height: isMobile ? 95 : 110,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        const SizedBox(width: 4),
                        _summaryCard(
                          title: "Today's Expenses",
                          amountObs: () => controller.todayExpenses,
                          color: const LinearGradient(
                            colors: [Color(0xFFff7e5f), Color(0xFFfeb47b)],
                          ),
                        ),
                        _summaryCard(
                          title: "This Month",
                          amountObs: () => controller.thisMonthExpenses,
                          color: const LinearGradient(
                            colors: [Color(0xFF43cea2), Color(0xFF185a9d)],
                          ),
                        ),
                        _summaryCard(
                          title: "Total",
                          amountObs: () => controller.totalExpenses,
                          color: const LinearGradient(
                            colors: [Color(0xFFf7971e), Color(0xFFffd200)],
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🔹 Search Bar + Refresh
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: theme.cardColor,
                            hintText: "Search expenses, vendor...",
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            hintStyle: TextStyle(color: theme.hintColor),
                            contentPadding: const EdgeInsets.all(0),
                          ),
                          style:
                              TextStyle(color: theme.colorScheme.onSurface),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: controller.refresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Refresh"),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 14 : 16,
                            vertical: isMobile ? 10 : 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 🔹 Responsive Layout for Table + Chart
                  Expanded(
                    child: isMobile
                        ? Column(
                            children: [
                              Expanded(
                                  child: _expenseTable(controller, context)),
                              const SizedBox(height: 12),
                              SizedBox(
                                  height: 260,
                                  child: _expenseChart(controller, isDark)),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  flex: 3,
                                  child: _expenseTable(controller, context)),
                              const SizedBox(width: 16),
                              Expanded(
                                  flex: 2,
                                  child: SizedBox(
                                      height: double.infinity,
                                      child: _expenseChart(
                                          controller, isDark))),
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }


  void _showEditExpenseDialog(BuildContext context, ExpenseController controller, ExpenseEntity expense) {
    final amountC = TextEditingController(text: expense.amount.toString());
    final descC = TextEditingController(text: expense.description ?? "");
    String paymentMode = expense.paymentMode ?? "Cash";
    String? selectedVendorUuid = expense.vendorUuid;
    DateTime selectedDate = expense.date;
    TimeOfDay selectedTime = TimeOfDay(hour: expense.date.hour, minute: expense.date.minute);
    bool nonRefundable = expense.nonRefundable;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Edit Expense"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: amountC, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: "Amount (AED)")),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: selectedVendorUuid,
                    items: [const DropdownMenuItem(value: null, child: Text("No vendor")), ...controller.vendors.map((v) => DropdownMenuItem(value: v.uuid, child: Text(v.name)))],
                    onChanged: (v) => setState(() => selectedVendorUuid = v),
                    decoration: const InputDecoration(labelText: "Vendor (optional)"),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: paymentMode,
                    items: const [DropdownMenuItem(value: 'Cash', child: Text('Cash')), DropdownMenuItem(value: 'Card', child: Text('Card')), DropdownMenuItem(value: 'UPI', child: Text('UPI')), DropdownMenuItem(value: 'Other', child: Text('Other'))],
                    onChanged: (v) => setState(() => paymentMode = v ?? 'Cash'),
                    decoration: const InputDecoration(labelText: "Payment Mode"),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                            if (picked != null) {
                              setState(() => selectedDate = DateTime(picked.year, picked.month, picked.day, selectedDate.hour, selectedDate.minute));
                            }
                          },
                          child: Text("Date: ${selectedDate.toLocal().toString().split(' ')[0]}"),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final picked = await showTimePicker(context: context, initialTime: selectedTime);
                            if (picked != null) {
                              setState(() {
                                selectedTime = picked;
                                selectedDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, picked.hour, picked.minute);
                              });
                            }
                          },
                          child: Text("Time: ${selectedTime.format(context)}"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: descC, decoration: const InputDecoration(labelText: "Description (optional)")),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(value: nonRefundable, onChanged: (v) => setState(() => nonRefundable = v ?? false)),
                      const SizedBox(width: 6),
                      const Expanded(child: Text("Non-refundable")),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  final amt = double.tryParse(amountC.text.trim());
                  if (amt == null) {
                    Get.snackbar("Error", "Please enter a valid amount.", backgroundColor: Colors.red);
                    return;
                  }
                  
                  final updatedExpense = ExpenseEntity(
                    amount: amt, 
                    date: selectedDate, 
                    paymentMode: paymentMode, 
                    description: descC.text.trim().isEmpty ? null : descC.text.trim(), 
                    nonRefundable: nonRefundable, 
                    vendorUuid: selectedVendorUuid
                  );
                  updatedExpense.id = expense.id;

                  await controller.updateExpense(updatedExpense); 
                  
                  Navigator.pop(context);
                  Get.snackbar("Success", "Expense updated successfully.", backgroundColor: Colors.green);
                },
                child: const Text("Save Changes"),
              ),
            ],
          );
        },
      ),
    );
  }
  // 🔹 Summary Card Widget
  Widget _summaryCard({
    required String title,
    required double Function() amountObs,
    required LinearGradient color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          gradient: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.colors.last.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              Obx(() {
                final amt = amountObs();
                return Text(
                  "AED ${amt.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Expense Table (unchanged logic, responsive padding added)
  Widget _expenseTable(ExpenseController controller, BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedDate = Rx<DateTime>(DateTime.now());
    final showNonRefundable = RxBool(false);
    final selectedFilter = "Daily".obs;
    final startDate = Rx<DateTime?>(null);
    final endDate = Rx<DateTime?>(null);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              blurRadius: 8,
              color: isDark ? Colors.white12 : Colors.black12,
              offset: const Offset(0, 3))
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // 🔸 Filter Controls
          Row(
            children: [
              Obx(
                () => DropdownButton<String>(
                  value: selectedFilter.value,
                  items: ["Daily", "Weekly", "Monthly", "Yearly", "Custom"]
                      .map((f) => DropdownMenuItem(
                          value: f,
                          child: Text(f, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) selectedFilter.value = v;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Obx(() {
                  if (selectedFilter.value == "Custom") {
                    return TextButton.icon(
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        startDate.value != null && endDate.value != null
                            ? "${startDate.value!.toLocal().toString().split(' ')[0]} → ${endDate.value!.toLocal().toString().split(' ')[0]}"
                            : "Pick Custom Range",
                        style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      onPressed: () async {
                        final range = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (range != null) {
                          startDate.value = range.start;
                          endDate.value = range.end;
                        }
                      },
                    );
                  } else {
                    return TextButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate.value,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) selectedDate.value = picked;
                      },
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        "Date: ${DateFormat('yyyy-MM-dd').format(selectedDate.value)}",
                        style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    );
                  }
                }),
              ),
              const SizedBox(width: 10),
              Obx(
                () => DropdownButton<String>(
                  value: showNonRefundable.value
                      ? "Non-Chargeable"
                      : "All",
                  items: const [
                    DropdownMenuItem(value: "All", child: Text("All")),
                    DropdownMenuItem(
                        value: "Non-Chargeable",
                        child: Text("Non-Chargeable"))
                  ],
                  onChanged: (v) =>
                      showNonRefundable.value = (v == "Non-Chargeable"),
                ),
              ),
            ],
          ),
          const Divider(),
          // 🔸 Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: Row(
              children: const [
                Expanded(flex: 2, child: Text("Date", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text("Amount", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text("Payment", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text("Vendor", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          const Divider(height: 6),
          // 🔸 Expense Rows
          Expanded(
            child: Obx(() {
              final filtered = controller.expenses.where((e) {
                if (showNonRefundable.value && !e.nonRefundable) return false;
                final eDate = DateTime(e.date.year, e.date.month, e.date.day);
                bool match;
                switch (selectedFilter.value) {
                  case "Daily":
                    final sel = DateTime(selectedDate.value.year,
                        selectedDate.value.month, selectedDate.value.day);
                    match = eDate.isAtSameMomentAs(sel);
                    break;
                  case "Weekly":
                    final sel = selectedDate.value;
                    final start = sel.subtract(Duration(days: sel.weekday - 1));
                    final end = start.add(const Duration(days: 6));
                    match =
                        !eDate.isBefore(start) && !eDate.isAfter(end);
                    break;
                  case "Monthly":
                    match = e.date.year == selectedDate.value.year &&
                        e.date.month == selectedDate.value.month;
                    break;
                  case "Yearly":
                    match = e.date.year == selectedDate.value.year;
                    break;
                  case "Custom":
                    if (startDate.value == null || endDate.value == null)
                      return false;
                    match = !eDate.isBefore(startDate.value!) &&
                        !eDate.isAfter(endDate.value!);
                    break;
                  default:
                    match = false;
                }
                return match;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                    child: Text("No records found",
                        style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant)));
              }

              return ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: theme.dividerColor.withOpacity(0.1)),
                itemBuilder: (context, i) {
                  final e = filtered[i];
                  final vendor = controller.vendors.firstWhereOrNull(
                      (v) => v.uuid == e.vendorUuid);
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 2,
                            child: Text(
                                DateFormat('yyyy-MM-dd HH:mm')
                                    .format(e.date),
                                style: TextStyle(
                                    color: theme.colorScheme
                                        .onSurfaceVariant))),
                        Expanded(
                            child: Text(
                                "AED ${e.amount.toStringAsFixed(2)}",
                                style: TextStyle(
                                    color: theme.colorScheme
                                        .onSurfaceVariant))),
                        Expanded(
                            child: Text(e.paymentMode ?? "Cash",
                                style: TextStyle(
                                    color: theme.colorScheme
                                        .onSurfaceVariant))),
                        Expanded(
                            child: Text(vendor?.name ?? "None",
                                style: TextStyle(
                                    color: theme.colorScheme
                                        .onSurfaceVariant))),
                        Expanded(
                          child: Row(
                            children: [
                              IconButton(
                                  onPressed: () =>
                                      _showEditExpenseDialog(context,
                                          controller, e),
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blueAccent, size: 18)),
                              IconButton(
                                  onPressed: () =>
                                      controller.deleteExpenseById(e.id),
                                  icon: const Icon(Icons.delete,
                                      color: Colors.redAccent, size: 18)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // 🔹 Chart (unchanged logic)
  Widget _expenseChart(ExpenseController controller, bool isDark) {
    final theme = Theme.of(Get.context!);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              blurRadius: 8,
              color: isDark ? Colors.white12 : Colors.black12,
              offset: const Offset(0, 3))
        ],
      ),
      child: Obx(() {
        if (controller.expenses.isEmpty) {
          return Center(
              child: Text("No chart data",
                  style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant)));
        }
        final dailyData = controller.getDailyExpensesForLastNDays(14);
        final maxValue =
            dailyData.isEmpty ? 1.0 : dailyData.reduce((a, b) => a > b ? a : b);
        final maxY = (maxValue * 1.25).clamp(1.0, double.infinity);
        final barGroups = List.generate(14, (i) {
          final day = DateTime.now().subtract(Duration(days: 13 - i));
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: dailyData[i],
                width: 18,
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: isDark
                      ? [Colors.cyanAccent, Colors.blueAccent]
                      : [Colors.teal.shade300, Colors.teal.shade700],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                backDrawRodData: BackgroundBarChartRodData(
                    show: true, toY: maxY, color: Colors.grey.withOpacity(0.06)),
              )
            ],
          );
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Last 14 Days",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant)),
                Text(
                    "Total AED ${dailyData.fold(0.0, (a, b) => a + b).toStringAsFixed(2)}",
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface)),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  titlesData: FlTitlesData(
                    show: true,
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: maxY / 4,
                          getTitlesWidget: (v, m) => Padding(
                                padding: const EdgeInsets.only(right: 4.0),
                                child: Text(v.toInt().toString(),
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: theme.colorScheme
                                            .onSurfaceVariant)),
                              )),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, m) {
                            final day = DateTime.now()
                                .subtract(Duration(days: 13 - v.toInt()));
                            return SideTitleWidget(
                                meta: m,
                                child: Text(DateFormat.Md().format(day),
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: theme.colorScheme
                                            .onSurfaceVariant)));
                          }),
                    ),
                  ),
                  gridData: FlGridData(show: true, horizontalInterval: maxY / 4),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
