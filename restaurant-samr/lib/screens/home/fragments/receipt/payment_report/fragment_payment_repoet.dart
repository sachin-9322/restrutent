// FragmentOrderReport.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:splash_screen_03/screens/home/fragments/receipt/fragments/order_report/controller_order_report.dart';
import 'package:splash_screen_03/screens/home/fragments/receipt/payment_report/controller_paymnet.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/controller_setting.dart';

class FragmentPaymentRepoet extends StatefulWidget {
  const FragmentPaymentRepoet({super.key});

  @override
  State<FragmentPaymentRepoet> createState() => _FragmentPaymentRepoetState();
}

class _FragmentPaymentRepoetState extends State<FragmentPaymentRepoet> {
  late final ControllerPaymnet ctrl;
  final TextEditingController _searchCtrl = TextEditingController();
  final DateFormat _df = DateFormat('dd/MM/yyyy');

  final ScrollController _hScroll = ScrollController();
  final ScrollController _vScroll = ScrollController();
  final ScrollController _controlsScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    try {
      ctrl = Get.find<ControllerPaymnet>();
    } catch (_) {
      ctrl = Get.put(ControllerPaymnet(), permanent: true);
    }
    _searchCtrl.text = ctrl.searchText.value;
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    ctrl.searchText.value = _searchCtrl.text;
    // If controller has a combined filter method (like Sales), prefer that.
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

