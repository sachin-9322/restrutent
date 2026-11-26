import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/objectbox.g.dart';
import 'package:splash_screen_03/screens/home/Dashboard/controller_dashboard.dart';
import 'package:splash_screen_03/screens/home/fragments/table_order/widget/glass_card.dart';

class TopSellingItemsChart extends StatefulWidget {
  const TopSellingItemsChart({super.key});

  @override
  State<TopSellingItemsChart> createState() => _TopSellingItemsChartState();
}

class _TopSellingItemsChartState extends State<TopSellingItemsChart> {
  String _selectedRange = 'Today';
  final ControllerDashboard c = Get.put(ControllerDashboard());

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return GlasssCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 200,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Top Selling Items",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => setState(() => _selectedRange = value),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'Today', child: Text('Today')),
                    PopupMenuItem(value: 'Weekly', child: Text('Weekly')),
                    PopupMenuItem(value: 'Monthly', child: Text('Monthly')),
                    PopupMenuItem(value: 'Yearly', child: Text('Yearly')),
                  ],
                  icon: Icon(Icons.more_vert, color: subTextColor),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Obx(() {
                final items = c.getTopSellingItemsForRange(_selectedRange);

                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      "No sales data for $_selectedRange",
                      style: TextStyle(color: subTextColor),
                    ),
                  );
                }

                final colors = [
                  const Color(0xFF5B9CFF),
                  const Color(0xFFF7C880),
                  const Color(0xFF8ADE8E),
                  Color(0xFF005D6A),
                  const Color(0xFFF0F4F7),
                ];

                final sections = <PieChartSectionData>[];
                for (int i = 0; i < items.length; i++) {
                  final it = items[i];
                  final qty = (it['qty'] as int).toDouble();
                  sections.add(
                    PieChartSectionData(
                      color: colors[i % colors.length],
                      value: qty,
                      showTitle: false,
                      radius: 30,
                    ),
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 5,
                          centerSpaceRadius: 35,
                          sections: sections,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < items.length; i++)
                              _buildLegendItem(
                                colors[i % colors.length],
                                items[i]['name'] ?? 'Unknown',
                                "${items[i]['qty']}",
                                textColor,
                                subTextColor,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(
    Color color,
    String title,
    String value,
    Color textColor,
    Color subTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: textColor, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(value, style: TextStyle(color: subTextColor, fontSize: 14)),
        ],
      ),
    );
  }
}

// ---------------- Payment Mode Chart ---------------- //

class PaymentModeChart extends StatelessWidget {
  const PaymentModeChart({super.key});

  Widget _buildLegendItem(
    Color color,
    String title,
    String amount,
    Color textColor,
    Color subTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  amount,
                  style: TextStyle(color: subTextColor, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedRange = 'Today'.obs;
    final ControllerDashboard controller = Get.find();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return GlasssCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 200,
        child: Obx(() {
          final currentRange = selectedRange.value;
          final amounts = controller.getPaymentModeAmountsForRange(
            currentRange,
          );
          final total = amounts.values.fold<double>(0, (p, n) => p + n);

          if (total == 0) {
            return Center(
              child: Text(
                "No Data for $currentRange",
                style: TextStyle(color: subTextColor),
              ),
            );
          }

          final colors = [
            const Color(0xFFE96C52),
            const Color(0xFF90C88E),
            const Color(0xFFAECFED),
            const Color(0xFFE0E0E0),
            const Color(0xFF7BADEB),
            Color(0xFF005D6A),
            Colors.cyan.shade100,
          ];

          int i = 0;
          final sections = amounts.entries.map((e) {
            final pct = (e.value / total) * 100;
            final color = colors[i++ % colors.length];
            return PieChartSectionData(
              color: color,
              value: e.value.toDouble(),
              title: '${pct.toStringAsFixed(0)}%',
              radius: 45,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            );
          }).toList();

          i = 0;
          final legendItems = amounts.entries.map((e) {
            final color = colors[i++ % colors.length];
            return _buildLegendItem(
              color,
              e.key,
              '₹${e.value.toStringAsFixed(2)}',
              textColor,
              subTextColor,
            );
          }).toList();

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Payment Modes",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => selectedRange.value = value,
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'Today', child: Text('Today')),
                      PopupMenuItem(value: 'Weekly', child: Text('Weekly')),
                      PopupMenuItem(value: 'Monthly', child: Text('Monthly')),
                      PopupMenuItem(value: 'Yearly', child: Text('Yearly')),
                    ],
                    icon: Icon(Icons.more_vert, color: subTextColor),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Row(
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
                          children: legendItems,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
