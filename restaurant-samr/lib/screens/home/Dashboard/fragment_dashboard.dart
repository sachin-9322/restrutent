// ignore_for_file: unused_local_variable

import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:splash_screen_03/screens/home/Dashboard/controller_dashboard.dart';
import 'package:splash_screen_03/screens/home/Dashboard/widget/casflow_card.dart';
import 'package:splash_screen_03/screens/home/Dashboard/widget/dashboard_overview.dart';
import 'package:splash_screen_03/screens/home/Dashboard/widget/fragment_sales.dart';
import 'package:splash_screen_03/screens/home/fragments/expness/controller_expness.dart';
import 'package:splash_screen_03/screens/home/fragments/day/day_report.dart';
import 'package:splash_screen_03/screens/home/Dashboard/widget/expenss_chart.dart';
import 'package:splash_screen_03/screens/home/fragments/table_order/widget/glass_card.dart';

// --- THEME-INDEPENDENT COLORS ---
// These colors are for status (e.g., success, danger) and can remain constant across themes.
const Color greenColor = Color.fromARGB(255, 10, 161, 56);
const Color redColor = Color(0xFFE53935);
// The old hardcoded theme colors have been removed from here and are now handled within each widget.

class DashboardUiController extends GetxController {
  final RxBool showExpenseChart = false.obs;

  Future<void> addExpenseChart() async {
    showExpenseChart.value = true;
    try {
      final storage = GetStorage();
      await storage.write('showExpenseChart', true);
    } catch (_) {
      /* ignore */
    }
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF101417) : Colors.grey[100];

    if (!Get.isRegistered<ExpenseController>()) {
      Get.put(ExpenseController(), permanent: true);
    }

    final ControllerDashboard c = Get.isRegistered<ControllerDashboard>()
        ? Get.find<ControllerDashboard>()
        : Get.put(ControllerDashboard(), permanent: true);

    final ui = Get.isRegistered<DashboardUiController>()
        ? Get.find<DashboardUiController>()
        : Get.put(DashboardUiController(), permanent: true);

    final ExpenseController expenseC = Get.find<ExpenseController>();

