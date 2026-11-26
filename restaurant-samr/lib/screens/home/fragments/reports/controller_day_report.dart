// OpenDayReportController.dart
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:splash_screen_03/model/day_report_model.dart';
import 'package:splash_screen_03/screens/home/fragments/day/day_report.dart';
import 'package:splash_screen_03/screens/home/fragments/day/shift%20reports/close_day.dart';
extension ToRow on OpenDayRow {
  List<CellValue?> toExcelRow() => [
        TextCellValue(startDate),
        TextCellValue(endDate),
        TextCellValue(startedBy),
        TextCellValue(closedBy),
        TextCellValue(invoiceRange),
        TextCellValue(openingBal.toStringAsFixed(2)),
        TextCellValue(totalSales.toStringAsFixed(2)),
        TextCellValue(expenses.toStringAsFixed(2)),
        TextCellValue(closingBal.toStringAsFixed(2)),
      ];
}

class OpenDayReportController extends GetxController {
  final shiftCtrl = Get.put(ShiftController());
  final closeCtrl = Get.put(CloseShiftController());

  final rows = <OpenDayRow>[].obs;
  final filteredRows = <OpenDayRow>[].obs;

  final searchText = ''.obs;
  final selectedFilter = 'All Dates'.obs;

  DateTime? filterStart;
  DateTime? filterEnd;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> exportReport() async {
  if (filteredRows.isEmpty) {
    Get.snackbar("Export", "No data available to export");
    return;
  }

  try {
    String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Report As',
      fileName: "day_report_${DateTime.now().millisecondsSinceEpoch}.xlsx",
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (outputPath == null) return;

    final excel = Excel.createExcel();

    // Remove default empty sheet
    excel.delete('Sheet1');

    // Create correct sheet
    final Sheet sheet = excel['Report'];

    // HEADER
    sheet.appendRow([
      TextCellValue("Start Date"),
      TextCellValue("End Date"),
      TextCellValue("Started By"),
      TextCellValue("Closed By"),
      TextCellValue("Invoice Range"),
      TextCellValue("Opening Bal"),
      TextCellValue("Total Sales"),
      TextCellValue("Expenses"),
      TextCellValue("Closing Bal"),
    ]);

    // DATA ROWS
    for (var r in filteredRows) {
      sheet.appendRow(r.toExcelRow());
    }

    // SAVE FILE
    final bytes = excel.encode();
    if (bytes == null) {
      Get.snackbar("Export Failed", "Could not encode Excel");
      return;
    }

    final file = File(outputPath);
    await file.writeAsBytes(bytes);

    Get.snackbar(
      "Export Successful",
      "Saved to:\n$outputPath",
      snackPosition: SnackPosition.BOTTOM,
    );

  } catch (e) {
    Get.snackbar("Export Failed", e.toString(),
        snackPosition: SnackPosition.BOTTOM);
  }
}



  // LOAD DATA
  void loadData() {
    rows.clear();

    final repo = shiftCtrl.repo;
    final allReports = repo.allDesc();

    final df = DateFormat('dd/MM/yyyy hh:mm a');

    rows.assignAll(
      allReports.map((r) {
        return OpenDayRow(
          startDate: df.format(r.openedAt),
          endDate: r.closedAt != null ? df.format(r.closedAt!) : "-",
          startedBy: r.username,
          closedBy: r.closedAt != null ? r.username : "-",
          openingBal: r.openingCash,
          closingBal: r.closingCash ?? 0,
          invoiceRange: "${r.invoiceStart} - ${r.invoiceEnd}",
          expenses: r.totalExpenses ?? 0,
          totalSales: r.totalSales ?? 0,
          openedAtRaw: r.openedAt,
        );
      }).toList(),
    );

    applyFilters();
  }

  // SEARCH + DATE FILTER
  void applyFilters() {
    List<OpenDayRow> data = rows.toList();

    // 🔍 SEARCH
    if (searchText.value.isNotEmpty) {
      final q = searchText.value.toLowerCase();
      data = data.where((row) {
        return row.startedBy.toLowerCase().contains(q) ||
            row.closedBy.toLowerCase().contains(q);
      }).toList();
    }

    // 📅 DATE RANGE
    if (filterStart != null && filterEnd != null) {
      data = data.where((row) {
        return row.openedAtRaw.isAfter(filterStart!) &&
            row.openedAtRaw.isBefore(filterEnd!);
      }).toList();
    }

    filteredRows.assignAll(data);
  }

  // APPLIED FILTER TYPE
  void setDateFilter(String type) {
    selectedFilter.value = type;

    final now = DateTime.now();

    switch (type) {
      case "Today":
        filterStart = DateTime(now.year, now.month, now.day);
        filterEnd = filterStart!.add(const Duration(days: 1));
        break;

      case "Yesterday":
        filterStart =
            DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
        filterEnd = DateTime(now.year, now.month, now.day);
        break;

      case "Last 7 Days":
        filterStart = now.subtract(const Duration(days: 7));
        filterEnd = now;
        break;

      case "This Month":
        filterStart = DateTime(now.year, now.month, 1);
        filterEnd = DateTime(now.year, now.month + 1, 1);
        break;

      case "All Time":
        filterStart = null;
        filterEnd = null;
        break;
    }

    applyFilters();
  }

  // CUSTOM RANGE
  void setCustomRange(DateTime start, DateTime end) {
    filterStart = start;
    filterEnd = end.add(const Duration(days: 1));
    selectedFilter.value = "Custom Range";
    applyFilters();
  }

  // CLEAR
  void clearFilters() {
    searchText.value = "";
    selectedFilter.value = "All Dates";
    filterStart = null;
    filterEnd = null;
    applyFilters();
  }
}
