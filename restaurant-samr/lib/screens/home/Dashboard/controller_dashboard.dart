import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:objectbox/objectbox.dart';
import 'package:splash_screen_03/captain/login/auth_service.dart';

import 'package:splash_screen_03/model/entity_bill.dart';
import 'package:splash_screen_03/model/enum_bill_status.dart';
import 'package:splash_screen_03/objectbox.g.dart';
import 'package:splash_screen_03/screens/home/fragments/order/controller_order.dart';
import 'package:splash_screen_03/screens/home/fragments/order/controller_ordetype.dart';
import 'package:tuple/tuple.dart';
import 'package:splash_screen_03/model/payment_method.dart';

class ControllerDashboard extends GetxController {
  final Box<EntityOrder> boxEntityOrder = Get.find();
  final ControllerOrder ctrlOrder = Get.find<ControllerOrder>();

  // Payment modes aggregated by amount for pie
  final RxMap<String, double> paymentModeAmounts = <String, double>{}.obs;
  // Add this anywhere inside ControllerDashboard (after _resolveSettledOrCreatedTime)
  DateTime resolveOrderTime(EntityOrder b) {
    return _resolveSettledOrCreatedTime(b);
  }

  // Reactive stats
  final RxDouble totalToday = 0.0.obs;
  final RxDouble totalMonth = 0.0.obs;
  final RxDouble totalYear = 0.0.obs;

  final RxInt ordersToday = 0.obs;
  final RxInt ordersWeek = 0.obs;
  final RxInt ordersMonth = 0.obs;

  // Extra metrics
  final RxInt uniqueCustomers = 0.obs;
  final RxInt activeUsers24h = 0.obs;
  final RxDouble avgOrderValue = 0.0.obs;

  // Order types and payment counts
  final RxMap<String, int> orderTypeCounts = <String, int>{}.obs;
  final RxMap<String, int> paymentModeCounts = <String, int>{}.obs;

  final RxList<EntityOrder> recentOrders = <EntityOrder>[].obs;
  final RxString chartRange = "7".obs; // 7 = week, 15 = 15 days, 30 = 1 month
  final RxList<FlSpot> salesSpots = <FlSpot>[].obs;
  final RxDouble yesterdaySalesTotal = 0.0.obs;

  // Hourly
  final RxList<FlSpot> hourlySpotsAmount = <FlSpot>[].obs; // 24 points
  final RxList<int> hourlyCounts = <int>[].obs; // 24 points
  final RxList<double> hourlyAmounts = <double>[].obs; // 24 points

  // Peak / low
  final RxInt peakHour = 0.obs;
  final RxDouble peakValue = 0.0.obs;
  final RxInt lowHour = 0.obs;
  final RxDouble lowValue = 0.0.obs;

  // Top selling items
  final RxList<Map<String, dynamic>> topSellingItems =
      <Map<String, dynamic>>[].obs;
  final RxInt topSellingLimit = 6.obs;

  List<Map<String, dynamic>> getTopSellingItemsForRange(String range) {
    final start = _startForRange(range);
    final now = DateTime.now();
    final billsInRange = boxEntityOrder.getAll().where((b) {
      final status = (b.status ?? '').toLowerCase();
      if (status != 'settled') return false;
      final ts = _resolveSettledOrCreatedTime(b);
      return !ts.isBefore(start) && !ts.isAfter(now);
    }).toList();
    // <-- FIX: Corrected the method name here
    return _computeTopSellingFromBills(billsInRange);
  }

  Map<String, double> getPaymentModeAmountsForRange(String range) {
    final start = _startForRange(range);
    final now = DateTime.now();
    final Map<String, double> payAmounts = {};
    final billsInRange = boxEntityOrder.getAll().where((b) {
      final status = (b.status ?? '').toLowerCase();
      if (status != 'settled') return false;
      final ts = _resolveSettledOrCreatedTime(b);
      return !ts.isBefore(start) && !ts.isAfter(now);
    }).toList();

    for (final b in billsInRange) {
      final splits = _extractPaymentSplits(b);
      if (splits.isNotEmpty) {
        splits.forEach((mode, amt) {
          if (amt > 0) {
            payAmounts[mode] = (payAmounts[mode] ?? 0.0) + amt;
          }
        });
      } else {
        final amount = b.totalAmount ?? 0.0;
        payAmounts['Others'] = (payAmounts['Others'] ?? 0.0) + amount;
      }
    }
    return payAmounts;
  }

