import 'dart:math';
import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/screens/home/Dashboard/controller_dashboard.dart';
import 'package:splash_screen_03/screens/home/fragments/expness/controller_expness.dart';
import 'package:splash_screen_03/screens/home/fragments/table_order/widget/glass_card.dart';

const Color kDarkBgColor = Color(0xFF26292E);
const Color kDarkTextColor = Colors.white;
const Color kDarkSubTextColor = Colors.white70;

const Color kLightBgColor = Color(0xFFF5F5F5);
const Color kLightTextColor = Colors.black87;
const Color kLightSubTextColor = Color(0xFF5A5A5A);

class ControllerCashFlow extends GetxController {
  RxBool showInflow = true.obs;
  RxBool showOutflow = true.obs;

  final RxString range = 'Weekly'.obs;
  List<String> get ranges => const ['Daily', 'Weekly', 'Monthly', 'Yearly'];
}

class CashFlowChart extends StatelessWidget {
  CashFlowChart({super.key});

  final ControllerCashFlow c = Get.put(ControllerCashFlow(), permanent: true);

  @override
  Widget build(BuildContext context) {
    final double screenWidth = Get.width;
    final bool isSmallScreen = screenWidth < 650;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? kDarkTextColor : kLightTextColor;
    final Color subTextColor = isDark ? kDarkSubTextColor : kLightSubTextColor;

    final Color inflowColor =
        isDark ? Color(0xFF005D6A) : Color(0xFF005D6A);
    final Color outflowColor =
        isDark ? const Color(0xFFC5B2FF) : const Color(0xFF9B8AFF);

    final Color checkboxBorderColor = isDark ? Colors.white54 : Colors.black54;

    final dash = Get.find<ControllerDashboard>();
    final exp = Get.find<ExpenseController>();

    return GlasssCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(18),
      child: Container(
        constraints: const BoxConstraints(minHeight: 350, maxHeight: 500),
        height: Get.height * 0.45,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- Header Row ----------
            Row(
              children: [
                Text(
                  "CashFlow",
                  style: TextStyle(
                    color: textColor,
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Obx(() {
                  return DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor:
                          isDark ? kDarkBgColor.withOpacity(0.8) : Colors.white,
                      value: c.range.value,
                      items: c.ranges
                          .map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text(
                                r,
                                style: TextStyle(color: subTextColor),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) c.range.value = val;
                      },
                    ),
                  );
                }),
              ],
            ),

            const SizedBox(height: 12),

            // ---------- Toggles ----------
            Wrap(
              spacing: isSmallScreen ? 8.0 : 20.0,
              runSpacing: 4.0,
              children: [
                _buildToggle(
                  "Sales",
                  c.showInflow,
                  inflowColor,
                  textColor,
                  checkboxBorderColor,
                ),
                _buildToggle(
                  "Expenses",
                  c.showOutflow,
                  outflowColor,
                  textColor,
                  checkboxBorderColor,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ---------- Chart ----------
            Expanded(
              child: Obx(() {
                final _ = dash.recentOrders.length;
                final __ = exp.expenses.length;

                final salesMap = dash.getCashflowForRange(c.range.value);
                final entries = salesMap.entries.toList();
                if (entries.isEmpty) {
                  return Center(
                    child:
                        Text('No data', style: TextStyle(color: subTextColor)),
                  );
                }

                final range = _rangeFor(c.range.value);
                final labels = _labelsForRange(c.range.value, range.days);

                final expensePerDay =
                    _expensesForRange(exp, range.start, range.days);

                double maxY = 0.0;
                for (int i = 0; i < range.days; i++) {
                  final inflow = c.showInflow.value
                      ? ((entries.length > i
                              ? entries[i].value['inflow']
                              : 0) ??
                          0)
                      : 0.0;
                  final outflow = c.showOutflow.value ? expensePerDay[i] : 0.0;
                  final total = inflow + outflow;
                  if (total > maxY) maxY = total;
                }
                if (maxY <= 0) maxY = 1;
                maxY *= 1.15;

                final yAxisLabelStyle = TextStyle(
                  color: subTextColor,
                  fontSize: isSmallScreen ? 10 : 12,
                );
                final maxYLabel = _formatK(maxY);
                final textPainter = TextPainter(
                  text: TextSpan(text: maxYLabel, style: yAxisLabelStyle),
                  textDirection: TextDirection.ltr,
                )..layout();
                final leftTitleWidth = textPainter.width + 12;

                final chartDrawableWidth =
                    screenWidth - (16 * 2) - leftTitleWidth - 8;
                final minLabelSpacing = range.days > 30 ? 20.0 : 40.0;
                final maxVisibleLabels =
                    (chartDrawableWidth / minLabelSpacing).floor();
                final skip = (labels.length / maxVisibleLabels)
                    .ceil()
                    .clamp(1, labels.length);

                final double barWidth =
                    (chartDrawableWidth / labels.length) * 0.6;
                final double clampedBarWidth = barWidth.clamp(4.0, 22.0);

                final groups = List.generate(range.days, (i) {
                  final inflow = ((entries.length > i
                              ? entries[i].value['inflow']
                              : 0) ??
                          0)
                      .toDouble();
                  final outflow = expensePerDay[i];

                  final bool showIn = c.showInflow.value;
                  final bool showOut = c.showOutflow.value;
                  final double total =
                      (showIn ? inflow : 0) + (showOut ? outflow : 0);

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: total > 0 ? total : 0.0001,
                        width: clampedBarWidth,
                        borderRadius: BorderRadius.circular(5),
                        rodStackItems: _buildRodStacks(
                          inflow: showIn ? inflow : 0,
                          outflow: showOut ? outflow : 0,
                          inflowColor: inflowColor,
                          outflowColor: outflowColor,
                        ),
                      ),
                    ],
                  );
                });

                return BarChart(
                  BarChartData(
                    maxY: maxY,
                    alignment: BarChartAlignment.spaceAround,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: subTextColor.withOpacity(0.14),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= labels.length) {
                              return const SizedBox.shrink();
                            }
                            if (i % skip != 0 &&
                                i != labels.length - 1 &&
                                skip > 1) {
                              return const SizedBox.shrink();
                            }
                            return SideTitleWidget(
                              meta: meta,
                              space: 6,
                              child: Text(
                                labels[i],
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 11,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: leftTitleWidth,
                          interval: _niceInterval(maxY),
                          getTitlesWidget: (value, meta) {
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(
                                _formatK(value),
                                style: yAxisLabelStyle,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    barGroups: groups,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final inflow = ((entries.length > groupIndex
                                      ? entries[groupIndex].value['inflow']
                                      : 0) ??
                                  0)
                              .toDouble();
                          final outflow = expensePerDay[groupIndex];

                          final parts = <String>[
                            labels[groupIndex],
                            if (c.showInflow.value)
                              'Inflow: ${_fmt(inflow)}',
                            if (c.showOutflow.value)
                              'Outflow: ${_fmt(outflow)}',
                          ];
                          return BarTooltipItem(
                            parts.join('\n'),
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helpers (unchanged) ---
  List<BarChartRodStackItem> _buildRodStacks({
    required double inflow,
    required double outflow,
    required Color inflowColor,
    required Color outflowColor,
  }) {
    final List<BarChartRodStackItem> stacks = [];
    double start = 0.0;

    if (inflow > 0) {
      stacks.add(BarChartRodStackItem(start, start + inflow, inflowColor));
      start += inflow;
    }
    if (outflow > 0) {
      stacks.add(BarChartRodStackItem(start, start + outflow, outflowColor));
    }

    if (stacks.isEmpty) {
      return [BarChartRodStackItem(0, 0.0001, Colors.transparent)];
    }
    return stacks;
  }

  Widget _buildToggle(String label, RxBool controller, Color color,
      Color textColor, Color borderColor) {
    return Obx(
      () => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: controller.value,
            onChanged: (v) => controller.value = v ?? true,
            activeColor: color,
            side: BorderSide(color: borderColor),
            visualDensity: VisualDensity.compact,
          ),
          Text(label, style: TextStyle(color: textColor, fontSize: 13)),
          const SizedBox(width: 8),
          _dot(color: color),
        ],
      ),
    );
  }

  static Widget _dot({required Color color}) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  _Range _rangeFor(String range) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (range) {
      case 'Daily':
        return _Range(today, 1);
      case 'Weekly':
        return _Range(today.subtract(const Duration(days: 6)), 7);
      case 'Monthly':
        return _Range(today.subtract(const Duration(days: 29)), 30);
      case 'Yearly':
        return _Range(today.subtract(const Duration(days: 364)), 365);
      default:
        return _Range(today.subtract(const Duration(days: 6)), 7);
    }
  }

  List<double> _expensesForRange(
      ExpenseController exp, DateTime start, int days) {
    final totals = List<double>.filled(days, 0.0);
    final end = start.add(Duration(days: days));
    for (final e in exp.expenses) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      if (!d.isBefore(start) && d.isBefore(end)) {
        final idx = d.difference(start).inDays;
        if (idx >= 0 && idx < days) totals[idx] += (e.amount);
      }
    }
    return totals;
  }

  List<String> _labelsForRange(String range, int count) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (range == 'Weekly' && count == 7) {
      final start = today.subtract(const Duration(days: 6));
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return List.generate(7, (i) {
        final d = start.add(Duration(days: i));
        return days[d.weekday - 1];
      });
    }
    final start = today.subtract(Duration(days: count - 1));
    return List.generate(
        count, (i) => '${start.add(Duration(days: i)).month}/${start.add(Duration(days: i)).day}');
  }

  static double _niceInterval(double maxY) {
    if (maxY <= 0) return 1;
    final exponent = (log(maxY) / log(10)).floor();
    final powerOfTen = pow(10, exponent).toDouble();
    final remainder = maxY / powerOfTen;

    double interval;
    if (remainder < 2) {
      interval = 0.2 * powerOfTen;
    } else if (remainder < 5) {
      interval = 0.5 * powerOfTen;
    } else {
      interval = 1.0 * powerOfTen;
    }

    if (maxY / interval < 4) interval /= 2;
    return interval <= 0 ? 1 : interval;
  }

  static String _formatK(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  static String _fmt(double v) =>
      v >= 1000 ? _formatK(v) : v.toStringAsFixed(v % 1 == 0 ? 0 : 2);
}

class _Range {
  final DateTime start;
  final int days;
  const _Range(this.start, this.days);
}
