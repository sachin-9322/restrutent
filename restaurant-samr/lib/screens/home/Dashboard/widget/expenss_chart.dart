import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/screens/home/fragments/expness/controller_expness.dart'; // adjust import as needed

const Color cardColor = Color(0xFF2A2D3A);
const Color textColor = Colors.white;
const Color subTextColor = Colors.white70;

class ExpensePieChart extends StatelessWidget {
  const ExpensePieChart({super.key});

  @override
  Widget build(BuildContext context) {
    final ExpenseController controller = Get.put(ExpenseController());

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      height: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Expense Breakdown",
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // ✅ Dynamic Pie Chart
          Expanded(
            child: Obx(() {
              final expenses = controller.expenses;
              if (expenses.isEmpty) {
                return const Center(
                  child: Text(
                    "No expense data available",
                    style: TextStyle(color: subTextColor),
                  ),
                );
              }

              // Group expenses by Category (or Vendor if no category)
              final Map<String, double> groupedData = {};
              for (final e in expenses) {
                final category = controller.categories
                    .firstWhereOrNull((c) => c.uuid == e.categoryUuid);
                final vendor = controller.vendors
                    .firstWhereOrNull((v) => v.uuid == e.vendorUuid);

                final key = category?.name ?? vendor?.name ?? "Uncategorized";
                groupedData[key] = (groupedData[key] ?? 0) + e.amount;
              }

              // Total expense sum
              final total = groupedData.values.fold(0.0, (a, b) => a + b);

              // Chart colors
              final colors = [
                Colors.redAccent,
                Colors.blueAccent,
                Colors.orangeAccent,
                Colors.teal,
                Colors.greenAccent,
                Colors.purpleAccent,
                Colors.amber,
              ];

              int i = 0;
              final sections = groupedData.entries.map((e) {
                final pct = (e.value / total) * 100;
                final color = colors[i % colors.length];
                i++;
                return PieChartSectionData(
                  color: color,
                  value: e.value,
                  title: '${pct.toStringAsFixed(0)}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList();

              // Legend section
              i = 0;
              final legend = groupedData.entries.map((e) {
                final color = colors[i % colors.length];
                i++;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Icon(Icons.circle, color: color, size: 10),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.key,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: subTextColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        "₹${e.value.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();

              return Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: sections,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: legend,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
