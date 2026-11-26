import 'package:flutter/material.dart';

class TextStyles {
  static Text primaryTextStyle(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
    );
  }

  static Text primaryTextStyles(text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
    );
  }

  static Text tertiaryTextStyle(text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
    );
  }
}