  // THEME (matches Sales UI)
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
      width: 280,
      child: TextField(
        controller: _searchCtrl,
        style: TextStyle(color: colors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search by Order From...',
          hintStyle: TextStyle(color: colors.textSecondary, fontSize: 14),
          prefixIcon: Icon(Icons.search, size: 20, color: colors.textSecondary),
          filled: true,
          fillColor: colors.controlFill,
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }

  Widget _buildDateFilterButton(ThemeData theme, _AppColors colors) {
    return SizedBox(
      height: _controlHeight,
      child: Obx(() {
        final dr = ctrl.selectedDateRange.value;
        final label = ctrl.getDateLabel(dr, _df);

        return PopupMenuButton<String>(
          tooltip: 'Select date range',
          color: colors.headerFooter,
          onSelected: (value) async {
            if (value == 'all') {
              ctrl.clearDateRange();
            } else if (value == 'today') {
              ctrl.presetToday();
            } else if (value == 'yesterday') {
              ctrl.presetYesterday();
            } else if (value == 'last7') {
              ctrl.presetLast7Days();
            } else if (value == 'last30') {
              ctrl.presetLast30Days();
            } else if (value == 'thisMonth') {
              ctrl.presetThisMonth();
            } else if (value == 'lastMonth') {
              ctrl.presetLastMonth();
            } else if (value == 'custom') {
              final now = DateTime.now();
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 5),
                lastDate: DateTime(now.year + 1),
                initialDateRange:
                    ctrl.selectedDateRange.value ??
                    DateTimeRange(start: now, end: now),
              );
              if (picked != null) {
                ctrl.setDateRange(
                  DateTimeRange(
                    start: DateTime(
                      picked.start.year,
                      picked.start.month,
                      picked.start.day,
                    ),
                    end: DateTime(
                      picked.end.year,
                      picked.end.month,
                      picked.end.day,
                      23,
                      59,
                      59,
                    ),
                  ),
                );
              }
            }
          },
          itemBuilder: (ctx) => const [
            PopupMenuItem(value: 'today', child: Text('Today')),
            PopupMenuItem(value: 'yesterday', child: Text('Yesterday')),
            PopupMenuItem(value: 'last7', child: Text('Last 7 Days')),
            PopupMenuItem(value: 'last30', child: Text('Last 30 Days')),
            PopupMenuItem(value: 'thisMonth', child: Text('This Month')),
            PopupMenuItem(value: 'lastMonth', child: Text('Last Month')),
            PopupMenuDivider(),
            PopupMenuItem(value: 'custom', child: Text('Custom Range')),
            PopupMenuItem(value: 'all', child: Text('All Time')),
          ],
          child: Container(
            height: _controlHeight,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colors.controlFill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.divider),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: dr == null
                          ? colors.textSecondary
                          : colors.textPrimary,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, color: colors.textSecondary),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildClearFilterButton(_AppColors colors) {
    return SizedBox(
      height: _controlHeight,
      child: TextButton.icon(
        onPressed: () {
          _searchCtrl.clear();
        },
        icon: Icon(Icons.close, size: 18, color: colors.textSecondary),
        label: Text(
          'Clear filter',
          style: TextStyle(color: colors.textSecondary, fontSize: 14),
        ),
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
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
            Get.snackbar(
              'Export',
              'Successfully exported to Downloads folder',
              snackPosition: SnackPosition.BOTTOM,
            );
          } catch (e) {
            Get.snackbar(
              'Export',
              'Failed: $e',
              snackPosition: SnackPosition.BOTTOM,
            );
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

  Widget _buildStatusPill(ThemeData theme, String text) {
    final bool isDark = theme.brightness == Brightness.dark;
    _PillStyle style;

    switch (text.toLowerCase()) {
      case 'settled':
      case 'completed':
      case 'delivered':
      case 'paid':
        style = isDark
            ? _PillStyle(const Color(0xff1A382A), const Color(0xff6AFB92))
            : _PillStyle(const Color(0xffDFF7EA), const Color(0xff185B33));
        break;
      case 'unpaid':
      case 'cancelled':
      case 'void':
      case 'rejected':
      case 'failed':
        style = isDark
            ? _PillStyle(const Color(0xff431B22), const Color(0xffF8716F))
            : _PillStyle(const Color(0xffFFEBE9), const Color(0xff9D2422));
        break;
      case 'pending':
      case 'processing':
      case 'preparing':
        style = isDark
            ? _PillStyle(const Color(0xff3D2D0C), const Color(0xffEAC54F))
            : _PillStyle(const Color(0xffFFF8E5), const Color(0xff7E5900));
        break;
      default:
        style = isDark
            ? _PillStyle(const Color(0xff2D333B), const Color(0xff768390))
            : _PillStyle(const Color(0xffF0F0F0), const Color(0xff57606A));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: style.background,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: style.foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
Widget _buildTable(
  ThemeData theme,
  _AppColors colors,
  BoxConstraints constraints,
) {
  return Obx(() {
    final list = ctrl.filteredReceipts;
    if (list.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Text(
            'No records found...',
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
      );
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
                border: TableBorder(
                  horizontalInside: BorderSide(
                    color: colors.divider,
                    width: 1.0,
                  ),
                ),
                columnSpacing: 12,
                horizontalMargin: 16,
                headingRowHeight: 52,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 56,
                headingRowColor: WidgetStateProperty.all(colors.headerFooter),
                headingTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colors.textSecondary,
                  fontSize: 13,
                ),
                dataTextStyle: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                ),
                columns: const [
                  // PAYMENT MODE LABEL
                  DataColumn(label: Text('PAYMENT MODE')),

                  // COUNT
                  DataColumn(
                    label: SizedBox(
                      width: 80,
                      child: Center(child: Text('COUNT')),
                    ),
                    numeric: true,
                  ),

                  // STATUS
                  DataColumn(
                    label: SizedBox(
                      width: 120,
                      child: Center(child: Text('STATUS')),
                    ),
                  ),

                  // AMOUNT
                  DataColumn(
                    label: SizedBox(
                      width: 120,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text('AMOUNT'),
                      ),
                    ),
                    numeric: true,
                  ),
                ],
                rows: List.generate(list.length, (i) {
                  final r = list[i];

                  return DataRow(
                    cells: [
                      // PAYMENT MODE (Cash / UPI / Card…)
                      DataCell(Text(r.mode)),

                      // COUNT
                      DataCell(
                        SizedBox(
                          width: 80,
                          child: Center(child: Text(r.qty.toString())),
                        ),
                      ),

                      // STATUS
                      DataCell(
                        SizedBox(
                          width: 120,
                          child: Center(
                            child: _buildStatusPill(theme, r.status),
                          ),
                        ),
                      ),

                      // AMOUNT
                      DataCell(
                        SizedBox(
                          width: 120,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(r.amount.toStringAsFixed(2)),
                          ),
                        ),
                      ),
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


  Widget _buildFooterRow(ThemeData theme, _AppColors colors) {
    final settings = Get.find<ControllerSetting>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: colors.headerFooter,
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
            Text(
              'Total: ${formatter.format(total)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            if (ctrl.totalPages > 1)
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left,
                      size: 20,
                      color: colors.textSecondary,
                    ),
                    onPressed: ctrl.currentPage.value > 1
                        ? () => ctrl.prevPage()
                        : null,
                    splashRadius: 20,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${ctrl.currentPage.value}',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'of ${ctrl.totalPages}',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: colors.textSecondary,
                    ),
                    onPressed: ctrl.currentPage.value < ctrl.totalPages
                        ? () => ctrl.nextPage()
                        : null,
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
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return _buildTable(theme, colors, constraints);
                        },
                      ),
                    ),
                    _buildFooterRow(theme, colors),
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
  final Color scaffold,
      surface,
      headerFooter,
      controlFill,
      divider,
      textPrimary,
      textSecondary;
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
