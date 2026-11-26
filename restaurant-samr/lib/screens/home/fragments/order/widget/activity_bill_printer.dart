import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:splash_screen_03/model/entity_bill_food.dart';
import 'package:splash_screen_03/model/enum_printer_size.dart';
import '../../../../../../model/entity_bill.dart';
import '../../../../../../model/entity_kot.dart';

Future<void> activityBillPrinter({
  required EntityOrderFood kot,
  required EntityOrder bill,
  required Map<String, List<MapEntry<dynamic, int>>> groupedItems,
  required Printer selectedPrinter,
  required EnumPrinterSize assignedWidth,
}) async {
  try {
    final pageFormat = (assignedWidth == EnumPrinterSize.mm58
        ? PdfPageFormat.roll57
        : assignedWidth == EnumPrinterSize.mm80
        ? PdfPageFormat.roll80
        : PdfPageFormat.a4)
        .copyWith(marginLeft: 2 * PdfPageFormat.mm, marginRight: 2 * PdfPageFormat.mm, marginTop: 2 * PdfPageFormat.mm, marginBottom: 2 * PdfPageFormat.mm);

    final pdf = pw.Document();
    final fontRegular = pw.Font.courier();
    final fontBold = pw.Font.courierBold();

    final moneyFmt = NumberFormat('#,##0', 'en_US');

    double priceOf(dynamic food) {
      if (food == null) return 0.0;
      try {
        if (food is Map) {
          return (food['price'] as num?)?.toDouble() ?? 0.0;
        } else {
          final priceField = (food as dynamic).price;
          if (priceField is num) return priceField.toDouble();
          if (priceField is String) return double.tryParse(priceField) ?? 0.0;
        }
      } catch (_) {}
      return 0.0;
    }

    final itemEntries = groupedItems.entries.expand((e) => e.value).toList();
    int totalQty = 0;
    double totalAmount = 0.0;

    for (var items in groupedItems.values) {
      for (var entry in items) {
        final qty = entry.value;
        final price = priceOf(entry.key);
        totalQty += qty;
        totalAmount += price * qty;
      }
    }

    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy').format(now);
    final formattedTime = DateFormat('hh:mm a').format(now);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          pw.TextStyle tsBold(double size) =>
              pw.TextStyle(font: fontBold, fontSize: size);
          pw.TextStyle tsRegular(double size) =>
              pw.TextStyle(font: fontRegular, fontSize: size);

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ===== HEADER =====
              pw.Center(child: pw.Text('SMR canteen - BILL', style: tsBold(14))),
              pw.SizedBox(height: 2),
              pw.Center(
                  child: pw.Text('Bill No: ${bill.orderNumber ?? 0}',
                      style: tsBold(10))),
              pw.Center(child: pw.Text(formattedDate, style: tsRegular(7))),
              pw.Center(child: pw.Text(formattedTime, style: tsRegular(7))),
              pw.Center(
                  child: pw.Text(
                      'Customer: ${bill.userName ?? "-"}', style: tsRegular(8))),
              pw.SizedBox(height: 1.5),
              pw.Divider(thickness: 0.4),
              pw.SizedBox(height: 1.5),

              // ===== TABLE HEADER =====
              pw.Row(
                children: [
                  pw.Expanded(flex: 3, child: pw.Text('Item', style: tsBold(8))),
                  pw.Expanded(
                      flex: 1,
                      child: pw.Text('Qty',
                          textAlign: pw.TextAlign.center, style: tsBold(8))),
                  pw.Expanded(
                      flex: 2,
                      child: pw.Text('Rate',
                          textAlign: pw.TextAlign.right, style: tsBold(8))),
                  pw.Expanded(
                      flex: 2,
                      child: pw.Text('Amount',
                          textAlign: pw.TextAlign.right, style: tsBold(8))),
                ],
              ),
              pw.Divider(thickness: 0.4),

              // ===== ITEMS =====
              ...itemEntries.map((entry) {
                final qty = entry.value;
                final price = priceOf(entry.key);
                final amount = price * qty;
                String itemName;

                try {
                  if (entry.key is Map) {
                    itemName =
                        (entry.key as Map)['foodName']?.toString() ?? 'N/A';
                  } else {
                    itemName =
                        (entry.key as dynamic).foodName?.toString() ?? 'N/A';
                  }
                } catch (_) {
                  itemName = entry.key.toString();
                }

                return pw.Row(
                  children: [
                    pw.Expanded(
                        flex: 3,
                        child: pw.Text(itemName, style: tsRegular(8))),
                    pw.Expanded(
                        flex: 1,
                        child: pw.Text(qty.toString(),
                            textAlign: pw.TextAlign.center,
                            style: tsRegular(8))),
                    pw.Expanded(
                        flex: 2,
                        child: pw.Text(moneyFmt.format(price.round()),
                            textAlign: pw.TextAlign.right,
                            style: tsRegular(8))),
                    pw.Expanded(
                        flex: 2,
                        child: pw.Text(moneyFmt.format(amount.round()),
                            textAlign: pw.TextAlign.right,
                            style: tsRegular(8))),
                  ],
                );
              }),

              pw.Divider(thickness: 0.4),

              // ===== TOTAL =====
              pw.Row(
                children: [
                  pw.Expanded(
                      flex: 3, child: pw.Text('Total', style: tsBold(9))),
                  pw.Expanded(
                      flex: 1,
                      child: pw.Text(totalQty.toString(),
                          textAlign: pw.TextAlign.center, style: tsBold(9))),
                  pw.Expanded(flex: 2, child: pw.Text('')),
                  pw.Expanded(
                      flex: 2,
                      child: pw.Text(moneyFmt.format(totalAmount.round()),
                          textAlign: pw.TextAlign.right, style: tsBold(9))),
                ],
              ),
              pw.Divider(thickness: 0.4),
              pw.SizedBox(height: 2),
              pw.Center(
                child: pw.Text('Thank You!',
                    style: tsRegular(7)
                        .copyWith(fontStyle: pw.FontStyle.italic)),
              ),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    debugPrint(
        " Printing BILL to: ${selectedPrinter.name} (${selectedPrinter.url})");
    debugPrint("PDF size: ${pdfBytes.lengthInBytes} bytes");

    await Printing.directPrintPdf(
      printer: selectedPrinter,
      onLayout: (_) async => pdfBytes,
      name: 'bill_ticket.pdf',
    );
  } catch (e) {
    debugPrint(" Bill printing failed: $e");
  }
}
