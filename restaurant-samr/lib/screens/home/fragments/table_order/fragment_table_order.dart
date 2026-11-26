import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:splash_screen_03/model/entity_table.dart';
import 'package:splash_screen_03/screens/home/fragments/order/controller_order.dart';
import 'package:splash_screen_03/screens/home/fragments/order/controller_ordetype.dart';
import 'package:splash_screen_03/screens/home/fragments/order/fragment_order.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/controller_setting.dart';
import 'package:splash_screen_03/screens/home/fragments/sub_order_type/controller_sub_order.dart';
import 'package:splash_screen_03/screens/home/fragments/table_order/top_hedar.dart';
import 'package:splash_screen_03/screens/home/fragments/table_order/widget/table_order_widet.dart';
import 'package:splash_screen_03/screens/home/fragments/table_type/controller_table.dart';

// ------------------- Keyboard Shortcut Intent ------------------- //
class ToggleCompactIntent extends Intent {
  const ToggleCompactIntent();
}

enum ViewDensity { normal, compact }

class FragmentTableOrder extends StatefulWidget {
  const FragmentTableOrder({super.key});

  @override
  State<FragmentTableOrder> createState() => _FragmentTableOrderState();
}

class _FragmentTableOrderState extends State<FragmentTableOrder> {
  bool isCompact = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF101417) : Colors.grey[100];

    final ControllerTable tableController = Get.put(
      ControllerTable(),
      permanent: true,
    );
    final ControllerOrder catController = Get.put(
      ControllerOrder(),
      permanent: true,
    );
    final ControllerSetting settingController = Get.put(
      ControllerSetting(),
      permanent: true,
    );
    final ControllerSubOrder subController = Get.put(
      ControllerSubOrder(),
      permanent: true,
    );

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.keyC): const ToggleCompactIntent(),
      },
      child: Actions(
        actions: {
          ToggleCompactIntent: CallbackAction<ToggleCompactIntent>(
            onInvoke: (intent) {
              setState(() => isCompact = !isCompact);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: bgColor,
            body: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final bool isMobile = width < 700;
                final bool isTablet = width >= 700 && width < 1100;
                final bool isDesktop = width >= 1100;

                final horizontalPadding = isMobile ? 8.0 : 12.0;
                final verticalPadding = isMobile ? 4.0 : 8.0;

                return SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: verticalPadding,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TopHeaderBarExact(
                                tableController: tableController,
                                orderController: catController,
                                settingController: settingController,
                                subController: subController,
                              ),
                            ),
                            if (!isMobile) const SizedBox(width: 16),
                          ],
                        ),
                      ),

                      // ------------------- Rooms + Tables + Temp Orders ------------------- //
                      Expanded(
                        child: Obx(() {
                          final rooms = tableController.rxRoomList;
                          final temps = tableController.rxTempTables
                              .where((t) => t.showAfterKot)
                              .toList();
                          final allTables = tableController.rxTableList;
                          final filteredTables = allTables.where((table) {
                            return tableController.matchesBooking(
                                  table,
                                  tableController.bookingStatusFilter.value,
                                ) &&
                                tableController.matchesAc(
                                  table,
                                  tableController.acFilter.value,
                                ) &&
                                tableController.matchesRoom(
                                  table,
                                  tableController.roomFilter.value,
                                ) &&
                                tableController.matchesSearch(
                                  table,
                                  tableController.searchQuery.value,
                                );
                          }).toList();

                          if (rooms.isEmpty && temps.isEmpty) {
                            return Center(
                              child: Text(
                                "No Tables Found",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: theme.disabledColor,
                                ),
                              ),
                            );
                          }

                          // --- Responsive grid logic ---
                          final baseCrossAxisCount = width > 1500
                              ? 6
                              : width > 1200
                              ? 5
                              : width > 900
                              ? 4
                              : width > 650
                              ? 3
                              : 2;

                          final crossAxisCount =
                              baseCrossAxisCount + (isCompact ? 1 : 0);
                          final tileAspect = isCompact
                              ? (isMobile ? 1.8 : 4 / 2.0)
                              : (isMobile ? 1.4 : 4 / 2.7);

                          return ListView(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding * 2,
                              vertical: verticalPadding,
                            ),
                            children: [
                              ...rooms.map((room) {
                                final tablesInRoom = filteredTables
                                    .where((t) => t.roomType == room.name)
                                    .toList();
                                if (tablesInRoom.isEmpty)
                                  return const SizedBox.shrink();

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(
                                        top: isMobile ? 8 : 16,
                                        bottom: isMobile ? 4 : 8,
                                      ),
                                      child: Text(
                                        room.name ?? '',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black87,
                                              fontSize: isMobile ? 14 : 16,
                                            ),
                                      ),
                                    ),
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: crossAxisCount,
                                            crossAxisSpacing: isMobile ? 8 : 16,
                                            mainAxisSpacing: isMobile ? 8 : 16,
                                            childAspectRatio: tileAspect,
                                          ),
                                      itemCount: tablesInRoom.length,
                                      itemBuilder: (context, tableIndex) {
                                        final table = tablesInRoom[tableIndex];
                                        return _buildTableCard(
                                          context,
                                          theme,
                                          table.tableName ?? '',
                                          table,
                                          compact: isCompact,
                                        );
                                      },
                                    ),
                                  ],
                                );
                              }),
                              if (temps.isNotEmpty) ...[
                                Padding(
                                  padding: EdgeInsets.only(
                                    top: isMobile ? 10 : 16,
                                    bottom: isMobile ? 6 : 8,
                                  ),
                                  child: Text(
                                    "Temporary Orders",
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black87,
                                          fontSize: isMobile ? 14 : 16,
                                        ),
                                  ),
                                ),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        crossAxisSpacing: isMobile ? 8 : 16,
                                        mainAxisSpacing: isMobile ? 8 : 16,
                                        childAspectRatio: tileAspect,
                                      ),
                                  itemCount: temps.length,
                                  itemBuilder: (context, index) {
                                    final temp = temps[index];
                                    return _buildTempTile(
                                      context,
                                      theme,
                                      temp,
                                      compact: isCompact,
                                    );
                                  },
                                ),
                              ],
                              const SizedBox(height: 12),
                            ],
                          );
                        }),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------- TEMP TABLE TILE ------------------- //
