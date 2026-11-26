// ignore_for_file: constant_identifier_names, unnecessary_to_list_in_spreads, curly_braces_in_flow_control_structures, deprecated_member_use

import 'dart:typed_data';
import 'dart:typed_data' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:splash_screen_03/model/entity_bill.dart';
import 'package:splash_screen_03/model/entity_bill_food.dart';
import 'package:splash_screen_03/model/entity_food.dart';
import 'package:splash_screen_03/model/entity_kot.dart';
import 'dart:ui' as ui show Image, ImageByteFormat;

import 'package:splash_screen_03/screens/home/fragments/order/controller_order.dart';

class ActivityKotPreviewPage extends StatelessWidget {
  final EntityOrderFood kot;
  final EntityOrder bill;
  final Map<String, List<MapEntry<EntityFood, int>>> groupedItems;

  const ActivityKotPreviewPage({
    super.key,
    required this.kot,
    required this.bill,
    required this.groupedItems,
  });

  Future<Uint8List> _generateKotPdf(PdfPageFormat format) async {
    final kotCreationDate = DateTime.parse(kot.createdOn!);
    final formattedDate = DateFormat(
      'dd MMMM yyyy',
    ).format(kotCreationDate.toLocal());
    final formattedTime = DateFormat(
      'hh:mm a',
    ).format(kotCreationDate.toLocal());
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final fontRegular = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    int calculatedTotalQuantity = 0;
    groupedItems.forEach((category, items) {
      for (var entry in items) {
        calculatedTotalQuantity += (entry.value);
      }
    });

    const double KOT_WIDTH = 50 * PdfPageFormat.mm;
    const double leftMargin = 1.5 * PdfPageFormat.mm;
    const double topMargin = 1.5 * PdfPageFormat.mm;
    const double rightMargin = 3.0 * PdfPageFormat.mm;
    const double bottomMargin = 1.5 * PdfPageFormat.mm;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          KOT_WIDTH,
          double.infinity,
          marginLeft: leftMargin,
          marginTop: topMargin,
          marginRight: rightMargin,
          marginBottom: bottomMargin,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'KOT',
                  style: pw.TextStyle(font: fontBold, fontSize: 16),
                ),
              ),
              pw.SizedBox(height: 2 * PdfPageFormat.mm),
              pw.Center(
                child: pw.Text(
                  'KOT No: ${kot.kotNumber}',
                  style: pw.TextStyle(font: fontBold, fontSize: 10),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Table: ${bill.tableName}',
                  style: pw.TextStyle(font: fontBold, fontSize: 9),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  bill.orderTypeId ?? 'Dine-In',
                  style: pw.TextStyle(font: fontRegular, fontSize: 9),
                ),
              ),
              pw.SizedBox(height: 1 * PdfPageFormat.mm),
              pw.Center(
                child: pw.Text(
                  formattedDate,
                  style: pw.TextStyle(font: fontRegular, fontSize: 7),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  formattedTime,
                  style: pw.TextStyle(font: fontRegular, fontSize: 7),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  bill.userName ?? '',
                  style: pw.TextStyle(font: fontRegular, fontSize: 8),
                ),
              ),
              pw.SizedBox(height: 1.5 * PdfPageFormat.mm),
              pw.Divider(
                height: 0.5 * PdfPageFormat.mm,
                borderStyle: pw.BorderStyle.solid,
              ),
              pw.SizedBox(height: 1.5 * PdfPageFormat.mm),
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      'Item',
                      style: pw.TextStyle(font: fontBold, fontSize: 7.5),
                    ),
                  ),
                  pw.SizedBox(width: 1 * PdfPageFormat.mm),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      'Qty',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: fontBold, fontSize: 7.5),
                    ),
                  ),
                ],
              ),
              pw.Divider(
                height: 0.5 * PdfPageFormat.mm,
                borderStyle: pw.BorderStyle.solid,
              ),
              pw.SizedBox(height: 1 * PdfPageFormat.mm),
              ...groupedItems.entries.map((categoryEntry) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (categoryEntry.key.isNotEmpty &&
                        categoryEntry.key != "OTHERS")
                      /*pw.Padding(                                                  //Here we are showing categories which can be optional
                        padding: pw.EdgeInsets.only(
                          top: 1.5 * PdfPageFormat.mm,
                          bottom: 0.5 * PdfPageFormat.mm,
                        ),
                        child: pw.Text(
                          '${categoryEntry.key}:',
                          style: pw.TextStyle(font: fontBold, fontSize: 7.5),
                        ),
                      ),*/
                      ...categoryEntry.value.map((itemEntry) {
                        final String quantityText = (itemEntry.value)
                            .toString();

                        return pw.Padding(
                          padding: pw.EdgeInsets.symmetric(
                            vertical: 0.5 * PdfPageFormat.mm,
                          ),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Expanded(
                                flex: 3,
                                child: pw.Text(
                                  itemEntry.key.foodName ?? 'N/A',
                                  style: pw.TextStyle(
                                    font: fontRegular,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              pw.SizedBox(width: 1 * PdfPageFormat.mm),
                              pw.Expanded(
                                flex: 1,
                                child: pw.Text(
                                  quantityText,
                                  textAlign: pw.TextAlign.center,
                                  style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              // Removed the extra pw.Divider() from here as it was likely misplaced
                            ],
                          ),
                        );
                      }),
                  ],
                );
              }).toList(), // Added toList() here as map needs to be resolved to a list of widgets
              pw.SizedBox(height: 1.5 * PdfPageFormat.mm),
              pw.Divider(
                height: 0.5 * PdfPageFormat.mm,
                borderStyle: pw.BorderStyle.solid,
              ),
              pw.SizedBox(height: 1.5 * PdfPageFormat.mm),
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      'Total Qty:',
                      style: pw.TextStyle(font: fontBold, fontSize: 9),
                    ),
                  ),
                  pw.SizedBox(width: 1 * PdfPageFormat.mm),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      calculatedTotalQuantity.toString(),
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: fontBold, fontSize: 9),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 3 * PdfPageFormat.mm),
              pw.Center(
                child: pw.Text(
                  'Thank You!',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 7,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    // Controls how "zoomed-out" the preview appears initially.
    // 0.55 produced the same look as your screenshot. Try 0.5 - 0.7 if needed.
    final double scaleFactor = 0.55;
    final double desiredMaxPageWidth = screenWidth * scaleFactor;

    return Scaffold(
      appBar: AppBar(title: const Text("KOT Preview")),
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Container(
          width:
              desiredMaxPageWidth + 40, // card width slightly larger than PDF
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: PdfPreview(
            allowPrinting: true,
            allowSharing: true,

            // core rendering
            enableScrollToPage: true,
            build: (format) => _generateKotPdf(format),
            canChangeOrientation: false,
            canChangePageFormat: false,
            pageFormats: {'KOT': PdfPageFormat.roll57},

            maxPageWidth: desiredMaxPageWidth,

            // filename
            pdfFileName: "kot.pdf",
          ),
        ),
      ),
    );
  }
}