  Tuple2<List<BarChartGroupData>, Widget Function(double, TitleMeta)>
  getSalesOverviewForRange(String range) {
    final now = DateTime.now();
    List<BarChartGroupData> groups = [];
    Widget Function(double, TitleMeta) bottomTitles = (v, m) => Container();
    final settledBills = boxEntityOrder
        .query(EntityOrder_.status.equals('settled', caseSensitive: false))
        .build()
        .find();

    switch (range) {
      case 'Weekly':
        final List<double> dailySales = List.filled(7, 0.0);
        for (int i = 0; i < 7; i++) {
          final day = now.subtract(Duration(days: 6 - i));
          final dayStart = DateTime(day.year, day.month, day.day);
          final dayEnd = dayStart.add(const Duration(days: 1));

          final sales = settledBills
              .where((b) {
                final ts = _resolveSettledOrCreatedTime(b);
                return !ts.isBefore(dayStart) && ts.isBefore(dayEnd);
              })
              .fold(0.0, (prev, b) => prev + (b.totalAmount ?? 0.0));
          dailySales[i] = sales;
        }
        groups = List.generate(7, (i) => makeGroupData(i, dailySales[i]));
        bottomTitles = (value, meta) {
          final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          final day = now.subtract(Duration(days: 6 - value.toInt())).weekday;
          return Text(
            days[day - 1],
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          );
        };
        break;
      // Add other cases ('Monthly', 'Yearly') here if needed
      default: // Today
        final List<double> hourlySales = List.filled(24, 0.0);
        final todayStart = DateTime(now.year, now.month, now.day);
        final bills = settledBills.where((b) {
          final ts = _resolveSettledOrCreatedTime(b);
          return !ts.isBefore(todayStart) &&
              ts.isBefore(todayStart.add(const Duration(days: 1)));
        }).toList();

        for (var b in bills) {
          final hour = _resolveSettledOrCreatedTime(b).hour;
          hourlySales[hour] += b.totalAmount ?? 0.0;
        }
        groups = List.generate(6, (i) {
          double blockTotal = 0.0;
          for (int j = 0; j < 4; j++) {
            blockTotal += hourlySales[i * 4 + j];
          }
          return makeGroupData(i, blockTotal);
        });
        bottomTitles = (value, meta) {
          final periods = ['12-4a', '4-8a', '8-12p', '12-4p', '4-8p', '8-12a'];
          return Text(
            periods[value.toInt()],
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          );
        };
        break;
    }
    return Tuple2(groups, bottomTitles);
  }

