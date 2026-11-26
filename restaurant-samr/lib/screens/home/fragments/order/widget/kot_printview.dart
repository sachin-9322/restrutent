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

class ActivityKotPreviewPagee extends StatelessWidget {
  final EntityOrderFood kot;
  final EntityOrder bill;
  final Map<String, List<MapEntry<EntityFood, int>>> groupedItems;

  const ActivityKotPreviewPagee({
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

    const double KOT_WIDTH = 49 * PdfPageFormat.mm;
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

class KotPreviewwDialog extends StatefulWidget {
  final EntityOrderFood kot;
  final EntityOrder bill;
  final Map<String, List<MapEntry<dynamic, int>>> groupedItems;

  const KotPreviewwDialog({
    super.key,
    required this.kot,
    required this.bill,
    required this.groupedItems,
  });

  @override
  State<KotPreviewwDialog> createState() => _KotPreviewwDialogState();
}

class _KotPreviewwDialogState extends State<KotPreviewwDialog> {
  // KOT page width in mm (same as PDF generator)
  static const double KOT_WIDTH_MM = 50.0;
  static final PdfPageFormat kotPageFormat = PdfPageFormat(
    KOT_WIDTH_MM * PdfPageFormat.mm,
    PdfPageFormat.a4.height,
  );

  Uint8List? _cachedPdfBytes;
  Uint8List? _cachedRasterImage; // PNG/JPEG of first PDF page
  bool _isGenerating = false;
  bool _rasterFailed = false;

  Future<Uint8List> _generateKotPdfBytes() async {
    if (_cachedPdfBytes != null) return _cachedPdfBytes!;
    setState(() => _isGenerating = true);

    final kotCreationDate = DateTime.parse(widget.kot.createdOn!);
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
    widget.groupedItems.forEach((_, items) {
      for (var e in items) calculatedTotalQuantity += e.value;
    });

    const double leftMargin = 1.5 * PdfPageFormat.mm;
    const double topMargin = 1.5 * PdfPageFormat.mm;
    const double rightMargin = 3.0 * PdfPageFormat.mm;
    const double bottomMargin = 1.5 * PdfPageFormat.mm;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          KOT_WIDTH_MM * PdfPageFormat.mm,
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
                  'KOT No: ${widget.kot.kotNumber}',
                  style: pw.TextStyle(font: fontBold, fontSize: 10),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Table: ${widget.bill.tableName}',
                  style: pw.TextStyle(font: fontBold, fontSize: 9),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  widget.bill.orderTypeId ?? 'Dine-In',
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
                  widget.bill.userName ?? '',
                  style: pw.TextStyle(font: fontRegular, fontSize: 8),
                ),
              ),
              pw.SizedBox(height: 1.5 * PdfPageFormat.mm),
              pw.Divider(height: 0.5 * PdfPageFormat.mm),
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
              pw.Divider(height: 0.5 * PdfPageFormat.mm),
              pw.SizedBox(height: 1 * PdfPageFormat.mm),
              ...widget.groupedItems.entries.expand((ce) => ce.value).map((
                entry,
              ) {
                final qtyText = entry.value.toString();

                // tolerant item name
                String rawName;
                try {
                  if (entry.key is Map) {
                    rawName =
                        (entry.key as Map)['foodName']?.toString() ?? 'N/A';
                  } else {
                    rawName =
                        (entry.key as dynamic).foodName?.toString() ?? 'N/A';
                  }
                } catch (_) {
                  rawName = entry.key.toString();
                }

                return pw.Padding(
                  padding: pw.EdgeInsets.symmetric(
                    vertical: 0.5 * PdfPageFormat.mm,
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          rawName,
                          style: pw.TextStyle(font: fontRegular, fontSize: 10),
                        ),
                      ),
                      pw.SizedBox(width: 1 * PdfPageFormat.mm),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          qtyText,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(font: fontBold, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              pw.SizedBox(height: 1.5 * PdfPageFormat.mm),
              pw.Divider(height: 0.5 * PdfPageFormat.mm),
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

    _cachedPdfBytes = await pdf.save();
    setState(() => _isGenerating = false);
    return _cachedPdfBytes!;
  }

  // Rasterize the first page into an image (PNG). This removes PdfPreview chrome.
  Future<Uint8List?> _rasterizeFirstPage(Uint8List pdfBytes) async {
    if (_cachedRasterImage != null) return _cachedRasterImage;
    try {
      // Use double for dpi to match function signature
      const double dpi = 150.0;

      // Printing.raster returns a Stream in many versions.
      final Stream<dynamic> rasterStream = Printing.raster(pdfBytes, dpi: dpi);
      final List<dynamic> pages = await rasterStream.toList();

      if (pages.isEmpty) {
        _rasterFailed = true;
        return null;
      }

      final dynamic first = pages.first;

      // 1) If stream yields Uint8List directly:
      if (first is Uint8List) {
        _cachedRasterImage = first;
        return _cachedRasterImage;
      }

      // 2) If PdfRaster-like object exposes 'bytes' getter (some versions)
      try {
        // use dynamic access but guard with try/catch
        final possibleBytes = (first as dynamic).bytes;
        if (possibleBytes is Uint8List) {
          _cachedRasterImage = possibleBytes;
          return _cachedRasterImage;
        }
      } catch (_) {
        // ignore and try next
      }

      // 3) If object exposes a toPng() / toImageBytes() method that returns Uint8List/Future<Uint8List>
      try {
        final dynamic dyn = first as dynamic;
        if (dyn.toPng is Function) {
          final result = await dyn.toPng();
          if (result is Uint8List) {
            _cachedRasterImage = result;
            return _cachedRasterImage;
          }
        } else if (dyn.toImage is Function) {
          // maybe returns ui.Image or Uint8List
          final result = await dyn.toImage();
          if (result is Uint8List) {
            _cachedRasterImage = result;
            return _cachedRasterImage;
          }
          if (result is ui.Image) {
            final byteData = await result.toByteData(
              format: ui.ImageByteFormat.png,
            );
            if (byteData != null) {
              _cachedRasterImage = byteData.buffer.asUint8List();
              return _cachedRasterImage;
            }
          }
        }
      } catch (_) {
        // ignore and try next
      }

      // 4) If object has an 'image' property (ui.Image), convert it
      try {
        final dynamic dyn = first as dynamic;
        final ui.Image? image = dyn.image as ui.Image?;
        if (image != null) {
          final ui.ByteData? bd = await image.toByteData(
            format: ui.ImageByteFormat.png,
          );
          if (bd != null) {
            _cachedRasterImage = bd.buffer.asUint8List();
            return _cachedRasterImage;
          }
        }
      } catch (_) {
        // ignore
      }

      // If nothing worked, mark raster as failed so caller can fallback to PdfPreview
      _rasterFailed = true;
      return null;
    } catch (e, st) {
      debugPrint('Rasterization failed (exception): $e\n$st');
      _rasterFailed = true;
      return null;
    }
  }

  Future<void> _prepareAll() async {
    if (_cachedPdfBytes != null &&
        (_cachedRasterImage != null || _rasterFailed))
      return;
    final bytes = await _generateKotPdfBytes();
    // Try rasterizing but don't fail if it errors — we'll fallback
    await _rasterizeFirstPage(bytes);
  }

  Future<void> _printPdf() async {
    try {
      final bytes = await _generateKotPdfBytes();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: 'kot.pdf',
      );
    } catch (e) {
      debugPrint('Print failed: $e');
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to print: $e')));
    }
  }

  Future<void> _openOrSharePdf() async {
    try {
      final bytes = await _generateKotPdfBytes();
      await Printing.sharePdf(bytes: bytes, filename: 'kot.pdf');
    } catch (e) {
      debugPrint('Share failed: $e');
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to open/share: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    // Start preparing PDF + raster asap
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareAll());
  }

  @override
  Widget build(BuildContext context) {
    final double dialogWidth = MediaQuery.of(context).size.width * 0.6;
    final double dialogHeight = MediaQuery.of(context).size.height * 0.85;

    // Visual width for the receipt image inside dialog. Tweak to match screenshot.
    final double receiptVisualWidth =
        dialogWidth * 0.6; // tweak this to scale larger/smaller

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            // header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "KOT Preview",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Center(
                  child: _isGenerating && _cachedRasterImage == null
                      ? const CircularProgressIndicator()
                      : _cachedRasterImage != null
                      ? SingleChildScrollView(
                          // Center the receipt image and allow vertical scroll if small screen
                          child: Column(
                            children: [
                              // white card that mimics the printed receipt
                              Container(
                                width: receiptVisualWidth,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 6,
                                      offset: const Offset(2, 2),
                                    ),
                                  ],
                                  border: Border.all(color: Colors.black12),
                                ),
                                child: Image.memory(
                                  _cachedRasterImage!,
                                  fit: BoxFit
                                      .fitWidth, // fills width and preserves aspect ratio
                                  // You can also set height if you want a fixed visual height:
                                  // height: receiptVisualHeight,
                                ),
                              ),

                              const SizedBox(height: 12),
                              // optional small note / scale indicator
                              Text(
                                'Receipt (print width ${KOT_WIDTH_MM.toStringAsFixed(0)}mm)',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        )
                      : // Raster failed — show PdfPreview fallback (works but has viewer chrome)
                        PdfPreview(
                          build: (format) => _generateKotPdfBytes(),
                          pageFormats: {'KOT': kotPageFormat},
                          canChangePageFormat: false,
                          canChangeOrientation: false,
                          allowPrinting: false,
                          allowSharing: false,
                          maxPageWidth: receiptVisualWidth,
                        ),
                ),
              ),
            ),

            // bottom action bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).dialogBackgroundColor,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _printPdf,
                    icon: const Icon(Icons.print),
                    label: Text(_isGenerating ? 'Preparing...' : 'Print'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _isGenerating ? null : _openOrSharePdf,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open / Download'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}