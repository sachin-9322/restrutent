import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:splash_screen_03/model/entity_bill.dart';

import 'package:splash_screen_03/screens/home/fragments/setting/controller_setting.dart';

// put this anywhere in a common file that sees EntityOrder class (kept here for convenience)
extension EntityOrderJsonExt on EntityOrder {
  // Always returns a map like: {'items': List, 'meta': Map}
  Map<String, dynamic> readItemsWrapper() {
    try {
      // Prefer itemsJson wrapper; fallback to metaJson (old)
      final raw = () {
        if ((itemsJson ?? '').trim().isNotEmpty) return itemsJson!.trim();
        if ((metaJson ?? '').trim().isNotEmpty) return metaJson!.trim();
        return null;
      }();

      if (raw == null) return {'items': const [], 'meta': const {}};

      final decoded = jsonDecode(raw);

      if (decoded is Map) {
        final items =
            decoded['items'] is List ? List.from(decoded['items']) : const [];
        final meta = decoded['meta'] is Map
            ? Map<String, dynamic>.from(decoded['meta'])
            : <String, dynamic>{};
        return {'items': items, 'meta': meta};
      }

      if (decoded is List) {
        // Old format: only items array
        return {'items': decoded, 'meta': const {}};
      }

      return {'items': const [], 'meta': const {}};
    } catch (_) {
      return {'items': const [], 'meta': const {}};
    }
  }

  Map<String, dynamic> readMeta() {
    final w = readItemsWrapper();
    return (w['meta'] is Map<String, dynamic>)
        ? w['meta'] as Map<String, dynamic>
        : <String, dynamic>{};
  }

  void writeMeta(Map<String, dynamic> meta) {
    final w = readItemsWrapper();
    final wrapped = {
      'items': w['items'] ?? const [],
      'meta': {...(w['meta'] as Map? ?? const {}), ...meta},
    };
    try {
      itemsJson = jsonEncode(wrapped);
    } catch (_) {}
  }

  void writeItemsWrapper({List<dynamic>? items, Map<String, dynamic>? meta}) {
    final w = readItemsWrapper();
    final wrapped = {
      'items': items ?? (w['items'] ?? const []),
      'meta': {...(w['meta'] as Map? ?? const {}), ...(meta ?? const {})},
    };
    try {
      itemsJson = jsonEncode(wrapped);
    } catch (_) {}
  }
}

class TilePalette {
  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color availableBg(BuildContext ctx) =>
      _isDark(ctx) ? const Color(0xFF2C3136) : const Color(0xFFF2F3F5);

  static Color occupiedBg(BuildContext ctx) => const Color(0xFF63A7FF); // blue
  static Color billingBg(BuildContext ctx) => const Color(0xFF005D6A); // purple
  static Color tempBg(BuildContext ctx) => const Color(0xFFE96C52); // orange

  static Color cardFgOnColor(BuildContext ctx) => Colors.white;
  static Color neutralBorder(BuildContext ctx) =>
      _isDark(ctx) ? const Color(0xFF3A4046) : const Color(0xFFE1E3E6);
  static Color softTextOnNeutral(BuildContext ctx) =>
      _isDark(ctx) ? Colors.white70 : Colors.black54;

  static Color chipAvailableBg(BuildContext ctx) => const Color(0xFF40C57B);
  static Color chipOccupiedBg(BuildContext ctx) =>
      Colors.white.withOpacity(0.15);
  static Color chipBillingBg(BuildContext ctx) =>
      Colors.white.withOpacity(0.15);
  static Color chipKotBg(BuildContext ctx) => Colors.white.withOpacity(0.15);

  static Color chipTextOnColor(BuildContext ctx) => Colors.white;
  static Color chipTextOnNeutral(BuildContext ctx) =>
      _isDark(ctx) ? Colors.white : Colors.black87;
}

