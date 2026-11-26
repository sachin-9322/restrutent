import 'package:flutter/material.dart';

enum PaymentMethod {
  cash,
  card,
  upi,
  paytm,
  googlePay,
  freecharge,
  other;

  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.paytm:
        return 'Paytm';
      case PaymentMethod.googlePay:
        return 'GooglePay';
      case PaymentMethod.freecharge:
        return 'Freecharge';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  Color get color {
    switch (this) {
      case PaymentMethod.cash:
        return Colors.teal;
      case PaymentMethod.card:
        return Colors.indigo;
      case PaymentMethod.upi:
        return Colors.purple;
      case PaymentMethod.paytm:
        return Colors.blue;
      case PaymentMethod.googlePay:
        return Colors.green;
      case PaymentMethod.freecharge:
        return Colors.orange;
      case PaymentMethod.other:
        return Colors.grey;
    }
  }

  static PaymentMethod? fromLabel(String label) {
    try {
      return PaymentMethod.values.firstWhere(
        (e) => e.label.toLowerCase() == label.trim().toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}
