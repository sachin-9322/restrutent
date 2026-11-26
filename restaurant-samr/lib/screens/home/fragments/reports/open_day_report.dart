import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/screens/home/fragments/reports/controller_day_report.dart';
import 'package:splash_screen_03/screens/home/fragments/table_order/widget/glass_card.dart';

class OpenDayReport extends StatefulWidget {
  const OpenDayReport({super.key});

  @override
  State<OpenDayReport> createState() => _OpenDayReportState();
}

class _OpenDayReportState extends State<OpenDayReport> {
  final ScrollController _vScroll = ScrollController();
  final ScrollController _hScroll = ScrollController();

  final ctrl = Get.put(OpenDayReportController());

  @override
  void initState() {
    super.initState();
    ctrl.loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xff0D1117)
          : const Color(0xffE8F0FA),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🔍 SEARCH + DATE DROPDOWN + CLEAR
            Row(
              children: [
                // SEARCH
                Expanded(
                  child: TextField(
                    onChanged: (v) {
                      ctrl.searchText.value = v;
                      ctrl.applyFilters();
                    },
                    decoration: InputDecoration(
                      hintText: "Search by name...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),

                // DATE FILTER DROPDOWN
                Obx(
                  () => PopupMenuButton<String>(
                    onSelected: (val) async {
                      if (val == "Custom Range") {
                        final range = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (range != null) {
                          ctrl.setCustomRange(range.start, range.end);
                        }
                      } else {
                        ctrl.setDateFilter(val);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: "Today", child: Text("Today")),
                      PopupMenuItem(
                        value: "Yesterday",
                        child: Text("Yesterday"),
                      ),
                      PopupMenuItem(
                        value: "Last 7 Days",
                        child: Text("Last 7 Days"),
                      ),
                      PopupMenuItem(
                        value: "This Month",
                        child: Text("This Month"),
                      ),
                      PopupMenuItem(
                        value: "Custom Range",
                        child: Text("Custom Range"),
                      ),
                      PopupMenuItem(value: "All Time", child: Text("All Time")),
                    ],
                    child: Chip(
                      label: Text(ctrl.selectedFilter.value),
                      avatar: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
                const SizedBox(width: 15),

                // CLEAR
                TextButton(
                  onPressed: ctrl.clearFilters,
                  child: const Text("Clear"),
                ),
                const SizedBox(width: 8),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffA7D3F5), // light blue
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => ctrl.exportReport(),
                  icon: const Icon(Icons.download_rounded, size: 20),
                  label: const Text("Export"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // MAIN CARD
            Expanded(
              child: GlasssCard(
                borderRadius: 16,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    // TABLE
                    Expanded(
                      child: Obx(() {
                        if (ctrl.filteredRows.isEmpty) {
                          return const Center(
                            child: Text(
                              "No records found",
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        return Scrollbar(
                          controller: _vScroll,
                          child: SingleChildScrollView(
                            controller: _vScroll,
                            child: Scrollbar(
                              controller: _hScroll,
                              child: SingleChildScrollView(
                                controller: _hScroll,
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: 1200),
                                  child: _buildTable(isDark),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    // FOOTER
                    // Obx(() => _buildFooter(isDark)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(bool isDark) {
    const headerStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 13,
      color: Color(0xff9AA1A9),
    );

    return Obx(() {
      return DataTable(
        headingRowColor: WidgetStateProperty.all(
          Colors.white.withOpacity(isDark ? 0.05 : 0.2),
        ),
        columns: const [
          DataColumn(label: Text("Start Date")),
          DataColumn(label: Text("End Date")),
          DataColumn(label: Text("Started By")),
          DataColumn(label: Text("Closed By")),
          DataColumn(label: Text("Invoice Range")),
          DataColumn(label: Text("Opening Bal")),
          DataColumn(label: Text("Total Sales")),
          DataColumn(label: Text("Expenses")),
          DataColumn(label: Text("Closing Bal")),
        ],
        rows: ctrl.filteredRows.map((row) {
          return DataRow(
            cells: [
              DataCell(Text(row.startDate)),
              DataCell(Text(row.endDate)),
              DataCell(Text(row.startedBy)),
              DataCell(Text(row.closedBy)),
              DataCell(Text(row.invoiceRange)),
              DataCell(Text(row.openingBal.toStringAsFixed(2))),
              DataCell(Text(row.totalSales.toStringAsFixed(2))),
              DataCell(Text(row.expenses.toStringAsFixed(2))),
              DataCell(Text(row.closingBal.toStringAsFixed(2))),
            ],
          );
        }).toList(),
      );
    });
  }

  Widget _buildFooter(bool isDark) {
    final totalSales = ctrl.filteredRows.fold<double>(
      0,
      (sum, row) => sum + row.totalSales,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isDark ? 0.05 : 0.25),
      ),
      child: Text(
        "Total Sales: AED ${totalSales.toStringAsFixed(2)}",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}
