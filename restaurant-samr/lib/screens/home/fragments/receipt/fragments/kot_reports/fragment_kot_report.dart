// fragment_kot_reports.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:splash_screen_03/model/entity_kot.dart';
import 'package:splash_screen_03/screens/home/fragments/receipt/fragments/kot_reports/controller_kot_repoert.dart';

class FragmentKotReports extends StatefulWidget {
  const FragmentKotReports({super.key});

  @override
  State<FragmentKotReports> createState() => _FragmentKotReportsState();
}

class _FragmentKotReportsState extends State<FragmentKotReports> {
  late final ControllerKotReports ctrl;
  final TextEditingController _searchCtrl = TextEditingController();

  // Match Sales UI date formats
  final DateFormat _dfRow = DateFormat('dd/MM/yyyy HH:mm');
  final DateFormat _dfLabel = DateFormat('dd/MM/yyyy');

  // Scroll controllers
  final ScrollController _hScroll = ScrollController();
  final ScrollController _vScroll = ScrollController();
  final ScrollController _controlsScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    try {
      ctrl = Get.find<ControllerKotReports>();
    } catch (_) {
      ctrl = Get.put(ControllerKotReports(), permanent: true);
    }
    _searchCtrl.text = ctrl.searchText.value;
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    // Keep controller reactive state in sync with the input text
    ctrl.searchText.value = _searchCtrl.text;
    try {
      (ctrl as dynamic)._applyCombinedFilters();
    } catch (_) {
      ctrl.applySearch(_searchCtrl.text);
    }
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _hScroll.dispose();
    _vScroll.dispose();
    _controlsScroll.dispose();
    super.dispose();
  }

  // THEME (same palette as Sales)
  _AppColors _getThemeColors(ThemeData theme) {
    final bool isDark = theme.brightness == Brightness.dark;
    return isDark
        ? _AppColors(
            scaffold: const Color(0xff0D1117),
            surface: const Color(0xff161B22),
            headerFooter: const Color(0xff21262D),
            controlFill: const Color(0xff21262D),
            divider: const Color(0xff30363D),
            textPrimary: Colors.white.withOpacity(0.9),
            textSecondary: Colors.white.withOpacity(0.7),
          )
        : _AppColors(
            scaffold: const Color(0xffF5F8FA),
            surface: Colors.white,
            headerFooter: const Color(0xffF6F8FA),
            controlFill: const Color(0xffF6F8FA),
            divider: const Color(0xffD0D7DE),
            textPrimary: const Color(0xff24292F),
            textSecondary: const Color(0xff57606A),
          );
  }

  // ---------------- WIDGETS ----------------

  static const double _controlHeight = 44.0;

  Widget _buildControlsRow(ThemeData theme, _AppColors colors) {
    return SingleChildScrollView(
      controller: _controlsScroll,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildSearchBar(theme, colors),
          const SizedBox(width: 12.0),
          _buildDateFilterButton(theme, colors),
          const SizedBox(width: 12.0),
          _buildClearFilterButton(colors),
          const SizedBox(width: 16.0),
          _buildExportButton(theme),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, _AppColors colors) {
    return SizedBox(
      height: _controlHeight,
      width: 300,
      child: TextField(
        controller: _searchCtrl,
        style: TextStyle(color: colors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search KOT, bill, table...',
          hintStyle: TextStyle(color: colors.textSecondary, fontSize: 14),
          prefixIcon: Icon(Icons.search, size: 20, color: colors.textSecondary),
          filled: true,
          fillColor: colors.controlFill,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.colorScheme.primary),
          ),
          suffixIcon: Obx(() {
            return ctrl.searchText.value.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, size: 18, color: colors.textSecondary),
                    onPressed: () => _searchCtrl.clear(),
                  )
                : const SizedBox.shrink();
          }),
        ),
      ),
    );
  }Widget _buildDateFilterButton(ThemeData theme, _AppColors colors) {
  final key = GlobalKey();
  return SizedBox(
    height: _controlHeight,
    child: Obx(() {
      final dr = ctrl.selectedDateRange.value;
      final label = dr == null
          ? 'All Dates'
          : '${DateFormat('dd MMM').format(dr.start)} - ${DateFormat('dd MMM').format(dr.end)}';
      return InkWell(
        key: key,
        onTap: () => _showDateFilterMenu(key, theme, colors),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colors.controlFill,
            border: Border.all(color: colors.divider),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 18),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: colors.textPrimary)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, size: 18),
            ],
          ),
        ),
      );
    }),
  );
}

