import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:splash_screen_03/model/entity_bill_food.dart';
import 'package:splash_screen_03/model/enum_printer_size.dart';
import '../../../../../../model/entity_bill.dart';

Future<void> activityKotPrinter({
  required EntityOrderFood kot,
  required EntityOrder bill,
  required Map<String, List<MapEntry<dynamic, int>>> groupedItems,
  required Printer selectedPrinter,
  required EnumPrinterSize assignedWidth,
}) async {
  // Determine printer width
  double kotWidthMm;
  switch (assignedWidth) {
    case EnumPrinterSize.mm58:
      kotWidthMm = 45.0;
      break;
    case EnumPrinterSize.mm80:
      kotWidthMm = 70.0;
      break;
    case EnumPrinterSize.a4:
      kotWidthMm = 200.0;
      break;
  }

  final pdf = pw.Document();
  final fontRegular = pw.Font.helvetica();
  final fontBold = pw.Font.helveticaBold();

  final itemEntries = groupedItems.entries.expand((e) => e.value).toList();
  final int totalQty = itemEntries.fold(0, (sum, e) => sum + e.value);
  final now = DateTime.now();
  final formattedDate = DateFormat('dd/MM/yyyy').format(now);
  final formattedTime = DateFormat('hh:mm a').format(now);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat(
        kotWidthMm * PdfPageFormat.mm,
        double.infinity,
        marginAll: 2 * PdfPageFormat.mm,
      ),
      build: (context) {
        return pw.Center( // Center the entire content
          child: pw.Container(
            width: kotWidthMm * PdfPageFormat.mm, // Limit width for proper alignment
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'KOT',
                  style: pw.TextStyle(font: fontBold, fontSize: 14),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'KOT No: ${kot.kotNumber}',
                  style: pw.TextStyle(font: fontBold, fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 1.5),
                pw.Text(
                  '${bill.tableName ?? "Table"} • ${bill.orderTypeId ?? "Dine-In"}',
                  style: pw.TextStyle(font: fontRegular, fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Date: $formattedDate',
                        style: pw.TextStyle(font: fontRegular, fontSize: 6.5)),
                    pw.Text(formattedTime,
                        style: pw.TextStyle(font: fontRegular, fontSize: 6.5)),
                  ],
                ),
                pw.Text('User: ${bill.userName ?? "-"}',
                    style: pw.TextStyle(font: fontBold, fontSize: 6.5)),
                pw.Divider(thickness: 0.4),
                pw.SizedBox(height: 1),

                // ===== Table Header =====
                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text('Item',
                          style: pw.TextStyle(font: fontBold, fontSize: 7)),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text('Qty',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(font: fontBold, fontSize: 7)),
                    ),
                  ],
                ),
                pw.Divider(thickness: 0.3),

                // ===== Items =====
                ...itemEntries.map((entry) {
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

                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 0.5),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(itemName,
                              style: pw.TextStyle(
                                  font: fontRegular, fontSize: 7)),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(entry.value.toString(),
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                  font: fontBold, fontSize: 7)),
                        ),
                      ],
                    ),
                  );
                }),

                pw.Divider(thickness: 0.4),

                // ===== Total Qty =====
                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 80,
                      child: pw.Text(
                        'Total Qty:',
                        style: pw.TextStyle(font: fontBold, fontSize: 8),
                      ),
                    ),
                    pw.Expanded(
                      flex: 13,
                      child: pw.Text(
                        totalQty.toString(),
                        style: pw.TextStyle(font: fontBold, fontSize: 8),
                      ),
                    ),
                  ],
                ),
                pw.Divider(thickness: 0.4),
              ],
            ),
          ),
        );
      },
    ),
  );

  // ===== Direct print =====
  final pdfBytes = await pdf.save();
  try {
    await Printing.directPrintPdf(
      printer: selectedPrinter,
      onLayout: (format) async => pdfBytes,
      name: 'kot_ticket.pdf',
    );
  } catch (e) {
    debugPrint("Printing failed: $e");
  }
}
