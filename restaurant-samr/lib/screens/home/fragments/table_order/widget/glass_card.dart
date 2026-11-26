import 'dart:ui';
import 'package:flutter/material.dart';

const greenColor = Colors.green;
const redColor = Colors.red;

/// Reusable glassmorphic container (now responsive)
class GlasssCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets? padding;

  const GlasssCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;

    // 📏 Responsive blur and padding
    final blurSigma = width < 600 ? 10.0 : width < 1000 ? 14.0 : 18.0;
    final effectivePadding = padding ??
        EdgeInsets.all(width < 600 ? 10 : width < 1000 ? 14 : 16);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.35),
                isDark
                    ? Colors.white.withOpacity(0.03)
                    : Colors.white.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.08),
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: width < 600 ? 6 : 10,
                spreadRadius: -3,
                offset: const Offset(0, 3),
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.2),
              ),
            ],
          ),
          padding: effectivePadding,
          child: child,
        ),
      ),
    );
  }
}

/// SummaryCard with glassmorphism + responsive typography & layout
class SummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final String orderCount;
  final bool isToday;
  final bool isTrendingUp;
  final String? chipLabel;
  final Widget? trailing;

  const SummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.orderCount,
    this.isToday = false,
    this.isTrendingUp = true,
    this.chipLabel,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final width = MediaQuery.of(context).size.width;

    // 📱 Responsive typography
    final titleSize = width < 600 ? 13.0 : 14.0;
    final amountSize = width < 600 ? 18.0 : 22.0;
    final orderSize = width < 600 ? 12.5 : 14.0;
    final iconSize = width < 600 ? 18.0 : 20.0;
    final chipFontSize = width < 600 ? 11.0 : 12.0;
    final chipPadding = width < 600
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5)
        : const EdgeInsets.symmetric(horizontal: 8, vertical: 2);

    return GlasssCard(
      padding: EdgeInsets.all(width < 600 ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Top Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(width < 600 ? 4.5 : 6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : Colors.black12,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isTrendingUp ? Icons.trending_up : Icons.trending_down,
                      color: isTrendingUp ? greenColor : redColor,
                      size: iconSize,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // 🔸 Range Chip
                  if (chipLabel != null)
                    _buildChip(chipLabel!, chipFontSize, chipPadding)
                  else if (isToday)
                    _buildChip("Today", chipFontSize, chipPadding),

                  // 🔸 Optional trailing widget
                  if (trailing != null) ...[
                    const SizedBox(width: 6),
                    trailing!,
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 💰 Amount
          Text(
            amount,
            style: TextStyle(
              color: textColor,
              fontSize: amountSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),

          const SizedBox(height: 4),

          // 🧾 Order count
          Text(
            orderCount,
            style: TextStyle(
              color: subTextColor,
              fontSize: orderSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, double fontSize, EdgeInsets padding) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: greenColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: greenColor, fontSize: fontSize),
      ),
    );
  }
}