void _showDateFilterMenu(GlobalKey key, ThemeData theme, _AppColors colors) {
  final ctx = key.currentContext;
  if (ctx == null) return;
  final overlay = Overlay.of(ctx);
  final box = ctx.findRenderObject() as RenderBox?;
  if (box == null) return;
  final pos = box.localToGlobal(Offset.zero);
  final size = box.size;

  late OverlayEntry entry;
  entry = OverlayEntry(builder: (context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => entry.remove(),
            behavior: HitTestBehavior.translucent,
          ),
        ),
        Positioned(
          left: pos.dx,
          top: pos.dy + size.height + 4,
          child: Material(
            color: colors.surface,
            elevation: 6,
            borderRadius: BorderRadius.circular(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _dateOption('Today', () {
                  ctrl.presetToday();
                  entry.remove();
                }),
                _dateOption('Yesterday', () {
                  ctrl.presetYesterday();
                  entry.remove();
                }),
                _dateOption('Last 7 Days', () {
                  ctrl.presetLast7Days();
                  entry.remove();
                }),
                _dateOption('Last 30 Days', () {
                  ctrl.presetLast30Days();
                  entry.remove();
                }),
                _dateOption('This Month', () {
                  ctrl.presetThisMonth();
                  entry.remove();
                }),
                _dateOption('Last Month', () {
                  ctrl.presetLastMonth();
                  entry.remove();
                }),
                const Divider(height: 1),
                _dateOption('Custom Range', () async {
                  entry.remove();
                  final picked = await showDateRangePicker(
                    context: ctx,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: ctrl.selectedDateRange.value,
                  );
                  if (picked != null) ctrl.setDateRange(picked);
                }),
                _dateOption('All Time', () {
                  ctrl.clearDateFilter();
                  entry.remove();
                }),
              ],
            ),
          ),
        ),
      ],
    );
  });

  overlay.insert(entry);
}