class TileStyle {
  final Color bg;
  final Color titleColor;
  final String? statusLabel; // Available | Occupied | Billing | Active (temp)
  final Color? statusBg;
  final Color? statusFg;
  final bool showActions; // eye + save/settle
  final bool showTotals; // amount/time line
  final bool intenseFg; // use white on colored cards
  const TileStyle({
    required this.bg,
    required this.titleColor,
    this.statusLabel,
    this.statusBg,
    this.statusFg,
    this.showActions = false,
    this.showTotals = false,
    this.intenseFg = false,
  });
}
TileStyle resolveTileStyle({
  required BuildContext context,
  required String tableName,
  required bool isTemp,
  required bool hasActions,
  required bool isDraftSaved,
  required bool isBooked,
}) {
  // TEMP orders
  if (isTemp) {
    // If bill is saved/prepared, show Billing style (purple)
    if (isDraftSaved) {
      return TileStyle(
        bg: TilePalette.billingBg(context),
        titleColor: TilePalette.cardFgOnColor(context),
        statusLabel: 'Billing',
        statusBg: TilePalette.chipBillingBg(context),
        statusFg: TilePalette.chipTextOnColor(context),
        showActions: true,
        showTotals: true,
        intenseFg: true,
      );
    }
    // Otherwise, Active (orange)
    return TileStyle(
      bg: TilePalette.tempBg(context),
      titleColor: TilePalette.cardFgOnColor(context),
      statusLabel: 'Active',
      statusBg: TilePalette.chipKotBg(context),
      statusFg: TilePalette.chipTextOnColor(context),
      showActions: hasActions,
      showTotals: true,
      intenseFg: true,
    );
  }

  // PHYSICAL tables
  if (!isBooked && !hasActions) {
    // Available
    return TileStyle(
      bg: TilePalette.availableBg(context),
      titleColor: Theme.of(context).colorScheme.onSurface,
      statusLabel: 'Available',
      statusBg: TilePalette.chipAvailableBg(context),
      statusFg: Colors.white,
      showActions: false,
      showTotals: false,
      intenseFg: false,
    );
  }

  if (isDraftSaved) {
    // Billing (saved draft or prepared)
    return TileStyle(
      bg: TilePalette.billingBg(context),
      titleColor: TilePalette.cardFgOnColor(context),
      statusLabel: 'Billing',
      statusBg: TilePalette.chipBillingBg(context),
      statusFg: TilePalette.chipTextOnColor(context),
      showActions: true,
      showTotals: true,
      intenseFg: true,
    );
  }

  // Occupied
  return TileStyle(
    bg: TilePalette.occupiedBg(context),
    titleColor: TilePalette.cardFgOnColor(context),
    statusLabel: 'Occupied',
    statusBg: TilePalette.chipOccupiedBg(context),
    statusFg: TilePalette.chipTextOnColor(context),
    showActions: true,
    showTotals: true,
    intenseFg: true,
  );
}

Widget statusChip({
  required String label,
  required Color bg,
  required Color fg,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}

class TinyIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color? color;
  const TinyIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bg = (color ?? Theme.of(context).colorScheme.surface).withOpacity(0.15);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}


String money(
  BuildContext context,
  double value, {
  String? code,              // optional override like 'USD'
  bool preferSymbol = true,  // true => symbol, false => code
}) {
  final setting = Get.isRegistered<ControllerSetting>()
      ? Get.find<ControllerSetting>()
      : null;

  final symbolOrCode = code ??
      (preferSymbol
          ? (setting?.currSymbol ?? 'AED')
          : (setting?.currCode ?? 'AED'));

  final locale = setting?.currLocale ?? 'en_US';
  final fmt = NumberFormat.currency(
    locale: locale,
    symbol: symbolOrCode,
  );
  return fmt.format(value);
}

String minsAgo(DateTime? dt) {
  if (dt == null) return '';
  final m = DateTime.now().difference(dt).inMinutes;
  if (m <= 0) return 'now';
  return '$m min';
}

// Best-effort latest KOT number + time from bill.foods
({int? kotNo, DateTime? at}) latestKotFromBill(EntityOrder? bill) {
  if (bill == null) return (kotNo: null, at: null);
  int? kot;
  DateTime? ts;
  for (final f in bill.listFood) {
    final k = (f.kotNumber ?? 0);
    final iso = (f.createdOn ?? f.createdOn);
    DateTime? t;
    try {
      t = iso != null && iso.isNotEmpty ? DateTime.parse(iso) : null;
    } catch (_) {}
    if (t == null && ts == null) {
      // fallback to bill start time
      try {
        t = (bill.startTime?.isNotEmpty ?? false)
            ? DateTime.parse(bill.startTime!)
            : null;
      } catch (_) {}
    }
    if (ts == null || (t != null && t.isAfter(ts))) {
      ts = t;
      kot = k > 0 ? k : kot;
    }
  }
  return (kotNo: kot, at: ts);
}

// Try to read a staff/delivery label from bill.meta (if you store it)
String? assigneeFromBill(EntityOrder? bill) {
  if (bill == null) return null;
  try {
    final wrap = bill.readItemsWrapper();
    final meta = (wrap['meta'] as Map?) ?? {};
    return (meta['waiter'] ??
            meta['steward'] ??
            meta['userName'] ??
            meta['dBoy'])
        ?.toString();
  } catch (_) {
    return null;
  }
}