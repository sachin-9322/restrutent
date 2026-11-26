import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_colors.dart';

/// 🔹 Reusable Elevated Button
Widget appButton({
  required String text,
  required VoidCallback onPressed,
  Color bgColor = AppColors.primary,
  Color textColor = AppColors.white,
  double radius = 6,
  EdgeInsetsGeometry? padding,
}) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      elevation: 0,
    ),
    child: Text(
      text,
      style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
    ),
  );
}

/// 🔹 Reusable Container Box
Widget appContainer({
  required Widget child,
  Color bgColor = AppColors.white,
  Color borderColor = AppColors.greyBorder,
  double radius = 6,
  EdgeInsetsGeometry? padding,
  EdgeInsetsGeometry? margin,
}) {
  return Container(
    padding: padding ?? const EdgeInsets.all(8),
    margin: margin,
    decoration: BoxDecoration(
      color: bgColor,
      border: Border.all(color: borderColor),
      borderRadius: BorderRadius.circular(radius),
    ),
    child: child,
  );
}

/// 🔹 Reusable Switch Tile
Widget appSwitch({
  required String label,
  required bool value,
  required ValueChanged<bool> onChanged,
  Color activeColor = AppColors.primary,
}) {
  return SwitchListTile(
    value: value,
    onChanged: onChanged,
    activeColor: activeColor,
    title: Text(label, style: const TextStyle(color: AppColors.white)),
  );
}

/// 🔹 Interval Box (used in KDS settings)
Widget intervalBox(String text) {
  return appContainer(
    bgColor: AppColors.greyDark,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    child: Text(text, style: const TextStyle(color: AppColors.white)),
  );
}

/// 🔹 Dropdown Box
Widget dropdownBox(String hint) {
  return appContainer(
    bgColor: AppColors.greyDark,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    child: Text(hint, style: const TextStyle(color: AppColors.white)),
  );
}