Widget _dateOption(String text, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(text),
    ),
  );
}


  Widget _buildClearFilterButton(_AppColors colors) {
    return SizedBox(
      height: _controlHeight,
      child: TextButton.icon(
        onPressed: () {
          _searchCtrl.clear();
          ctrl.clearFilters();
        },
        icon: Icon(Icons.close, size: 18, color: colors.textSecondary),
        label: Text('Clear filter', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      ),
    );
  }

  Widget _buildExportButton(ThemeData theme) {
    return SizedBox(
      height: _controlHeight,
      child: ElevatedButton.icon(
        onPressed: () async {
          try {
            await ctrl.exportFilteredToExcelToDownloads();
            Get.snackbar('Export', 'Successfully exported to Downloads folder', snackPosition: SnackPosition.BOTTOM);
          } catch (e) {
            Get.snackbar('Export', 'Failed: $e', snackPosition: SnackPosition.BOTTOM);
          }
        },
        icon: const Icon(Icons.file_download, size: 18),
        label: const Text('Export', style: TextStyle(fontSize: 14)),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
    );
  }

  // Details dialog (slightly styled to match)
  void _showKotDetailsDialog(BuildContext context, KotReceipt r) {
    final items = ctrl.getKotItemsByKotNumber(r.kotNumber);
    final theme = Theme.of(context);
    final colors = _getThemeColors(theme);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('KOT Details: ${r.kotNumber} (${r.tableName})'),
        contentPadding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
        insetPadding: const EdgeInsets.all(20),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text('No items recorded for this KOT.', style: TextStyle(color: colors.textSecondary)),
                  ),
                )
              : SingleChildScrollView(
                  child: DataTable(
                    columnSpacing: 20,
                    horizontalMargin: 12,
                    headingRowHeight: 40,
                    headingRowColor: MaterialStateProperty.all(colors.headerFooter),
                    headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: colors.textSecondary, fontSize: 13),
                    dataTextStyle: TextStyle(color: colors.textPrimary, fontSize: 14),
                    border: TableBorder(horizontalInside: BorderSide(color: colors.divider, width: 1.0)),
                    columns: const [
                      DataColumn(label: Text('Item')),
                      DataColumn(label: Text('Qty'), numeric: true),
                      DataColumn(label: Text('Price'), numeric: true),
                      DataColumn(label: Text('Total'), numeric: true),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('User')),
                    ],
                    rows: items.map((it) {
                      final name = it['name'] ?? it['foodName'] ?? 'N/A';
                      final qty = double.tryParse(it['qty']?.toString() ?? '1') ?? 1.0;
                      final price = (it['price'] as num?)?.toDouble() ?? 0.0;
                      final total = (it['amount'] as num?)?.toDouble() ?? (price * qty);
                      final status = it['status'] ?? '-';
                      final username = it['username'] ?? it['user'] ?? '-';

                      return DataRow(cells: [
                        DataCell(Text(name.toString())),
                        DataCell(Align(alignment: Alignment.centerRight, child: Text(qty.toString()))),
                        DataCell(Align(alignment: Alignment.centerRight, child: Text(price.toStringAsFixed(2)))),
                        DataCell(Align(alignment: Alignment.centerRight, child: Text(total.toStringAsFixed(2)))),
                        DataCell(Text(status.toString())),
                        DataCell(Text(username.toString())),
                      ]);
                    }).toList(),
                  ),
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Get.snackbar('Print', 'Printing KOT ${r.kotNumber}', snackPosition: SnackPosition.BOTTOM);
            },
            child: const Text('Print'),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(ThemeData theme, _AppColors colors, BoxConstraints constraints) {
    return Obx(() {
      final list = ctrl.filteredKotReceipts;
      if (list.isEmpty) {
        return SizedBox(height: 300, child: Center(child: Text('No records found...', style: TextStyle(color: colors.textSecondary))));
      }

      return Scrollbar(
        controller: _vScroll,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _vScroll,
          child: Scrollbar(
            controller: _hScroll,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _hScroll,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  showCheckboxColumn: false,
                  border: TableBorder(horizontalInside: BorderSide(color: colors.divider, width: 1.0)),
                  columnSpacing: 12,
                  horizontalMargin: 16,
                  headingRowHeight: 52,
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 56,
                  headingRowColor: MaterialStateProperty.all(colors.headerFooter),
                  headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: colors.textSecondary, fontSize: 13),
                  dataTextStyle: TextStyle(color: colors.textPrimary, fontSize: 14),
                  columns: const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('KOT NO')),
                    DataColumn(label: Text('TABLE')),
                    DataColumn(label: Text('QTY'), numeric: true),
                    DataColumn(label: Text('AVG. PRICE'), numeric: true),
                    DataColumn(label: Text('TOTAL'), numeric: true),
                    DataColumn(label: Text('CREATED ON')),
                  ],
                  rows: List.generate(list.length, (i) {
                    final r = list[i];
                    return DataRow(
                      onSelectChanged: (_) => _showKotDetailsDialog(context, r),
                      cells: [
                        DataCell(Text((i + 1).toString())),
                        DataCell(Text(r.kotNumber.toString())),
                        DataCell(Text(r.tableName)),
                        DataCell(Align(alignment: Alignment.centerRight, child: Text(r.totalQty.toString()))),
                        DataCell(Align(alignment: Alignment.centerRight, child: Text(r.avgPrice.toStringAsFixed(2)))),
                        DataCell(Align(alignment: Alignment.centerRight, child: Text(r.totalAmount.toStringAsFixed(2)))),
                        
                        DataCell(Text(_dfRow.format(r.createdOn))),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildFooter(ThemeData theme, _AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: colors.headerFooter,
      child: Obx(() {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total KOTs: ${ctrl.totalCount.value}', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
            if (ctrl.totalPages > 1)
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, size: 20, color: colors.textSecondary),
                    onPressed: ctrl.currentPage.value > 1 ? () => ctrl.prevPage() : null,
                    splashRadius: 20,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(6)),
                    child: Text('${ctrl.currentPage.value}', style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('of ${ctrl.totalPages}', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right, size: 20, color: colors.textSecondary),
                    onPressed: ctrl.currentPage.value < ctrl.totalPages ? () => ctrl.nextPage() : null,
                    splashRadius: 20,
                  ),
                ],
              ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _getThemeColors(theme);

    return Scaffold(
      backgroundColor: colors.scaffold,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildControlsRow(theme, colors),
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(12.0)),
                child: Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return _buildTable(theme, colors, constraints);
                        },
                      ),
                    ),
                    _buildFooter(theme, colors),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppColors {
  final Color scaffold, surface, headerFooter, controlFill, divider, textPrimary, textSecondary;
  _AppColors({
    required this.scaffold,
    required this.surface,
    required this.headerFooter,
    required this.controlFill,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
  });
}