    return Scaffold(
      backgroundColor: bgColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final bool isMobile = width < 700;
          final bool isTablet = width >= 700 && width < 1100;
          final bool isDesktop = width >= 1100;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12.0),
            child: Obx(() {
              final selectedRange = c.selectedRange.value;

              final totalSalesAmount = c
                  .totalAmountForRange(selectedRange)
                  .toStringAsFixed(2);
              final totalSalesCount = c.totalCountForRange(selectedRange);
              final dineInAmount = c
                  .orderTypeTotalForRange('Dine-In', selectedRange)
                  .toStringAsFixed(2);
              final dineInCount = c.orderTypeCountForRange(
                'Dine-In',
                selectedRange,
              );
              final takeawayAmount = c
                  .orderTypeTotalForRange('Takeaway', selectedRange)
                  .toStringAsFixed(2);
              final takeawayCount = c.orderTypeCountForRange(
                'Takeaway',
                selectedRange,
              );
              final deliveryAmount = c
                  .orderTypeTotalForRange('Delivery', selectedRange)
                  .toStringAsFixed(2);
              final deliveryCount = c.orderTypeCountForRange(
                'Delivery',
                selectedRange,
              );
              final yesterdaySales = c.yesterdaySalesTotal.value;
              final isTrendingUp = c.totalToday.value >= yesterdaySales;

              final cardSpacing = isMobile ? 10.0 : 8.0;
              final columnCount = isDesktop
                  ? 5
                  : isTablet
                  ? 3
                  : 2;

              // --- Cards ---
              final cards = [
                SummaryCard(
                  title: selectedRange == 'Today'
                      ? "Today's Sales"
                      : "$selectedRange Sales",
                  amount: "₹$totalSalesAmount",
                  orderCount: "$totalSalesCount orders",
                  isTrendingUp: isTrendingUp,
                  isToday: selectedRange == 'Today',
                  chipLabel: selectedRange,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) => c.selectedRange.value = value,
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'Today', child: Text('Today')),
                      PopupMenuItem(value: 'Weekly', child: Text('Weekly')),
                      PopupMenuItem(value: 'Monthly', child: Text('Monthly')),
                      PopupMenuItem(value: 'Yearly', child: Text('Yearly')),
                    ],
                    icon: Icon(
                      Icons.more_vert,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
                SummaryCard(
                  title: "Dine-In",
                  amount: "₹$dineInAmount",
                  orderCount: "$dineInCount orders",
                  isTrendingUp: true,
                ),
                SummaryCard(
                  title: "Takeaway",
                  amount: "₹$takeawayAmount",
                  orderCount: "$takeawayCount orders",
                  isTrendingUp: true,
                ),
                SummaryCard(
                  title: "Delivery",
                  amount: "₹$deliveryAmount",
                  orderCount: "$deliveryCount orders",
                  isTrendingUp: true,
                ),
                Obx(() {
                  final totalExp = expenseC.totalExpenses.toStringAsFixed(2);
                  return SummaryCard(
                    title: "Expenses",
                    amount: "₹$totalExp",
                    orderCount: "${expenseC.expenses.length} entries",
                    isTrendingUp: false,
                  );
                }),
              ];

              // === Adaptive Grid for Cards ===
              Widget summaryGrid = GridView.count(
                crossAxisCount: columnCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: cardSpacing,
                crossAxisSpacing: cardSpacing,
                childAspectRatio: isMobile ? 1.1 : 1.8,
                children: cards,
              );

              // === Charts Section ===
              final chartsSection = isMobile
                  ? Column(
                      children: [
                        const TotalSalesChart(),
                        const SizedBox(height: 8),
                        CashFlowChart(),
                        const SizedBox(height: 8),
                        const TopSellingItemsChart(),
                        const SizedBox(height: 8),
                        const DashboardOverviewChart(),
                        const SizedBox(height: 8),
                        const PaymentModeChart(),
                      ],
                    )
                  : Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(flex: 2, child: TotalSalesChart()),
                            const SizedBox(width: 8),
                            Expanded(flex: 1, child: CashFlowChart()),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Expanded(child: TopSellingItemsChart()),
                            SizedBox(width: 8),
                            Expanded(child: DashboardOverviewChart()),
                            SizedBox(width: 8),
                            Expanded(child: PaymentModeChart()),
                          ],
                        ),
                      ],
                    );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  summaryGrid,
                  const SizedBox(height: 8),
                  chartsSection,
                  const SizedBox(height: 8),
                  Obx(
                    () => ui.showExpenseChart.value
                        ? const ExpensePieChart()
                        : const SizedBox.shrink(),
                  ),
                ],
              );
            }),
          );
        },
      ),
    );
  }
}