Widget _buildTempTile(
  BuildContext context,
  ThemeData theme,
  TempOrderTable temp, {
  bool compact = false,
}) {
  final tableController = Get.find<ControllerTable>();
  final order = Get.find<ControllerOrder>();
  final setting = Get.find<ControllerSetting>();

  final tName = temp.name.trim();

  return Obx(() {
    final tick = order.tilesPulse.value;
    final hasItems = order.canShowBillActions(tName);
    final billingReady =
        order.hasPreparedBill(tName) || order.isDraftSavedFor(tName);
    final style = resolveTileStyle(
      context: context,
      tableName: tName,
      isTemp: true,
      hasActions: hasItems,
      isDraftSaved: billingReady,
      isBooked: true,
    );

    final showIcons = style.showActions && setting.showBillIconsOnTable;
    final bill = order.findLatestOpenBillForTable(tName);
    final latest = latestKotFromBill(bill);
    final billNo = bill?.orderNumber;
    final billChip = (billingReady && billNo != null && billNo > 0)
        ? statusChip(
            label: 'Bill #$billNo',
            bg: TilePalette.chipBillingBg(context),
            fg: TilePalette.chipTextOnColor(context),
          )
        : null;

    final kotChip = latest.kotNo != null
        ? statusChip(
            label: 'KOT ${latest.kotNo}',
            bg: TilePalette.chipKotBg(context),
            fg: TilePalette.chipTextOnColor(context),
          )
        : null;
    final total = style.showTotals ? order.getTotalPrice(forTable: tName) : 0.0;
    final mins = style.showTotals ? minsAgo(latest.at) : null;
    final assignee = assigneeFromBill(bill);

    final isAvailable = style.statusLabel?.toLowerCase() == 'available';

    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                temp.type,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: compact ? 14 : 16,
                ),
              ),
            ),
            if (showIcons) ...[
              const SizedBox(width: 8),
              TinyIconButton(
                icon: Icons.remove_red_eye,
                tooltip: 'Bill preview',
                onTap: () => order.showBillPreview(context, tableName: tName),
              ),
              const SizedBox(width: 6),
              TinyIconButton(
                icon: billingReady
                    ? Icons.payments_rounded
                    : Icons.save_rounded,
                tooltip: billingReady ? 'Settle bill' : 'Save bill',
                onTap: () async {
                  if (billingReady) {
                    await order.showSettleDialog(context, tableName: tName);
                  } else {
                    await order.saveBillOnly(table: null, printCopy: false);
                  }
                  order.refreshTiles();
                },
              ),
            ],
          ],
        ),
        SizedBox(height: compact ? 8 : 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (style.statusLabel != null)
              statusChip(
                label: style.statusLabel!,
                bg: style.statusBg ?? Colors.white12,
                fg: Colors.white,
              ),
            if (billChip != null) billChip else if (kotChip != null) kotChip,
          ],
        ),
        if (!compact && assignee != null && assignee.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            assignee,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ],
        const Spacer(),
        if (style.showTotals)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!compact)
                Text(
                  money(context, total),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              Text(
                mins ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
      ],
    );

    return InkWell(
      onTap: () {
        tableController.selectedTempTable.value = temp;
        tableController.selectedTable.value = null;
        order.loadTableOrders(tName);
        Get.to(() => ActivityCategoryFood(initialTabIndex: hasItems ? 1 : 0));
      },
      child: isAvailable
          ? GlassssCard(overlayColor: style.bg, child: cardContent)
          : AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: style.bg,
              ),
              padding: EdgeInsets.all(compact ? 12 : 16),
              child: cardContent,
            ),
    );
  });
}

