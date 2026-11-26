
import 'package:get/get.dart';



import 'package:flutter/material.dart';

class SearchBox extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool isDark;

  const SearchBox({
    required this.hintText,
    required this.icon,
    required this.isDark,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    // Keep search box appearance consistent: white fill + subtle shadow (like your image)
    final borderRadius = BorderRadius.circular(30.0);
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.6)
                : Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: TextStyle(color: Colors.black87),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          filled: true,
          fillColor:
              Colors.white,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.black38),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 10.0, right: 6.0),
            child: Icon(icon, color: Colors.black45),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}





// ---------------- Custom Widgets ----------------
class CustomTextField extends StatelessWidget {
  final String hint;
  final IconData? prefixIcon;
  final Function(String)? onChanged;

  const CustomTextField({
    super.key,
    required this.hint,
    this.prefixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
      style: theme.textTheme.bodyLarge,
      onChanged: onChanged,
    );
  }
}

class CustomButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon) : const SizedBox(),
      label: Text(label.tr),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    );
  }
}
