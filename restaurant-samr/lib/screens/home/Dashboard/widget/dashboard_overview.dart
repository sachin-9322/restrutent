import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/objectbox.g.dart';
import 'package:splash_screen_03/screens/home/Dashboard/controller_dashboard.dart';
import 'package:splash_screen_03/screens/home/fragments/table_order/widget/glass_card.dart';

/// 🔹 Dashboard Chart (Dynamic + GlasssCard)
class DashboardOverviewChart extends StatelessWidget {
  const DashboardOverviewChart({super.key});

  @override
  Widget build(BuildContext context) {
    final ControllerDashboard controller = Get.find();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    // ✅ Use reactive data from controller
    return Obx(() {
      final chartData = controller.overviewChartData;
      
      // ✅ Build grouped bars
      final barGroups = chartData.asMap().entries.map((entry) {
        final index = entry.key;
        final d = entry.value;
        return BarChartGroupData(
          x: index,
          barsSpace: 8,
          barRods: [
            BarChartRodData(
              toY: (d['sales'] as double) / 1000,
              color: const Color(0xFFB388FF),
              width: 18,
              borderRadius: BorderRadius.circular(6),
            ),
            BarChartRodData(
              toY: (d['cancel'] as double) / 1000,
              color: const Color(0xFFEF5350),
              width: 18,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        );
      }).toList();

      // ✅ Compute max scale
      final maxSales = chartData.isNotEmpty
          ? chartData
              .map((d) => (d['sales'] as double) + (d['cancel'] as double))
              .reduce((a, b) => a > b ? a : b)
          : 1000.0;
      final maxY = (maxSales / 1000) * 1.3;

      // ✅ Glassmorphic chart card
      return GlasssCard(
        borderRadius: 18,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  barGroups: barGroups,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black12,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final label = rodIndex == 0 ? 'Sales' : 'Cancelled';
                        final value = rod.toY * 1000;
                        return BarTooltipItem(
                          "$label\n₹${value.toStringAsFixed(0)}",
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (v, _) {
                          if (v == 0) return const Text('');
                          return Text(
                            '${v.toInt()}K',
                            style: TextStyle(color: subTextColor, fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          if (value < 0 || value >= chartData.length) {
                            return const Text('');
                          }
                          return Text(
                            chartData[value.toInt()]['day'],
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _LegendItem(color: Color(0xFFB388FF), text: "Total Sales"),
                SizedBox(width: 20),
                _LegendItem(color: Color(0xFFEF5350), text: "Total Cancelled"),
              ],
            ),
          ],
        ),
      );
    });
  }
}

/// 🔹 Small legend indicator row
class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }
}