// ------------------- NORMAL TABLE TILE (with safe merge) ------------------- //
Widget _buildTableCard(
  BuildContext context,
  ThemeData theme,
  String title,
  EntityTable table, {
  bool compact = false,
}) {
  final ControllerTable tableController = Get.find();
  final ControllerOrder order = Get.find<ControllerOrder>();
  final ControllerSetting setting = Get.find<ControllerSetting>();
  final tName = (table.tableName ?? title).trim();

  return Obx(() {
    final isBooked = tableController.isTableBooked(tName);
    final hasActions = order.canShowBillActions(tName);
    final billingReady =
        order.hasPreparedBill(tName) || order.isDraftSavedFor(tName);

    final style = resolveTileStyle(
      context: context,
      tableName: tName,
      isTemp: false,
      hasActions: hasActions,
      isDraftSaved: billingReady,
      isBooked: isBooked,
    );

    final showIcons = style.showActions && setting.showBillIconsOnTable;
    final bill = order.findLatestOpenBillForTable(tName);
    final latest = latestKotFromBill(bill);
    final billNo = bill?.orderNumber;

    final billChip = (billingReady && billNo != null && billNo > 0)
        ? statusChip(
            label: 'Bill #$billNo',
            bg: TilePalette.chipBillingBg(context),
            fg: style.intenseFg
                ? TilePalette.chipTextOnColor(context)
                : TilePalette.chipTextOnNeutral(context),
          )
        : null;

    final kotChip = latest.kotNo != null
        ? statusChip(
            label: 'KOT ${latest.kotNo}',
            bg: TilePalette.chipKotBg(context),
            fg: style.intenseFg
                ? TilePalette.chipTextOnColor(context)
                : TilePalette.chipTextOnNeutral(context),
          )
        : null;

    final total = style.showTotals ? order.getTotalPrice(forTable: tName) : 0.0;
    final totalLabel = style.showTotals ? money(context, total) : null;
    final mins = style.showTotals ? minsAgo(latest.at) : null;
    final assignee = assigneeFromBill(bill);
    final isAvailable = style.statusLabel?.toLowerCase() == 'available';

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${table.tableName ?? title} ${table.roomType != null ? '(${table.roomType})' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: style.titleColor,
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 14 : 16,
                ),
              ),
            ),
            if (showIcons) ...[
              const SizedBox(width: 8),
              TinyIconButton(
                icon: Icons.remove_red_eye,
                tooltip: 'Bill preview',
                onTap: () => order.showBillPreview(context, tableName: tName),
              ),
              const SizedBox(width: 6),
              TinyIconButton(
                icon: billingReady
                    ? Icons.payments_rounded
                    : Icons.save_rounded,
                tooltip: billingReady ? 'Settle bill' : 'Save bill',
                onTap: () async {
                  if (billingReady) {
                    await order.showSettleDialog(context, tableName: tName);
                  } else {
                    await order.saveBillOnly(table: table, printCopy: false);
                  }
                  order.refreshTiles();
                },
              ),
            ],
          ],
        ),
        SizedBox(height: compact ? 8 : 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (style.statusLabel != null)
              statusChip(
                label: style.statusLabel!,
                bg: style.statusBg ?? Colors.transparent,
                fg:
                    style.statusFg ??
                    (style.intenseFg
                        ? TilePalette.chipTextOnColor(context)
                        : TilePalette.chipTextOnNeutral(context)),
              ),
            if (billChip != null) billChip else if (kotChip != null) kotChip,
          ],
        ),
        if (!compact && assignee != null && assignee.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            assignee,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: style.intenseFg
                  ? Colors.white70
                  : TilePalette.softTextOnNeutral(context),
            ),
          ),
        ],
        const Spacer(),
        if (style.showTotals)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!compact)
                Text(
                  totalLabel ?? '',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: style.intenseFg
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              Text(
                mins ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: style.intenseFg
                      ? Colors.white70
                      : TilePalette.softTextOnNeutral(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
      ],
    );

    return GestureDetector(
      // ✅ Right-click (desktop/web) → Show merge option only if table is booked
      onSecondaryTapDown: (details) {
        if (isBooked) {
          _showTableContextMenu(context, details.globalPosition, table);
        }
      },

      // ✅ Long-press (mobile) → Allow merge only when booked
      onLongPress: () {
        if (isBooked) {
          _openMergeDialog(context, source: tName);
        }
      },

      child: InkWell(
      onTap: () {
  tableController.selectTable(table);
  tableController.rxCurrentTable.value = tName;

  final orderController = Get.find<ControllerOrder>();

  // ✅ FIX — get real MongoDB Order Type ID for Dine In
  final dine = _findOrderType("Dine In");

  orderController.selectOrderTypeById(
    id: dine["id"]!,      // real MongoDB _id (ex: 691e2c69b71b046bab266f37)
    label: dine["label"]!,
  );

  order.loadTableOrders(tName);

  Get.to(() => ActivityCategoryFood(initialTabIndex: hasActions ? 1 : 0));
},

        child: isAvailable
            ? GlassssCard(overlayColor: style.bg, child: content)
            : AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: style.bg,
                  borderRadius: BorderRadius.circular(16),
                  border: style.intenseFg
                      ? null
                      : Border.all(color: TilePalette.neutralBorder(context)),
                ),
                padding: EdgeInsets.all(compact ? 12 : 16),
                child: content,
              ),
      ),
    );
  });
}