class TotalSalesChart extends StatelessWidget {
  const TotalSalesChart({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboard = Get.find<ControllerDashboard>();
    final expensesCtrl = Get.find<ExpenseController>();

    return Obx(() {
      final range = int.parse(dashboard.chartRange.value); // 7, 15, or 30

      return _buildChart(context, dashboard, expensesCtrl, range);
    });
  }

  Widget _buildChart(
    BuildContext context,
    ControllerDashboard dashboard,
    ExpenseController expensesCtrl,
    int range, // This argument is now redundant but kept for signature compatibility if needed, or we can remove it.
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    final salesColor = isDark ? Colors.white : Colors.black87;
    final expenseColor = isDark ? Colors.white54 : Colors.black45;

    return GlasssCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        height: 380,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -----------------------------------------------------------
            // Header + FILTER BUTTONS
            // -----------------------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Sales",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                Row(
                  children: [
                    _legendDot(salesColor),
                    Text(" Sales", style: TextStyle(color: subTextColor)),
                    const SizedBox(width: 12),
                    _legendDot(expenseColor),
                    Text(" Expenses", style: TextStyle(color: subTextColor)),
                    const SizedBox(width: 15),

                    // 👇 FILTER BUTTON
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        dashboard.chartRange.value = value;
                      },
                      icon: Icon(Icons.filter_alt, color: textColor),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: "7",
                          child: Text("Weekly (7 days)"),
                        ),
                        PopupMenuItem(value: "15", child: Text("15 Days")),
                        PopupMenuItem(
                          value: "30",
                          child: Text("Monthly (30 days)"),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: Obx(() {
                // Reactive variables
                final rangeStr = dashboard.chartRange.value;
                final rangeInt = int.tryParse(rangeStr) ?? 7;
                
                // Data from controller (already calculated)
                final salesSpots = dashboard.salesSpots;
                
                // Expenses still fetched here (could be optimized too, but focusing on sales first)
                final expensesRaw = expensesCtrl.getDailyExpensesForLastNDays(rangeInt);
                final expenseSpots = List<FlSpot>.generate(
                  rangeInt,
                  (i) => FlSpot(i.toDouble(), expensesRaw[i]),
                );

                // Generate X-axis labels (days)
                final now = DateTime.now();
                final List<DateTime> days = List.generate(rangeInt, (i) {
                  return DateTime(
                    now.year,
                    now.month,
                    now.day,
                  ).subtract(Duration(days: rangeInt - 1 - i));
                });

                // Calculate max Y
                final allValues = [...salesSpots.map((e) => e.y), ...expenseSpots.map((e) => e.y)];
                final maxY = allValues.isEmpty ? 100.0 : (allValues.reduce(max) + 10).toDouble();

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final chartWidth = rangeInt == 7
                        ? constraints.maxWidth
                        : days.length * 55;

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: rangeInt == 7
                          ? const NeverScrollableScrollPhysics()
                          : const BouncingScrollPhysics(),

                      child: SizedBox(
                        width: chartWidth.toDouble(),
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            maxY: maxY,
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),

                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),

                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  reservedSize: 40,
                                  getTitlesWidget: (v, meta) =>
                                      _bottomLabel(v, subTextColor, days),
                                ),
                              ),

                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: maxY / 3,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) => Text(
                                    value.toInt().toString(),
                                    style: TextStyle(color: subTextColor, fontSize: 12),
                                  ),
                                ),
                              ),
                            ),

                            lineBarsData: [
                              LineChartBarData(
                                spots: salesSpots,
                                isCurved: true,
                                barWidth: 3,
                                color: salesColor,
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      salesColor.withOpacity(0.18),
                                      Colors.transparent,
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                                dotData: const FlDotData(show: false),
                              ),

                              LineChartBarData(
                                spots: expenseSpots,
                                isCurved: false,
                                barWidth: 2,
                                color: expenseColor,
                                dashArray: [6, 6],
                                dotData: const FlDotData(show: false),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            )
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // X Axis Label: Day + Date
  // ------------------------------------------------------------------
  Widget _bottomLabel(double value, Color color, List<DateTime> days) {
    if (value < 0 || value >= days.length) return const SizedBox();

    final d = days[value.toInt()];
    const names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    return Column(
      children: [
        Text(
          names[d.weekday - 1],
          style: TextStyle(color: color, fontSize: 11),
        ),
        Text(
          "${d.day}",
          style: TextStyle(color: color.withOpacity(0.8), fontSize: 10),
        ),
      ],
    );
  }

  // Show fewer labels on bigger ranges
  double _calculateInterval(int range) {
    if (range <= 7) return 1;
    if (range <= 15) return 2;
    return 3; // for 30 days
  }

  Widget _legendDot(Color color) => Icon(Icons.circle, color: color, size: 8);
}

Widget _buildLegendItem(
  Color color,
  String text,
  String value,
  Color textColor,
  Color subTextColor,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      children: [
        Icon(Icons.circle, color: color, size: 10),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: subTextColor, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(value, style: TextStyle(color: textColor, fontSize: 14)),
      ],
    ),
  );
}

BarChartGroupData makeGroupData(int x, double y) {
  return BarChartGroupData(
    x: x,
    barRods: [
      BarChartRodData(
        toY: y,
        color: const Color(0xFFB999EC),
        width: 20,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
      ),
    ],
  );
}