class KotPreviewDialog extends StatefulWidget {
  // --- THIS IS THE FIX (Part 1) ---
  // Change the type from EntityOrderFood to KotGroup
  final KotGroup kot;
  // --- END FIX ---
  final EntityOrder bill;
  final Map<String, List<MapEntry<dynamic, int>>> groupedItems;

  const KotPreviewDialog({
    super.key,
    required this.kot, // Now correctly expects a KotGroup
    required this.bill,
    required this.groupedItems,
  });

  @override
  State<KotPreviewDialog> createState() => _KotPreviewDialogState();
}

class _KotPreviewDialogState extends State<KotPreviewDialog> {
  late int _calculatedTotalQuantity;
  late String _formattedDate;
  late String _formattedTime;

  @override
  void initState() {
    super.initState();
    _calculateData();
  }

  void _calculateData() {
    _calculatedTotalQuantity = 0;
    widget.groupedItems.forEach((_, items) {
      for (var e in items) {
        _calculatedTotalQuantity += e.value;
      }
    });

    final creationDate = DateTime.tryParse(widget.kot.createdOn ?? '') ?? DateTime.now();
    _formattedDate = DateFormat('dd MMMM yyyy').format(creationDate.toLocal());
    _formattedTime = DateFormat('hh:mm a').format(creationDate.toLocal());
  }

  Widget _buildKotContent() {
    const TextStyle boldStyle = TextStyle(fontWeight: FontWeight.bold, color: Colors.black);
    const TextStyle regularStyle = TextStyle(color: Colors.black);
    final allItems = widget.groupedItems.entries.expand((ce) => ce.value).toList();

    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Text('KOT PREVIEW', style: boldStyle.copyWith(fontSize: 24))),
          const SizedBox(height: 8),

          // --- THIS IS THE FIX (Part 2) ---
          // Use the kotNumber from the KotGroup object.
          // Add a check to show "PREVIEW" for new, unsaved KOTs.
          Center(
            child: Text(
              'KOT No: ${widget.kot.kotNumber > 0 ? widget.kot.kotNumber : "NEW"}',
              style: boldStyle.copyWith(fontSize: 16),
            ),
          ),
          // --- END FIX ---

          Center(child: Text('Table: ${widget.bill.tableName ?? 'N/A'}', style: boldStyle.copyWith(fontSize: 14))),
          Center(child: Text(widget.bill.orderTypeId ?? 'Dine-In', style: regularStyle.copyWith(fontSize: 14))),
          const SizedBox(height: 4),
          Center(child: Text(_formattedDate, style: regularStyle.copyWith(fontSize: 12))),
          Center(child: Text(_formattedTime, style: regularStyle.copyWith(fontSize: 12))),
          const SizedBox(height: 8),
          const Divider(color: Colors.black, thickness: 1),

          // Item List Header and Rows... (rest of the code is fine)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('Item', style: boldStyle.copyWith(fontSize: 14))),
                Expanded(flex: 1, child: Text('Qty', textAlign: TextAlign.right, style: boldStyle.copyWith(fontSize: 14))),
              ],
            ),
          ),
          const Divider(color: Colors.black, thickness: 1),

          ...allItems.map((entry) {
            String itemName = (entry.key is EntityFood)
                ? (entry.key.foodName ?? 'N/A')
                : (entry.key is ExtraItem ? entry.key.name : 'N/A');
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(itemName, style: regularStyle.copyWith(fontSize: 14))),
                  Expanded(flex: 1, child: Text(entry.value.toString(), textAlign: TextAlign.right, style: boldStyle.copyWith(fontSize: 14))),
                ],
              ),
            );
          }),
          const Divider(color: Colors.black, thickness: 1),

          // Total Quantity
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('Total Qty:', style: boldStyle.copyWith(fontSize: 16))),
                Expanded(flex: 1, child: Text(_calculatedTotalQuantity.toString(), textAlign: TextAlign.right, style: boldStyle.copyWith(fontSize: 16))),
              ],
            ),
          ),
          const Divider(color: Colors.black, thickness: 1),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(child: _buildKotContent()),
    );
  }
}