// ------------------- GlasssCard ------------------- //
class GlassssCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  final Color? overlayColor;

  const GlassssCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(16),
    this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                (overlayColor ?? Colors.white).withOpacity(
                  isDark ? 0.05 : 0.25,
                ),
                (overlayColor ?? Colors.white).withOpacity(
                  isDark ? 0.03 : 0.15,
                ),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

// NEW: Function to display the color legend dialog
void showColorKeyDialog(BuildContext context) {
  // Helper widget to create a single legend entry
  Widget legendItem(Color color, String title, String subtitle) {
    final bool isLightColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.light;
    final borderColor = isLightColor ? Colors.black26 : Colors.white24;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 1.5),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.palette_outlined),
            SizedBox(width: 10),
            Text('Table Status Colors'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              legendItem(
                TilePalette.billingBg(dialogContext),
                'Billing (Teal)',
                'Bill is prepared and ready for settlement.',
              ),
              legendItem(
                TilePalette.occupiedBg(dialogContext),
                'Occupied (Blue)',
                'Items have been added to the table.',
              ),
              legendItem(
                TilePalette.tempBg(dialogContext),
                'Active (Orange)',
                'A temporary order like Delivery or Pickup.',
              ),
              legendItem(
                TilePalette.availableBg(dialogContext),
                'Available',
                'The table is empty and ready for new guests.',
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('CLOSE'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      );
    },
  );
}

