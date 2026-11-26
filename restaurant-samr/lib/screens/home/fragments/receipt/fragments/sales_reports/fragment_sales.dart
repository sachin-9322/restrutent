import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:splash_screen_03/screens/home/fragments/receipt/fragments/sales_reports/controller_sales.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/controller_setting.dart';
import 'package:splash_screen_03/screens/home/fragments/table_order/widget/glass_card.dart';

class FragmentSales extends StatefulWidget {
  const FragmentSales({super.key});

  @override
  State<FragmentSales> createState() => _FragmentSalesState();
}

class _FragmentSalesState extends State<FragmentSales> {
  late final ControllerSales ctrl;
  final TextEditingController _searchCtrl = TextEditingController();
  final DateFormat _df = DateFormat('dd/MM/yyyy');
  final GlobalKey _dateButtonKey = GlobalKey();

  final ScrollController _hScroll = ScrollController();
  final ScrollController _vScroll = ScrollController();
  final ScrollController _controlsScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    try {
      ctrl = Get.find<ControllerSales>();
    } catch (_) {
      ctrl = Get.put(ControllerSales(), permanent: true);
    }
    _searchCtrl.text = ctrl.searchText.value;
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    ctrl.searchText.value = _searchCtrl.text;
    try {
      (ctrl as dynamic)._applyCombinedFilters();
    } catch (_) {
      ctrl.applySearch();
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

  // --- Theme Colors ---
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
            scaffold: const Color(0xffE8F0FA),
            surface: Colors.white,
            headerFooter: const Color(0xffF6F8FA),
            controlFill: const Color(0xffF6F8FA),
            divider: const Color(0xffD0D7DE),
            textPrimary: const Color(0xff24292F),
            textSecondary: const Color(0xff57606A),
          );
  }

  // --- Controls Row (Responsive) ---
  Widget _buildControlsRow(ThemeData theme, _AppColors colors, bool isMobile) {
    final double spacing = isMobile ? 8 : 12;
    final double padding = isMobile ? 6 : 10;
    final double controlHeight = isMobile ? 38 : 44;
    final double searchWidth = isMobile ? double.infinity : 250;

    return SingleChildScrollView(
      controller: _controlsScroll,
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.only(bottom: padding),
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: searchWidth,
            child: _buildSearchBar(theme, colors, controlHeight),
          ),
          _buildFilterDropdown<String?>(
            'All Orders',
            ctrl.selectedOrderType,
            ctrl.receipts.map((r) => r.type).toSet().toList(),
            (val) => ctrl.setOrderType(val),
            colors,
            width: isMobile ? 140 : 150,
            height: controlHeight,
          ),
          _buildFilterDropdown<String?>(
            'All Bills',
            ctrl.selectedBillStatus,
            ctrl.receipts.map((r) => r.status).toSet().toList(),
            (val) => ctrl.setBillStatus(val),
            colors,
            width: isMobile ? 140 : 150,
            height: controlHeight,
          ),
          _buildFilterDropdown<String?>(
            'All Waiters',
            ctrl.selectedWaiter,
            ctrl.allWaiters,
            (val) => ctrl.setWaiter(val),
            colors,
            width: isMobile ? 140 : 150,
            height: controlHeight,
          ),
          _buildDateFilterButton(theme, colors, controlHeight),
          _buildClearFilterButton(colors, controlHeight),
          _buildExportButton(theme, controlHeight),
        ],
      ),
    );
  }

  // --- Search Bar ---
  Widget _buildSearchBar(ThemeData theme, _AppColors colors, double height) {
    return SizedBox(
      height: height,
      child: TextField(
        controller: _searchCtrl,
        style: TextStyle(color: colors.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search by Bill, Table, etc...',
          hintStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
          prefixIcon: Icon(Icons.search, size: 18, color: colors.textSecondary),
          filled: true,
          fillColor: colors.controlFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colors.divider),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown<T>(
    String hint,
    Rx<T?> selected,
    List<T> items,
    void Function(T?) onChanged,
    _AppColors colors, {
    double width = 150,
    double height = 44,
  }) {
    items.sort(
      (a, b) => a.toString().toLowerCase().compareTo(b.toString().toLowerCase()),
    );
    return SizedBox(
      height: height,
      width: width,
      child: Obx(
        () => DropdownButtonFormField<T?>(
          value: selected.value,
          onChanged: onChanged,
          style: TextStyle(color: colors.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.controlFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.divider),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          ),
          hint: Text(hint,
              style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          icon: Icon(Icons.arrow_drop_down, color: colors.textSecondary, size: 18),
          dropdownColor: colors.headerFooter,
          items: [
            DropdownMenuItem<T?>(value: null, child: Text(hint)),
            ...items.map(
              (e) => DropdownMenuItem<T?>(value: e, child: Text(e.toString())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilterButton(ThemeData theme, _AppColors colors, double height) {
    return SizedBox(
      height: height,
      child: OutlinedButton.icon(
        key: _dateButtonKey,
        onPressed: () {
          _showDateFilterDropdown(context, theme, colors);
        },
        icon: Icon(Icons.calendar_today, size: 16, color: colors.textSecondary),
        label: Obx(() {
          final dr = ctrl.selectedDateRange.value;
          final label = dr == null
              ? 'All Dates'
              : '${_df.format(dr.start)} - ${_df.format(dr.end)}';
          return Text(label,
              style: TextStyle(
                  color: colors.textPrimary, fontSize: 13),
              overflow: TextOverflow.ellipsis);
        }),
        style: OutlinedButton.styleFrom(
          backgroundColor: colors.controlFill,
          side: BorderSide(color: colors.divider),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  void _showDateFilterDropdown(
      BuildContext context, ThemeData theme, _AppColors colors) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final RenderBox? box =
        _dateButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final Offset pos = box.localToGlobal(Offset.zero);
    final Size size = box.size;

    late OverlayEntry dropdown;
    dropdown = OverlayEntry(builder: (context) {
      return Stack(children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => dropdown.remove(),
            behavior: HitTestBehavior.translucent,
          ),
        ),
        Positioned(
          left: pos.dx,
          top: pos.dy + size.height + 4,
          width: size.width * 1.3,
          child: Material(
            color: colors.headerFooter,
            elevation: 4,
            borderRadius: BorderRadius.circular(6),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _buildDateOption('Today', () {
                ctrl.presetToday();
                dropdown.remove();
              }, colors),
              _buildDateOption('Yesterday', () {
                ctrl.presetYesterday();
                dropdown.remove();
              }, colors),
              _buildDateOption('Last 7 Days', () {
                ctrl.presetLast7Days();
                dropdown.remove();
              }, colors),
              _buildDateOption('This Month', () {
                ctrl.presetThisMonth();
                dropdown.remove();
              }, colors),
              const Divider(height: 1),
              _buildDateOption('Custom Range', () async {
                dropdown.remove();
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: ctrl.selectedDateRange.value,
                  builder: (context, child) =>
                      Theme(data: theme.copyWith(), child: child!),
                );
                if (picked != null) ctrl.setDateRange(picked);
              }, colors),
              _buildDateOption('All Time', () {
                ctrl.setDateRange(null);
                dropdown.remove();
              }, colors),
            ]),
          ),
        ),
      ]);
    });
    overlay.insert(dropdown);
  }

  Widget _buildDateOption(String text, VoidCallback onTap, _AppColors colors) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(text,
              style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _buildClearFilterButton(_AppColors colors, double height) {
    return SizedBox(
      height: height,
      child: TextButton.icon(
        onPressed: () {
          _searchCtrl.clear();
          ctrl.clearFilters();
        },
        icon: Icon(Icons.close, size: 16, color: colors.textSecondary),
        label:
            Text('Clear', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      ),
    );
  }

  Widget _buildExportButton(ThemeData theme, double height) {
    return SizedBox(
      height: height,
      child: ElevatedButton.icon(
        onPressed: () => ctrl.exportFilteredToExcelToDownloads(),
        icon: const Icon(Icons.file_download, size: 16),
        label: const Text('Export', style: TextStyle(fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  // --- Responsive Compact Footer ---
  Widget _buildFooterRow(ThemeData theme, _AppColors colors, bool isMobile) {
    final settings = Get.find<ControllerSetting>();
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(
            theme.brightness == Brightness.dark ? 0.05 : 0.25),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Obx(() {
        final total = ctrl.filteredReceipts.fold<double>(
          0.0,
          (s, r) => s + r.amount,
        );
        final formatter = NumberFormat.currency(
          locale: settings.currLocale,
          symbol: '${settings.currCode} ',
          decimalDigits: 2,
        );
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total: ${formatter.format(total)}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 13 : 14,
                    color: colors.textPrimary)),
            if (ctrl.totalPages > 1)
              Row(children: [
                IconButton(
                  icon:
                      Icon(Icons.chevron_left, size: 20, color: colors.textSecondary),
                  onPressed:
                      ctrl.currentPage.value > 1 ? ctrl.prevPage : null,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${ctrl.currentPage.value}',
                      style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text('of ${ctrl.totalPages}',
                      style: TextStyle(
                          color: colors.textSecondary, fontSize: 12)),
                ),
                IconButton(
                  icon:
                      Icon(Icons.chevron_right, size: 20, color: colors.textSecondary),
                  onPressed:
                      ctrl.currentPage.value < ctrl.totalPages ? ctrl.nextPage : null,
                ),
              ]),
          ],
        );
      }),
    );
  }

  // --- Build Main ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _getThemeColors(theme);

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final bool isMobile = width < 700;

      return Scaffold(
        backgroundColor: colors.scaffold,
        body: Padding(
          padding: EdgeInsets.fromLTRB(isMobile ? 10 : 24, 20, isMobile ? 10 : 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildControlsRow(theme, colors, isMobile),
              Expanded(
                child: GlasssCard(
                  borderRadius: 16,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      Expanded(
                        child: Scrollbar(
                          controller: _vScroll,
                          child: SingleChildScrollView(
                            controller: _vScroll,
                            child: Scrollbar(
                              controller: _hScroll,
                              child: SingleChildScrollView(
                                controller: _hScroll,
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: constraints.maxWidth,
                                  ),
                                  child: Obx(() {
                                    final list = ctrl.filteredReceipts;
                                    if (list.isEmpty) {
                                      return SizedBox(
                                        height: 300,
                                        child: Center(
                                          child: Text('No records found...',
                                              style: TextStyle(
                                                  color: colors.textSecondary)),
                                        ),
                                      );
                                    }
                                    return DataTable(
                                      border: TableBorder(
                                        horizontalInside: BorderSide(
                                          color: colors.divider.withOpacity(0.3),
                                        ),
                                      ),
                                      columnSpacing: isMobile ? 12 : 16,
                                      headingRowHeight: 50,
                                      dataRowMinHeight: 46,
                                      dataRowMaxHeight: 52,
                                      headingRowColor: WidgetStateProperty.all(
                                        Colors.white.withOpacity(
                                            theme.brightness ==
                                                    Brightness.dark
                                                ? 0.05
                                                : 0.4),
                                      ),
                                      headingTextStyle: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: colors.textSecondary,
                                          fontSize: 13),
                                      dataTextStyle: TextStyle(
                                          color: colors.textPrimary,
                                          fontSize: 13.5),
                                      columns: const [
                                        DataColumn(label: Text('#')),
                                        DataColumn(label: Text('BILL NO')),
                                        DataColumn(label: Text('TABLE')),
                                        DataColumn(label: Text('TYPE')),
                                        DataColumn(label: Text('STATUS')),
                                        DataColumn(label: Text('DATE')),
                                        DataColumn(label: Text('CUSTOMER')),
                                        DataColumn(label: Text('WAITER')),
                                        DataColumn(label: Text('PAYMENT')),
                                        DataColumn(label: Text('AMOUNT')),
                                      ],
                                      rows: List.generate(list.length, (i) {
                                        final r = list[i];
                                        return DataRow(cells: [
                                          DataCell(Text(
                                              (i + 1 + ((ctrl.currentPage.value - 1) * ctrl.pageSize.value))
                                                  .toString())),
                                          DataCell(Text(r.billNo.toString())),
                                          DataCell(Text(r.tableName)),
                                          DataCell(_buildStatusPill(theme, r.type)),
                                          DataCell(_buildStatusPill(theme, r.status)),
                                          DataCell(Text(_df.format(r.date))),
                                          DataCell(Text(r.customer)),
                                          DataCell(Text(r.waiter ?? '')),
                                          DataCell(Text(r.payment)),
                                          DataCell(Text(r.amount.toStringAsFixed(2),
                                              textAlign: TextAlign.right)),
                                        ]);
                                      }),
                                    );
                                  }),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      _buildFooterRow(theme, colors, isMobile),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// Build small status/type pill used inside DataTable cells.
Widget _buildStatusPill(ThemeData theme, String text) {
  final bool isDark = theme.brightness == Brightness.dark;
  _PillStyle style;
  switch (text.toLowerCase()) {
    case 'settled':
      style = isDark
          ? _PillStyle(const Color(0xff1A382A), const Color(0xff6AFB92))
          : _PillStyle(const Color(0xffDFF7EA), const Color(0xff185B33));
      break;
    case 'unpaid':
      style = isDark
          ? _PillStyle(const Color(0xff431B22), const Color(0xffF8716F))
          : _PillStyle(const Color(0xffFFEBE9), const Color(0xff9D2422));
      break;
    case 'dine-in':
      style = isDark
          ? _PillStyle(const Color(0xff1E2E44), const Color(0xff79C0FF))
          : _PillStyle(const Color(0xffE5F1FF), const Color(0xff094A89));
      break;
    default:
      style = isDark
          ? _PillStyle(const Color(0xff2D333B), const Color(0xff768390))
          : _PillStyle(const Color(0xffF0F0F0), const Color(0xff57606A));
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: style.background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(text,
        style: TextStyle(color: style.foreground, fontSize: 12, fontWeight: FontWeight.w600)),
  );
}

// --- Helper Classes ---
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

class _PillStyle {
  final Color background, foreground;
  _PillStyle(this.background, this.foreground);
}
