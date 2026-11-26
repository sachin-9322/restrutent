import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart';

class PrinterManager {
  static Future<Printer?> pickPrinter({required dynamic context}) async {
    try {
      Printer? selectedPrinter = await PrinterManager.pickPrinter(context: context);
      if (selectedPrinter != null) {
        debugPrint('Printer saved: ${selectedPrinter.name}');
        return selectedPrinter;
      } else {
        debugPrint('No printer selected');
        return null;
      }
    } catch (e) {
      debugPrint('Error picking printer: $e');
      return null;
    }
  }
}