// --- All other helper functions and classes remain the same ---
// (e.g., _showTableContextMenu, _openMergeDialog, TilePalette, TileStyle, etc.)
// ... (The rest of the file you provided)
/// Find real Order Type ID from API
Map<String, String> _findOrderType(String name) {
  final c = Get.find<ControllerOrderType>();

  // Special case for your local Quick Bill
  if (name == "Quick Bill") {
    return {
      "id": "local-quickbill",
      "label": "Quick Bill",
    };
  }

  // Search in the API-loaded order types
  final match = c.rxOrderTypes.firstWhereOrNull(
    (e) => e["name"]["en"].toString().toLowerCase() == name.toLowerCase(),
  );

  if (match == null) {
    return {"id": "", "label": name}; // fallback
  }

  return {
    "id": match["_id"],       // <-- real Mongo ID from backend
    "label": match["name"]["en"],
  };
}

void _showTableContextMenu(
  BuildContext context,
  Offset position,
  EntityTable table,
) async {
  final selected = await showMenu<String>(
    context: context,
    position: RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      position.dx,
      position.dy,
    ),
    items: const [
      PopupMenuItem<String>(
        value: 'merge',
        child: ListTile(
          dense: true,
          leading: Icon(Icons.call_merge),
          title: Text('Merge into...'),
        ),
      ),
    ],
  );

  if (selected == 'merge') {
    _openMergeDialog(context, source: (table.tableName ?? '').trim());
  }
}

Future<void> _openMergeDialog(
  BuildContext context, {
  required String source,
}) async {
  if (source.isEmpty) return;
  final tableCtrl = Get.find<ControllerTable>();
  final orderCtrl = Get.find<ControllerOrder>();

  String? target;
  bool includeLocal = true;
  bool printAfter = false;

  final allTargets =
      tableCtrl.rxTableList
          .map((t) => (t.tableName ?? '').trim())
          .where(
            (name) =>
                name.isNotEmpty && name.toLowerCase() != source.toLowerCase(),
          )
          .toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  await showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text('Merge Tables'),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'From: $source',
                      style: Theme.of(ctx).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: target,
                    items: [
                      for (final name in allTargets)
                        DropdownMenuItem(value: name, child: Text(name)),
                    ],
                    onChanged: (v) => setState(() => target = v),
                    decoration: const InputDecoration(
                      labelText: 'Merge into',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: includeLocal,
                    onChanged: (v) => setState(() => includeLocal = v ?? true),
                    title: const Text('Include unsent (local) items'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: printAfter,
                    onChanged: (v) => setState(() => printAfter = v ?? false),
                    title: const Text('Print pending KOTs after merge'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Merge'),
                onPressed: (target == null)
                    ? null
                    : () async {
                        final String targetTableName = target!;
                        Navigator.pop(ctx);

                        await orderCtrl.mergeTables(
                          from: source,
                          into: targetTableName,
                          moveLocal: includeLocal,
                          printMergeKot: printAfter,
                        );

                        final targetTable = tableCtrl.rxTableList
                            .firstWhereOrNull(
                              (t) => t.tableName == targetTableName,
                            );

                        if (targetTable != null) {
                          tableCtrl.selectTable(targetTable);
                          tableCtrl.rxCurrentTable.value = targetTableName;
                          orderCtrl.loadTableOrders(targetTableName);

                          Get.to(
                            () =>
                                const ActivityCategoryFood(initialTabIndex: 1),
                          );
                        } else {
                          Get.snackbar(
                            'Merge Complete',
                            'Data from "$source" was merged into "$targetTableName".',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      },
              ),
            ],
          );
        },
      );
    },
  );
}

class _MiniFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? color;

  const _MiniFab({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? Theme.of(context).colorScheme.primaryContainer;
    final fg = Theme.of(context).colorScheme.onPrimaryContainer;
    final btn = Material(
      color: bg.withOpacity(0.95),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: fg),
        ),
      ),
    );

    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}