  BarChartGroupData makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: const Color(0xFFB999EC),
          width: 15,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }
  // === DATA NORMALIZATION & EXTRACTION (CLASS-LEVEL HELPERS) ===

  DateTime? _parseDateLoose(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  DateTime _resolveSettledOrCreatedTime(EntityOrder b) {
    DateTime? ts;
    try {
      final dyn = b as dynamic;
      ts =
          _parseDateLoose(dyn.settledOn) ??
          _parseDateLoose(dyn.closedOn) ??
          _parseDateLoose(dyn.endTime);
    } catch (_) {}
    ts ??= _parseDateLoose(b.createdOn ?? b.startTime) ?? DateTime.now();
    return ts;
  }

  String _normalizeOrderType(String raw) {
    String t = raw.toLowerCase();

    // Try to resolve ID to label if ControllerOrderType is available
    if (Get.isRegistered<ControllerOrderType>()) {
      final otCtrl = Get.find<ControllerOrderType>();
      final label = otCtrl.getLabelById(raw);
      if (label != 'Unknown') {
        t = label.toLowerCase();
      }
    }

    if (t.contains('dine')) return 'Dine-In';
    if (t.contains('take')) return 'Takeaway';
    if (t.contains('deliv')) return 'Delivery';
    if (t.contains('online')) return 'Online';
    return 'Other';
  }

  String _normalizePaymentMode(String raw) {
    final t = raw.toLowerCase().trim();
    bool has(List<String> keys) => keys.any((k) => t.contains(k));

    if (has(['cash', 'cod', 'cash on delivery']))
      return PaymentMethod.cash.label;

    // GOOGLE PAY (SEPARATE)
    if (has(['googlepay', 'google pay', 'gpay']))
      return PaymentMethod.googlePay.label;

    // PHONEPE (SEPARATE OPTIONAL - If you want separate)
    if (has(['phonepe'])) return 'PhonePe';

    // UPI GENERIC (BHIM, QR, etc.)
    if (has(['upi', 'bhim', 'qr'])) return PaymentMethod.upi.label;

    if (has(['paytm'])) return PaymentMethod.paytm.label;

    if (has(['card', 'debit', 'credit', 'visa', 'master', 'rupay', 'pos']))
      return PaymentMethod.card.label;

    if (has(['wallet', 'amazon', 'mobikwik', 'freecharge']))
      return PaymentMethod.freecharge.label;

    if (has(['bank', 'neft', 'rtgs', 'imps', 'transfer']))
      return 'Bank Transfer';

    if (has(['voucher', 'coupon', 'gift'])) return 'Voucher';

    if (has(['online', 'razorpay', 'stripe', 'payu', 'paypal']))
      return PaymentMethod.other.label;

    return raw.trim().isEmpty
        ? PaymentMethod.other.label
        : raw.trim()[0].toUpperCase() + raw.trim().substring(1);
  }

  // Try best-effort single mode extraction if no splits are present
  String _extractPaymentMode(EntityOrder b) {
    // 1) From relation payments (if only one unique mode)
    try {
      final pmts = b.payments;
      if (pmts.isNotEmpty) {
        final modes = <String>{};
        for (final p in pmts) {
          String rawMode = '';
          try {
            final dyn = p as dynamic;
            rawMode = (dyn.mode ?? dyn.paymentMode ?? dyn.type ?? '')
                .toString();
          } catch (_) {}
          if (rawMode.trim().isNotEmpty) {
            modes.add(_normalizePaymentMode(rawMode));
          }
        }
        if (modes.length == 1) return modes.first;
      }
    } catch (_) {}

    // 2) Direct fields on order
    try {
      final dyn = b as dynamic;
      final candidates = [
        dyn.paymentMode,
        dyn.payment_mode,
        dyn.mode,
        dyn.payMode,
        dyn.pay_mode,
        dyn.paymentType,
        dyn.payment_type,
        dyn.type,
      ];
      for (final c in candidates) {
        if (c != null && c.toString().trim().isNotEmpty) {
          return _normalizePaymentMode(c.toString());
        }
      }
    } catch (_) {}

    // 3) From itemsJson meta
    try {
      final jsonString = (b as dynamic).itemsJson as String?;
      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString);
        if (data is Map<String, dynamic>) {
          final meta = data['meta'];
          if (meta is Map<String, dynamic>) {
            final single = (meta['paymentMode'] ?? meta['mode'])?.toString();
            if (single != null && single.trim().isNotEmpty) {
              return _normalizePaymentMode(single);
            }
            final pmts =
                meta['payments'] ??
                meta['paymentSplit'] ??
                meta['splitPayments'];
            if (pmts is List && pmts.length == 1) {
              final p = pmts.first;
              if (p is Map) {
                final m = (p['mode'] ?? p['type'] ?? p['paymentMode'] ?? '')
                    .toString();
                if (m.trim().isNotEmpty) return _normalizePaymentMode(m);
              }
            }
          }
        }
      }
    } catch (_) {}

    return 'Others';
  }

  // Unified split extractor used everywhere (including charts)
  Map<String, double> _extractPaymentSplits(EntityOrder b) {
    final Map<String, double> splits = {};

    // 1) Relation: b.payments
    try {
      final pmts = b.payments;
      if (pmts.isNotEmpty) {
        double sumWithAmt = 0.0;
        final List<String> modesWithoutAmt = [];

        for (final p in pmts) {
          String rawMode = '';
          double pAmt = 0.0;

          try {
            final dyn = p as dynamic;
            rawMode = (dyn.mode ?? dyn.paymentMode ?? dyn.type ?? '')
                .toString();

            final anyAmt =
                (dyn.amount ??
                dyn.amt ??
                dyn.value ??
                dyn.paid ??
                dyn.received);
            if (anyAmt is num) pAmt = anyAmt.toDouble();
          } catch (_) {}

          final mode = _normalizePaymentMode(
            rawMode.isEmpty ? 'Others' : rawMode,
          );

          if (pAmt > 0) {
            splits[mode] = (splits[mode] ?? 0.0) + pAmt;
            sumWithAmt += pAmt;
          } else {
            modesWithoutAmt.add(mode);
          }
        }

        // If we got some amounts, and there are also modes without amounts, spread the remaining
        final total = (b.totalAmount ?? 0.0);
        if (sumWithAmt > 0) {
          final remaining = (total - sumWithAmt);
          if (remaining > 0 && modesWithoutAmt.isNotEmpty) {
            final per = remaining / modesWithoutAmt.length;
            for (final m in modesWithoutAmt) {
              splits[m] = (splits[m] ?? 0.0) + per;
            }
          }
          // Return whatever we have (with or without remainder distribution)
          if (splits.isNotEmpty) return splits;
        }

        // No amounts provided at all but there are modes -> equal split of total
        if (sumWithAmt == 0 && modesWithoutAmt.isNotEmpty && total > 0) {
          final per = total / modesWithoutAmt.length;
          for (final mode in modesWithoutAmt) {
            splits[mode] = (splits[mode] ?? 0.0) + per;
          }
          return splits;
        }
      }
    } catch (_) {}

    // 2) itemsJson.meta.* payments array
    try {
      final jsonString = (b as dynamic).itemsJson as String?;
      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString);
        if (data is Map<String, dynamic>) {
          final meta = data['meta'];
          if (meta is Map<String, dynamic>) {
            final pmts =
                meta['payments'] ??
                meta['paymentSplit'] ??
                meta['splitPayments'];
            if (pmts is List) {
              double sum = 0.0;
              for (final p in pmts) {
                if (p is Map) {
                  final mode = _normalizePaymentMode(
                    (p['mode'] ?? p['type'] ?? p['paymentMode'] ?? 'Others')
                        .toString(),
                  );
                  final num? amount =
                      (p['amount'] ?? p['amt'] ?? p['value'] ?? p['paid'])
                          as num?;
                  final amt = amount?.toDouble() ?? 0.0;
                  if (amt > 0) {
                    splits[mode] = (splits[mode] ?? 0.0) + amt;
                    sum += amt;
                  }
                }
              }
              // If we captured any positive amounts, return them
              if (splits.isNotEmpty) {
                final total = (b.totalAmount ?? 0.0);
                final remaining =
                    total - splits.values.fold(0.0, (p, n) => p + n);
                // If meta only had modes but no amounts, split equally
                if (sum == 0 && pmts.isNotEmpty && total > 0) {
                  final per = total / pmts.length;
                  splits.clear();
                  for (final p in pmts) {
                    if (p is Map) {
                      final mode = _normalizePaymentMode(
                        (p['mode'] ?? p['type'] ?? p['paymentMode'] ?? 'Others')
                            .toString(),
                      );
                      splits[mode] = (splits[mode] ?? 0.0) + per;
                    }
                  }
                } else if (remaining > 0) {
                  // If we had partial sums, put the remainder into the first mode
                  final firstKey = splits.keys.isNotEmpty
                      ? splits.keys.first
                      : 'Others';
                  splits[firstKey] = (splits[firstKey] ?? 0.0) + remaining;
                }
                return splits;
              }
            }

            // Single mode in meta
            final single = (meta['paymentMode'] ?? meta['mode'])?.toString();
            if (single != null && single.trim().isNotEmpty) {
              final total = (b.totalAmount ?? 0.0);
              if (total > 0) {
                splits[_normalizePaymentMode(single)] = total;
                return splits;
              }
            }
          }
        }
      }
    } catch (_) {}

    // 3) Single-mode fallback
    final total = (b.totalAmount ?? 0.0);
    if (total > 0) {
      final singleMode = _extractPaymentMode(b);
      splits[_normalizePaymentMode(singleMode)] = total;
    }
    return splits;
  }

  // <-- FIX: This is now a reusable function that RETURNS data
  List<Map<String, dynamic>> _computeTopSellingFromBills(
    List<EntityOrder> bills,
  ) {
    final Map<String, Map<String, dynamic>> agg = {};

    for (final b in bills) {
      List<dynamic> items = [];
      try {
        final itemsJsonRaw = (b as dynamic).itemsJson as String?;
        if (itemsJsonRaw != null && itemsJsonRaw.isNotEmpty) {
          final parsed = jsonDecode(itemsJsonRaw);
          if (parsed is Map && parsed['items'] is List) {
            items = List<dynamic>.from(parsed['items']);
          } else if (parsed is List) {
            items = List<dynamic>.from(parsed);
          }
        }
      } catch (_) {}

      for (final it in items) {
        if (it is Map) {
          String name = (it['name'] ?? it['foodName'] ?? 'Unknown').toString();
          int qty = (it['qty'] as num?)?.toInt() ?? 0;
          if (name.trim().isNotEmpty && name != 'Unknown' && qty > 0) {
            agg.update(name, (existing) {
              existing['qty'] = (existing['qty'] as int) + qty;
              return existing;
            }, ifAbsent: () => {'name': name, 'qty': qty});
          }
        }
      }
    }

    final list = agg.values.toList();
    list.sort((a, b) => (b['qty'] as int).compareTo(a['qty'] as int));

    return list.take(topSellingLimit.value).toList();
  }

  // ---------------------------------------------------------------------------
  // NEW: Total Sales Chart Data (Reactive)
  // ---------------------------------------------------------------------------

  void _calculateSalesSpots() {
    final rangeStr = chartRange.value;
    final rangeInt = int.tryParse(rangeStr) ?? 7;
    salesSpots.value = salesLastNDays(rangeInt);
  }

  void _calculateYesterdaySales() {
    final now = DateTime.now();
    final yesterdayStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));
    final yesterdayEnd = DateTime(now.year, now.month, now.day);

    // Query only settled bills in range
    final settled = boxEntityOrder
        .query(EntityOrder_.status.equals('settled', caseSensitive: false))
        .build()
        .find();

    double total = 0.0;
    for (final b in settled) {
      final created = _resolveSettledOrCreatedTime(b);
      if (!created.isBefore(yesterdayStart) && created.isBefore(yesterdayEnd)) {
        total += b.totalAmount ?? 0.0;
      }
    }
    yesterdaySalesTotal.value = total;
  }

  // ---------------------------------------------------------------------------
  // NEW: Overview Chart Data (Optimized)
  // ---------------------------------------------------------------------------
  final RxList<Map<String, dynamic>> overviewChartData =
      <Map<String, dynamic>>[].obs;

  void _calculateOverviewData() {
    final now = DateTime.now();

    // Fetch settled and cancelled bills ONCE
    final settledBills = boxEntityOrder
        .query(EntityOrder_.status.equals('settled', caseSensitive: false))
        .build()
        .find();

    final cancelledBills = boxEntityOrder
        .query(
          EntityOrder_.status
              .equals('cancelled', caseSensitive: false)
              .or(EntityOrder_.status.equals('canceled', caseSensitive: false))
              .or(EntityOrder_.status.equals('cancel', caseSensitive: false)),
        )
        .build()
        .find();

    final List<Map<String, dynamic>> data = [];

    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: 6 - i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final sales = settledBills
          .where((b) {
            final ts = resolveOrderTime(b);
            return !ts.isBefore(dayStart) && ts.isBefore(dayEnd);
          })
          .fold(0.0, (p, b) => p + (b.totalAmount ?? 0.0));

      final cancelled = cancelledBills
          .where((b) {
            final ts = resolveOrderTime(b);
            return !ts.isBefore(dayStart) && ts.isBefore(dayEnd);
          })
          .fold(0.0, (p, b) => p + (b.totalAmount ?? 0.0));

      data.add({
        'day': [
          'Mon',
          'Tue',
          'Wed',
          'Thu',
          'Fri',
          'Sat',
          'Sun',
        ][day.weekday - 1],
        'sales': sales,
        'cancel': cancelled,
      });
    }

    overviewChartData.value = data;
  }

  @override
  void onInit() {
    super.onInit();
    // Get the AuthService instance
    final AuthService authService = Get.find();

    // Now you can use the name directly!
    print(authService.restaurantName);
    print(authService.address);
    _recalculateAll();

    // Watch ObjectBox for any changes (insertion/update/delete)
    try {
      boxEntityOrder.query().watch(triggerImmediately: true).listen((_) {
        _recalculateAll();
      });
    } catch (e) {
      if (kDebugMode) {
        print('ObjectBox watch error: $e');
      }
    }

    // Update sales chart when range changes
    ever(chartRange, (_) => _calculateSalesSpots());

    // Listen to order type changes to refresh stats if labels load late
    if (Get.isRegistered<ControllerOrderType>()) {
      final otCtrl = Get.find<ControllerOrderType>();
      ever(otCtrl.rxOrderTypes, (_) {
        _recalculateAll();
      });
    }
  }

  // Prefer created/start time
  DateTime _resolveCreatedTime(EntityOrder b) {
    return _parseDateLoose(b.createdOn ?? b.startTime) ?? DateTime.now();
  }

  // Returns grouped totals for order types (Dine-In, Takeaway, Delivery, Online, Other)
  Map<String, double> getOrderTypeTotals() {
    final Map<String, double> totals = {
      "Dine-In": 0.0,
      "Takeaway": 0.0,
      "Delivery": 0.0,
      "Online": 0.0,
      "Other": 0.0,
    };

    // Fetch all settled orders
    final settledBills = boxEntityOrder
        .query(EntityOrder_.status.equals('settled', caseSensitive: false))
        .build()
        .find();

    // Access ControllerOrderType to resolve IDs -> Labels
    final otCtrl = Get.isRegistered<ControllerOrderType>()
        ? Get.find<ControllerOrderType>()
        : null;

    for (final b in settledBills) {
      String rawType = b.orderTypeId ?? '';
      // Try to resolve ID to label (e.g. "60d5..." -> "Dine In")
      if (otCtrl != null) {
        final resolved = otCtrl.getLabelById(rawType);
        if (resolved != 'Unknown') {
          rawType = resolved;
        }
      }

      final type = rawType.toLowerCase();
      final amount = b.totalAmount ?? 0.0;

      if (type.contains('dine')) {
        totals["Dine-In"] = (totals["Dine-In"] ?? 0) + amount;
      } else if (type.contains('take')) {
        totals["Takeaway"] = (totals["Takeaway"] ?? 0) + amount;
      } else if (type.contains('deliv')) {
        totals["Delivery"] = (totals["Delivery"] ?? 0) + amount;
      } else if (type.contains('online')) {
        totals["Online"] = (totals["Online"] ?? 0) + amount;
      } else {
        totals["Other"] = (totals["Other"] ?? 0) + amount;
      }
    }

    return totals;
  }

  // Cashflow per day for range — only SETTLED orders
  Map<String, Map<String, double>> getCashflowForRange(String range) {
    final Map<String, Map<String, double>> data = {};
    final now = DateTime.now();

    final settled = boxEntityOrder
        .query(EntityOrder_.status.equals('settled', caseSensitive: false))
        .build()
        .find();

    DateTime start;
    int days;
    switch (range) {
      case 'Daily':
        start = DateTime(now.year, now.month, now.day);
        days = 1;
        break;
      case 'Weekly':
        start = now.subtract(const Duration(days: 6));
        days = 7;
        break;
      case 'Monthly':
        start = now.subtract(const Duration(days: 29));
        days = 30;
        break;
      case 'Yearly':
        start = now.subtract(const Duration(days: 364));
        days = 365;
        break;
      default:
        start = DateTime(now.year, now.month, now.day);
        days = 1;
    }

    for (int i = 0; i < days; i++) {
      final day = start.add(Duration(days: i));
      final key = "${day.month}/${day.day}";

      double inflow = 0.0;
      double outflow = 0.0;

      for (final b in settled) {
        final ts = _resolveSettledOrCreatedTime(b);
        if (ts.year == day.year && ts.month == day.month && ts.day == day.day) {
          final amt = (b.totalAmount ?? 0.0);
          if (amt >= 0) {
            inflow += amt;
          } else {
            outflow += amt.abs();
          }
        }
      }

      data[key] = {"inflow": inflow, "outflow": outflow};
    }

    return data;
  }

  // Range utility for external components
  List<FlSpot> salesForRange(String range) {
    switch (range) {
      case 'Today':
        return salesLast24Hours();
      case 'Weekly':
        return salesLastNDays(7);
      case 'Monthly':
        return salesLastNDays(30);
      case 'Yearly':
        return salesLastNDays(365);
      default:
        return salesLast24Hours();
    }
  }

  // === Online card range state + helpers ===
  final RxString onlineRange = 'Today'.obs;

  final RxString selectedRange = 'Today'.obs; // Was onlineRange
  DateTime _startForRange(String range) {
    final now = DateTime.now();
    switch (range) {
      case 'Today':
        return DateTime(now.year, now.month, now.day);
      case 'Weekly':
        return now.subtract(const Duration(days: 6)); // last 7 days incl today
      case 'Monthly':
        return now.subtract(const Duration(days: 29)); // last 30 days
      case 'Yearly':
        return now.subtract(const Duration(days: 364)); // last 365 days
      default:
        return DateTime(now.year, now.month, now.day);
    }
  }

  double totalAmountForRange(String range) {
    final start = _startForRange(range);
    final now = DateTime.now();
    final allBills = boxEntityOrder
        .query(EntityOrder_.status.equals(BillStatus.settled.value))
        .build()
        .find();

    double total = 0.0;
    for (final b in allBills) {
      final ts = _resolveSettledOrCreatedTime(b);
      // Check if the order is within the selected date range
      if (!ts.isBefore(start) && !ts.isAfter(now)) {
        total += (b.totalAmount ?? 0.0);
      }
    }
    return total;
  }

  int totalCountForRange(String range) {
    final start = _startForRange(range);
    final now = DateTime.now();
    final allBills = boxEntityOrder
        .query(EntityOrder_.status.equals(BillStatus.settled.value))
        .build()
        .find();

    int count = 0;
    for (final b in allBills) {
      final ts = _resolveSettledOrCreatedTime(b);
      // Check if the order is within the selected date range
      if (!ts.isBefore(start) && !ts.isAfter(now)) {
        count++;
      }
    }
    return count;
  }

  // Total amount for a given order type within a range (SETTLED only)
  double orderTypeTotalForRange(String type, String range) {
    final start = _startForRange(range); // Use the centralized helper
    final now = DateTime.now();
    final allBills = boxEntityOrder
        .query(EntityOrder_.status.equals(BillStatus.settled.value))
        .build()
        .find();

    double total = 0.0;
    for (final b in allBills) {
      final ts = _resolveSettledOrCreatedTime(b);
      if (!ts.isBefore(start) && !ts.isAfter(now)) {
        final normType = _normalizeOrderType(b.orderTypeId ?? '');
        if (normType == type) {
          total += (b.totalAmount ?? 0.0);
        }
      }
    }
    return total;
  }

  // Order count for a given order type within a range (SETTLED only)
  int orderTypeCountForRange(String type, String range) {
    final start = _startForRange(range); // Use the centralized helper
    final now = DateTime.now();
    final allBills = boxEntityOrder
        .query(EntityOrder_.status.equals(BillStatus.settled.value))
        .build()
        .find();

    int count = 0;
    for (final b in allBills) {
      final ts = _resolveSettledOrCreatedTime(b);
      if (!ts.isBefore(start) && !ts.isAfter(now)) {
        final normType = _normalizeOrderType(b.orderTypeId ?? '');
        if (normType == type) count++;
      }
    }
    return count;
  }

  void _recalculateAll() {
    _calculateSalesSpots();
    _calculateYesterdaySales();
    final all = boxEntityOrder.getAll();

    // Recent orders (for display)
    recentOrders.value = all.reversed.take(10).toList();

    // Time ranges
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);
    final yearStart = DateTime(now.year, 1, 1);
    final last24hStart = now.subtract(const Duration(hours: 24));
    final hourlyChartStart = now.subtract(const Duration(hours: 23));

    // Reset metrics
    double tToday = 0.0, tMonth = 0.0, tYear = 0.0;
    int oToday = 0, oWeek = 0, oMonth = 0;
    double totalAllOrders = 0.0;
    int totalOrdersCount = 0;

    final Map<String, int> counts = {};
    final Map<String, int> payCounts = {};
    final Map<String, double> payAmounts = {};

    final Set<String> customerSet = {};
    final Set<String> customerSet24h = {};

    final hourlyAmountsData = List<double>.filled(24, 0.0);
    final hourlyCountsData = List<int>.filled(24, 0);

    for (final b in all) {
      final status = (b.status ?? '').toLowerCase();
      final ts = _resolveSettledOrCreatedTime(b);
      final amount = (b.totalAmount ?? 0.0);

      // ✅ Ignore orders that were never settled
      if (!status.contains('settled') && !status.contains('cancel')) continue;

      // Track customers
      final cust = (b.customerName ?? b.userName?.toString() ?? "unknown")
          .trim();
      if (cust.isNotEmpty) {
        customerSet.add(cust);
        final created = _resolveCreatedTime(b);
        if (!created.isBefore(last24hStart)) customerSet24h.add(cust);
      }

      // Calculate totals
      if (ts.year == now.year) {
        tYear += amount;
        if (ts.month == now.month) {
          tMonth += amount;
          oMonth++;
          if (ts.day == now.day) {
            tToday += amount;
            oToday++;
          }
        }
      }

      // Week
      if (!ts.isBefore(weekStart)) {
        oWeek++;
      }

      totalAllOrders += amount;
      totalOrdersCount++;
    }

    // Update observables
    totalToday.value = tToday;
    totalMonth.value = tMonth;
    totalYear.value = tYear;
    ordersToday.value = oToday;
    ordersWeek.value = oWeek;
    ordersMonth.value = oMonth;

    uniqueCustomers.value = customerSet.length;
    activeUsers24h.value = customerSet24h.length;
    avgOrderValue.value = totalOrdersCount > 0
        ? totalAllOrders / totalOrdersCount
        : 0.0;
  }

  // Sales series for last N days (only SETTLED)
  List<FlSpot> salesLastNDays(int n) {
    final now = DateTime.now();
    final List<FlSpot> spots = [];
    final allBills = boxEntityOrder.getAll();

    for (int i = 0; i < n; i++) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: n - 1 - i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final daySales = allBills
          .where((b) {
            if (b.status != BillStatus.settled.value) return false;
            final ts = _resolveSettledOrCreatedTime(b);
            return !ts.isBefore(dayStart) && ts.isBefore(dayEnd);
          })
          .fold<double>(0.0, (prev, b) => prev + (b.totalAmount ?? 0.0));

      spots.add(FlSpot(i.toDouble(), daySales));
    }
    return spots;
  }

  // Last 24 hours sales (hourly) — already from settled in _recalculateAll
  List<FlSpot> salesLast24Hours() => hourlySpotsAmount;

  // Pie by order type counts
  List<PieChartSectionData> pieSections() {
    final total = orderTypeCounts.values.fold<int>(0, (p, n) => p + n);
    if (total == 0) {
      return [PieChartSectionData(value: 1, title: '')];
    }
    final sections = <PieChartSectionData>[];
    final colors = [
      const Color(0xFF33A2E4),
      const Color(0xFFFFA500),
      const Color(0xFF0CB477),
      const Color(0xFF6B4EFF),
      const Color(0xFFE53935),
      const Color(0xFF00BFA6),
      const Color(0xFFFFD54F),
    ];
    int i = 0;
    orderTypeCounts.forEach((k, v) {
      final pct = (v / total) * 100;
      sections.add(
        PieChartSectionData(
          value: v.toDouble(),
          title: '${pct.toStringAsFixed(0)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          color: colors[i % colors.length],
        ),
      );
      i++;
    });
    return sections;
  }

  // Pie by payment mode counts
  List<PieChartSectionData> pieSectionsPayment() {
    final total = paymentModeCounts.values.fold<int>(0, (p, n) => p + n);
    if (total == 0) {
      return [PieChartSectionData(value: 1, title: '')];
    }
    final sections = <PieChartSectionData>[];
    final colors = [
      const Color(0xFF0CB477), // cash
      const Color(0xFF3F51B5), // online / card
      const Color(0xFF9E9E9E), // others
      const Color(0xFFFFA726),
      const Color(0xFFAB47BC),
    ];
    int i = 0;
    paymentModeCounts.forEach((k, v) {
      final pct = (v / total) * 100;
      sections.add(
        PieChartSectionData(
          value: v.toDouble(),
          title: '${pct.toStringAsFixed(0)}%',
          radius: 48,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          color: colors[i % colors.length],
        ),
      );
      i++;
    });
    return sections;
  }
}
