// ignore_for_file: constant_identifier_names, prefer_null_aware_operators, curly_braces_in_flow_control_structures

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/captain/login/auth_service.dart';
import 'package:splash_screen_03/constant/api_constant.dart';
import 'package:splash_screen_03/kds/fragment/controller_kds.dart';
import 'package:splash_screen_03/model/entity_bill.dart';
import 'package:splash_screen_03/model/entity_cateogry_tax.dart';
import 'package:splash_screen_03/model/entity_food.dart';
import 'package:splash_screen_03/model/entity_kot.dart';
import 'package:splash_screen_03/model/entity_payment.dart';
import 'package:splash_screen_03/model/entity_bill_food.dart';
import 'package:splash_screen_03/model/entity_table.dart';
import 'package:splash_screen_03/model/entity_user.dart';
import 'package:splash_screen_03/model/enum_bill_status.dart';
import 'package:splash_screen_03/repository/Base64.dart';

import 'package:splash_screen_03/screens/home/fragments/order/controller_ordetype.dart';
import 'package:splash_screen_03/screens/home/fragments/order/widget/payment_dialog.dart';
import 'package:splash_screen_03/screens/home/fragments/receipt/controller_receipt.dart';
import 'package:splash_screen_03/screens/home/fragments/receipt/fragments/kot_reports/controller_kot_repoert.dart';
import 'package:splash_screen_03/screens/home/fragments/receipt/fragments/sales_reports/controller_sales.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/controller_setting.dart';
import 'package:splash_screen_03/screens/home/fragments/table_type/controller_table.dart';
import 'package:splash_screen_03/services/api_client.dart';
import 'package:splash_screen_03/services/controller_server.dart';
import 'package:splash_screen_03/services/session.dart';
import '../../../../captain/serverList/controller_server_selection.dart';
import '../../../../objectbox.g.dart';
import 'package:uuid/uuid.dart';

class KotUiItem {
  final int? id;
  final int foodId;
  final String name;
  final double price;
  int qty;
  final int kotNumber;
  final String uuid;

  // ✅ Add these optional fields
  final String? createdOn;
  final String? tableName;

  KotUiItem({
    this.id,
    required this.foodId,
    required this.name,
    required this.price,
    required this.qty,
    required this.kotNumber,
    required this.uuid,
    this.createdOn,
    this.tableName,
  });
}

class ControllerOrder extends GetxController {
  var rxOrderTypeId = "".obs; // store mongoId
  var rxOrderTypeLabel = "".obs; // only for UI display

  static const String ALL_ITEMS_UUID = "ALL";
  static const String ALL_ITEMS_NAME = "All Categories";
  bool isPrinting = false;
  final Uuid _uuidGen = const Uuid();
  final RxMap<String, String> itemNotes = <String, String>{}.obs;
  final RxBool isPrintingKot = false.obs;

  // Show actions only after at least one KOT exists for this table
  bool canShowBillActions([String? preferTable]) {
    final t = _resolveTableName(preferTable);

    if (t.isEmpty) return false;
    return hasServerKotForTable(t) ||
        hasUnsentItemsForTable(t); // MODIFIED: Show if local items exist too
  }

  String? _lastDineInTable;

  List<String> getUnsettledTableList() {
    final List<String> tables = [];
    final bills = boxEntityOrder
        .query(EntityOrder_.status.equals(BillStatus.booked.value))
        .build()
        .find();

    for (final b in bills) {
      final t = (b.tableName ?? "").trim();
      if (t.isNotEmpty) tables.add(t);
    }

    return tables;
  }

  // --- Selected waiter (for Service selection) ---
  final Rxn<EntityUser> selectedWaiter = Rxn<EntityUser>();
  String? _getRestaurantUuid() {
    try {
      final storage = StorageRepository();
      final rawJson = storage.restaurant;
      if (rawJson.isEmpty) return null;

      final decoded = jsonDecode(rawJson);
      if (decoded is Map && decoded['restUuid'] is String) {
        return decoded['restUuid'];
      }
    } catch (e) {
      debugPrint('⚠️ Failed to decode restaurant UUID: $e');
    }
    return null;
  }

  void setWaiter(EntityUser? user) {
    selectedWaiter.value = user;
    debugPrint("✅ Waiter set: ${user?.userName}");
  }

  void clearWaiter() {
    selectedWaiter.value = null;
  }

  // Replace your existing removeKotItem(...) with this implementation:
  Future<void> removeKotItem(dynamic serverItem) async {
    try {
      // If UI passed an ExtraItem (local/server unified model)
      final String itemName = (serverItem is ExtraItem)
          ? serverItem.name.trim()
          : (serverItem?.name ?? '').toString().trim();
      final int itemQty = (serverItem is ExtraItem)
          ? serverItem.qty
          : (serverItem?.qty ?? 0);
      final double itemPrice = (serverItem is ExtraItem)
          ? serverItem.price
          : (serverItem?.price ?? 0.0);

      // Resolve current table (prefer rxCurrentTable if set)
      final tableName = rxCurrentTable.value.trim();
      if (tableName.isEmpty) {
        debugPrint("removeKotItem: no current table selected.");
        return;
      }

      // Find the active/open bill for this table
      final bill = findLatestOpenBillForTable(tableName);
      if (bill == null) {
        debugPrint("removeKotItem: no open bill found for table '$tableName'.");
        return;
      }

      // Find a matching EntityOrderFood row in this bill.
      // Matching criteria: same name (trim), same qty, price approx equal.
      EntityOrderFood? found;
      for (final f in bill.listFood.toList()) {
        final fname = (f.name ?? '').trim();
        final fqty = (f.quantity ?? 0);
        final fprice = (f.price ?? 0.0);
        final priceDiff = (fprice - itemPrice).abs();

        if (fname == itemName && fqty == itemQty && priceDiff < 0.01) {
          found = f;
          break;
        }
      }

      if (found == null) {
        debugPrint(
          "removeKotItem: no matching persisted KOT row found for '$itemName' x$itemQty @ $itemPrice",
        );
        // Still try to remove local extra (if passed an ExtraItem in local bucket)
        if (serverItem is ExtraItem) {
          final bucket = _tableOrders[tableName];
          if (bucket != null) {
            final idx = bucket.extraItems.indexWhere(
              (e) =>
                  e.name.trim().toLowerCase() ==
                      serverItem.name.trim().toLowerCase() &&
                  e.price == serverItem.price &&
                  e.qty == serverItem.qty,
            );
            if (idx >= 0) {
              bucket.extraItems.removeAt(idx);
              rebuildUnifiedKotList(tableName: tableName);
              getTotalPrice(forTable: tableName);
              update();
              debugPrint(
                "removeKotItem: removed local extra item '${serverItem.name}' from bucket.",
              );
              return;
            }
          }
        }
        return;
      }

      // Remove from bill.listFood and DB
      final orderFoodId = found.orderId;
      try {
        bill.listFood.remove(found);
        bill.listFood.applyToDb();
        // Remove the row from the order-food box if we have a DB id
        if (orderFoodId != null) {
          try {
            boxEntityOrderFood.remove(orderFoodId);
          } catch (e) {
            debugPrint(
              "removeKotItem: failed to remove from boxEntityOrderFood: $e",
            );
          }
        }
        boxEntityOrder.put(bill);
        debugPrint(
          "removeKotItem: removed persisted KOT line '${found.name}' (orderFoodId=$orderFoodId) from bill ${bill.orderId}",
        );
      } catch (e, st) {
        debugPrint(
          "removeKotItem: error while removing persisted row: $e\n$st",
        );
      }

      // If you store itemsJson on the bill, rebuild it so history/export stays consistent
      try {
        final foods = bill.listFood.toList();
        final remainingItems = [
          for (final f in _itemsFromFoodsAggregated(foods))
            {
              'id': f.id ?? 0,
              'name': f.name,
              'qty': f.qty,
              'price': f.price,
              'amount': (f.price * f.qty),
            },
        ];

        final meta = (bill as dynamic).itemsJson != null
            ? _safeDecodeMap((bill as dynamic).itemsJson as String?)
            : <String, dynamic>{};
        final wrapper = {
          'meta': (meta['meta'] ?? <String, dynamic>{}),
          'items': remainingItems,
        };
        try {
          (bill as dynamic).itemsJson = jsonEncode(wrapper);
          boxEntityOrder.put(bill);
        } catch (_) {}
      } catch (_) {}

      // Refresh controller/UI state
      refreshKotItemsForTable(tableName, bill.orderId);
      rebuildUnifiedKotList(tableName: tableName);
      getTotalPrice(forTable: tableName);
      update();
    } catch (e, st) {
      debugPrint("removeKotItem failed: $e\n$st");
    }
  }

  // Add these reactive fields
  final rxCustomerName = ''.obs;
  final rxCustomerMobile = ''.obs;
  final rxCustomerAddress = ''.obs;

  void setCustomerDetails({String? name, String? mobile, String? address}) {
    if (name != null) rxCustomerName.value = name;
    if (mobile != null) rxCustomerMobile.value = mobile;
    if (address != null) rxCustomerAddress.value = address;
  }

  void saveCustomer({
    required String name,
    required String mobile,
    String? address,
  }) {
    // First, update reactive variables for immediate UI update
    setCustomerDetails(name: name, mobile: mobile, address: address);

    // Check if customer already exists in database
    final existing = getUserByMobile(mobile);

    if (existing != null) {
      // Update existing customer
      final nameParts = name.split(' ');
      existing.first = nameParts.isNotEmpty ? nameParts.first : name;
      existing.last = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';
      existing.userName = name;
      if (address != null && address.isNotEmpty) {
        existing.address = address;
      }
      boxEntityUser.put(existing);
      debugPrint('✅ Updated existing customer: $name ($mobile)');
    } else {
      // Create new customer
      final nameParts = name.split(' ');
      createUserFromDetails(
        mobile: mobile,
        first: nameParts.isNotEmpty ? nameParts.first : name,
        last: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
        address: address ?? '',
        userType: 'Customer',
      );
      debugPrint('✅ Created new customer: $name ($mobile)');
    }
  }

  bool isDraftSavedFor([String? preferTable]) {
    final t = _resolveTableName(preferTable);
    if (t.isEmpty) return false;

    final bill = findLatestOpenBillForTable(t);
    if (bill == null) return false;

    final wrap = bill.readItemsWrapper(); // your extension
    final meta = (wrap['meta'] as Map?) ?? {};
    return meta['draft'] == true;
  }

  // Quick bottom-sheet bill preview for a specific table
  Future<void> showBillPreview(
    BuildContext context, {
    String? tableName,
  }) async {
    final t = _resolveTableName(tableName);
    if (t.isEmpty) {
      Get.snackbar("Info", "No active table.");
      return;
    }

    // MODIFIED: Use unified list which includes local items
    rebuildUnifiedKotList(tableName: t);
    final items = kotUnifiedItems
        .map(
          (e) => {
            'name': e.name,
            'qty': e.qty,
            'price': e.price,
            'amount': e.price * e.qty,
          },
        )
        .toList();

    if (items.isEmpty) {
      Get.snackbar("Info", "No items to preview yet.");
      return;
    }

    final total = items.fold<double>(
      0.0,
      (s, m) => s + ((m['amount'] as num?)?.toDouble() ?? 0.0),
    );

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bill Preview • $t',
                style: Theme.of(
                  ctx,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final e = items[i];
                    final name = (e['name'] ?? '') as String;
                    final qty = (e['qty'] as num?)?.toInt() ?? 0;
                    final price = (e['price'] as num?)?.toDouble() ?? 0.0;
                    final amount =
                        (e['amount'] as num?)?.toDouble() ?? (price * qty);
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(name, overflow: TextOverflow.ellipsis),
                      subtitle: Text('x$qty @ ${price.toStringAsFixed(2)}'),
                      trailing: Text(
                        amount.toStringAsFixed(2),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    total.toStringAsFixed(2),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> showSettleDialog(
    BuildContext context, {
    String? tableName,
  }) async {
    final t = _resolveTableName(tableName);
    if (t.isEmpty) return;

    // make sure downstream eBill picks this table if coming from grid
    rxCurrentTable.value = t;

    String mode = 'Cash';
    final modes = ['Cash', 'UPI', 'Card'];
    final refCtrl = TextEditingController();
    bool printAfter = true;

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Settle Bill • $t',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: mode,
                    items: modes
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => setState(() => mode = v ?? mode),
                    decoration: const InputDecoration(
                      labelText: 'Payment Mode',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: refCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Reference/UTR (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: printAfter,
                    onChanged: (v) => setState(() => printAfter = v ?? true),
                    title: const Text('Print after settle'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Settle'),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await eBill(
                              null, // will use rxCurrentTable (we set it above)
                              mode,
                              referenceNo: refCtrl.text.trim().isEmpty
                                  ? null
                                  : refCtrl.text.trim(),
                              printAfterSettle: printAfter,
                              includeLocalCart:
                                  true, // Always include local cart on settle
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Box<EntityCategoryTax> boxEntityCategory = Get.find();
  Box<EntityFood> boxEntityFood = Get.find();

  // map tableName -> orderId (latest booked)
  final Map<String, int> tableBillMap = {};
  bool hasUnsentItemsForTable(String tableName) {
    final t = tableName.trim();
    if (t.isEmpty) return false;
    final data = _tableOrders[t];
    return (data?.orderItems.isNotEmpty ?? false) ||
        (data?.extraItems.isNotEmpty ?? false);
  }

  Future<void> sendKotFromGroup(KotGroup g) async {
    final table = (g.tableName ?? '').trim();
    if (table.isEmpty) return;

    final bill =
        getActiveBillForTableName(table) ??
        await getOrCreateOpenBillForTable(table);

    final itemsJson = jsonEncode({
      'items': g.items
          .map(
            (f) => {
              'id': f.foodId ?? 0,
              'name': f.name ?? '',
              'qty': f.quantity ?? 0,
              'price': f.price ?? 0.0,
              'amount': (f.price ?? 0.0) * (f.quantity ?? 0),
              if ((f.category ?? '').toLowerCase() == 'extras') 'extra': true,
            },
          )
          .toList(),
    });
    markLocalKotSent(table); // keep this

    await sendKotAndMarkTable(
      bill: bill,
      kotNumber: g.kotNumber,
      createdOn: g.createdOn ?? DateTime.now().toUtc().toIso8601String(),
      tableName: table,
      itemsJson: itemsJson,
    );

    // Mark local origin so next navigation opens Bill tab
  }

  String _currentOrigin() => Session.origin();

  var rxMasterCategoryList = <EntityCategoryTax>[].obs;
  var rxDisplayCategoryList = <EntityCategoryTax>[].obs;
  var rxMasterFoodList = <EntityFood>[].obs;
  var rxDisplayedFoodItems = <EntityFood>[].obs;
  Box<EntityOrder> boxEntityOrder = Get.find();
  Box<EntityOrderFood> boxEntityOrderFood = Get.find();
  Box<EntityUser> boxEntityUser = Get.find();
  Box<Payment> boxPayment = Get.find();

  final RxDouble rxGrandTotal = 0.0.obs;

  var selectedTempTable = Rxn<TempOrderTable>();
  var rxTempTables = <TempOrderTable>[].obs;

  final Map<String, TableOrderData> _tableOrders = {};
  RxList<KotUiItem> get rxKotItems =>
      _tableOrders[rxCurrentTable.value]?.kotItems ?? <KotUiItem>[].obs;

  final RxString rxCurrentTable = "".obs;

  RxMap<EntityFood, int> get rxOrderItems =>
      _tableOrders[rxCurrentTable.value]?.orderItems ?? <EntityFood, int>{}.obs;

  RxList<ExtraItem> get rxExtraItems =>
      _tableOrders[rxCurrentTable.value]?.extraItems ?? <ExtraItem>[].obs;

  void _ensureTableEntry(String key) {
    final t = key.trim();
    if (t.isEmpty) return;

    // ACCEPT ANY MODE AS VIRTUAL TABLE (Delivery, Quick Bill, Takeaway)
    if (!_tableOrders.containsKey(t)) {
      _tableOrders[t] = TableOrderData();
    }
  }

  String _kotFingerprint(TableOrderData data) {
    final buf = StringBuffer();

    // Normal foods (sort by foodId)
    final items = data.orderItems.entries.toList()
      ..sort((a, b) => (a.key.foodId ?? 0).compareTo(b.key.foodId ?? 0));
    for (final e in items) {
      final id = e.key.foodId ?? 0;
      final price = e.key.price.isNotEmpty
          ? (e.key.price.first.price ?? 0.0)
          : 0.0;
      buf.write('$id|${price.toStringAsFixed(2)}|${e.value};');
    }

    // Extras (sort by name, then price)
    final extras = data.extraItems.toList()
      ..sort((a, b) {
        final n = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        if (n != 0) return n;
        return a.price.compareTo(b.price);
      });
    for (final ex in extras) {
      buf.write(
        'ex:${ex.name.toLowerCase()}|${ex.price.toStringAsFixed(2)}|${ex.qty};',
      );
    }

    return buf.toString();
  }

  final RxMap<String, DateTime> _billPreparedAt = <String, DateTime>{}.obs;

  bool hasPreparedBill(String tableName) {
    if (tableName.isEmpty) return false;
    return _billPreparedAt.containsKey(tableName);
  }

  void markBillPrepared(String tableName) {
    if (tableName.isEmpty) return;
    _billPreparedAt[tableName] = DateTime.now();
  }

  void markBillDirty(String tableName) {
    if (tableName.isEmpty) return;
    _billPreparedAt.remove(tableName);
  }

  void markCurrentAsDirty() {
    final t = rxCurrentTable.value.trim();
    if (t.isNotEmpty) markBillDirty(t);
  }

  void loadTableOrders(String tableName) {
    rxCurrentTable.value = tableName;
    _ensureTableEntry(tableName);
    rebuildUnifiedKotList(tableName: tableName);
    update();
  }

  DateTime _ts(String? iso) {
    try {
      if (iso == null || iso.isEmpty)
        return DateTime.fromMillisecondsSinceEpoch(0);
      return DateTime.parse(iso);
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  bool hasBookedKotForTable(String? tableName) {
    final name = (tableName ?? '').trim();
    if (name.isEmpty) return false;
    final bill = findLatestOpenBillForTable(name);
    if (bill == null) return false;
    final kots = getKotsForActiveBillOfTable(name);
    return kots.isNotEmpty;
  }

  List<KotUiItem> _itemsFromFoods(List<EntityOrderFood> foods) {
    final items = <KotUiItem>[];
    for (final f in foods) {
      if ((f.quantity ?? 0) <= 0) continue;

      items.add(
        KotUiItem(
          id: f.orderId,
          foodId: f.foodId ?? 0,
          name: f.name ?? '',
          price: f.price ?? 0.0,
          qty: f.quantity ?? 0,
          kotNumber: f.kotNumber ?? 0,
          uuid: f.uuid ?? '',
        ),
      );
    }
    return items;
  }

  Future<void> attachPaymentsToBill(
    EntityOrder bill,
    List<Map<String, dynamic>> items,
    List<Payment> payments, {
    required String paymentLabel,
    String? overallReference,
    double tip = 0.0,
    String tipMode = 'Cash',
    double due = 0.0,
  }) async {
    if (payments.isEmpty && tip <= 0) return;

    // Save payment entries
    if (payments.isNotEmpty) boxPayment.putMany(payments);

    // Add tip as separate payment entry
    if (tip > 0) {
      final tipPay = Payment(
        price: tip,
        mode: tipMode,
        utr: overallReference,
        date: DateTime.now(),
      );
      boxPayment.put(tipPay);
      payments.add(tipPay);
    }

    final b = boxEntityOrder.get(bill.orderId) ?? bill;

    // ✅ FIX: Link payments to the bill relation
    b.payments.clear();
    b.payments.addAll(payments);

    // ---------- READ EXISTING META FROM BILL ----------
    Map<String, dynamic> existingMeta = {};
    try {
      final raw = (b as dynamic).itemsJson;
      if (raw != null && raw.toString().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map && decoded['meta'] is Map<String, dynamic>) {
          existingMeta = Map<String, dynamic>.from(decoded['meta']);
        }
      }
    } catch (e) {
      debugPrint("⚠️ Could not parse existing meta: $e");
    }

    // ---------- ORIGINAL TOTAL ----------
    final double originalTotal = items.fold<double>(
      0.0,
      (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0.0),
    );

    // ---------- DISCOUNT ----------
    final double billDiscountPercent =
        ((b as dynamic).discountPercent ?? 0.0) as double;

    double billDiscountAmount =
        ((b as dynamic).discountAmount ?? 0.0) as double;

    if (billDiscountPercent > 0 && billDiscountAmount <= 0) {
      billDiscountAmount = (billDiscountPercent / 100.0) * originalTotal;
      try {
        (b as dynamic).discountAmount = billDiscountAmount;
      } catch (_) {}
    }

    final double finalTotal = (originalTotal - billDiscountAmount).clamp(
      0.0,
      double.infinity,
    );

    // ---------- BUILD UPDATED META ----------
    final Map<String, dynamic> metaUpdate = {
      ...existingMeta,
      'paymentMode': paymentLabel,
      'referenceNo': overallReference,
      'dueAmount': due,
      'tipAmount': tip,
      'tipPaymentMode': tipMode,
      'payments': [
        for (final p in payments)
          {'mop': p.mode, 'amount': p.price, 'utr': p.utr},
      ],
      // totals
      'originalTotal': originalTotal,
      'discountPercent': billDiscountPercent,
      'discountAmount': billDiscountAmount,
      'finalTotal': finalTotal,
    };

    // ---------- WRITE BACK UPDATED WRAPPER ----------
    try {
      final newWrapper = {'meta': metaUpdate, 'items': items};
      (b as dynamic).itemsJson = jsonEncode(newWrapper);
    } catch (e) {
      debugPrint("⚠️ JSON build failed: $e");
    }

    // Save back to objectbox
    boxEntityOrder.put(b);

    final sum = payments.fold<double>(0.0, (s, p) => s + p.price);
    debugPrint(
      '💾 Payments linked → Bill #${b.orderNumber}'
      ' | amount=₹${sum.toStringAsFixed(2)}'
      ' | due=₹${due.toStringAsFixed(2)}'
      ' | tip=₹${tip.toStringAsFixed(2)}',
    );
  }

  // Merge orders from one table to another.
  // - Moves server KOT items from source open bill to destination open bill
  // - Optionally merges local (unsent) items too
  // - Closes the source bill (status -> settled) and clears source booking
  Future<void> mergeTables({
    required String from,
    required String into,
    bool moveLocal = true,
    bool printMergeKot = false,
  }) async {
    final src = from.trim();
    final dst = into.trim();
    if (src.isEmpty || dst.isEmpty || src.toLowerCase() == dst.toLowerCase()) {
      Get.snackbar("Merge", "Please choose two different tables.");
      return;
    }

    final tableController = Get.find<ControllerTable>();

    EntityOrder destBill =
        getActiveBillForTableName(dst) ??
        await getOrCreateOpenBillForTable(dst);

    final sourceBill = findLatestOpenBillForTable(src);
    if (sourceBill != null) {
      final foods = sourceBill.listFood.toList();
      if (foods.isNotEmpty) {
        for (final f in foods) {
          sourceBill.listFood.remove(f);
          f.orderId = destBill.orderId;
          f.tableName = dst;
          destBill.listFood.add(f);
        }
        sourceBill.listFood.applyToDb();
        destBill.listFood.applyToDb();
        boxEntityOrder.put(sourceBill);
        boxEntityOrder.put(destBill);
      }

      sourceBill.status = BillStatus.settled.value;
      sourceBill.endTime = DateTime.now().toIso8601String();
      boxEntityOrder.put(sourceBill);
    }

    if (moveLocal) {
      _mergeLocalBuckets(from: src, into: dst);
    }

    tableBillMap.remove(src);
    tableBillMap[dst] = destBill.orderId;

    tableController.clearBooked(src);
    tableController.markTableBooked(dst);

    // 4) Refresh KOT/UI/totals for destination
    refreshKotItemsForTable(dst, destBill.orderId);
    rebuildUnifiedKotList(tableName: dst);
    getTotalPrice(forTable: dst);
    update();

    // Optional: print any pending KOTs for destination after merge
    if (printMergeKot) {
      await printPendingKotsForTable(dst);
    }

    Get.snackbar("Merged", "Orders moved from $src to $dst.");
  }

  // Helper: merge local (unsent) buckets between tables
  void _mergeLocalBuckets({required String from, required String into}) {
    _ensureTableEntry(from);
    _ensureTableEntry(into);

    final src = _tableOrders[from]!;
    final dst = _tableOrders[into]!;

    // Merge normal items
    src.orderItems.forEach((food, qty) {
      dst.orderItems[food] = (dst.orderItems[food] ?? 0) + qty;
    });

    // Merge extras by (name + price)
    for (final ex in src.extraItems) {
      final idx = dst.extraItems.indexWhere(
        (e) =>
            e.name.trim().toLowerCase() == ex.name.trim().toLowerCase() &&
            e.price == ex.price,
      );
      if (idx >= 0) {
        dst.extraItems[idx].qty += ex.qty;
      } else {
        dst.extraItems.add(
          ExtraItem(id: ex.id, name: ex.name, price: ex.price, qty: ex.qty),
        );
      }
    }

    // Clear source local cart
    src.orderItems.clear();
    src.extraItems.clear();
  }

  Map<String, TableOrderData> get tableOrders => _tableOrders;
  // Pull server-KOT data for a table into reactive fields so UI can see it
  void ensureLoadedForTable(String tableName, {bool latestOnly = true}) {
    final t = tableName.trim();
    if (t.isEmpty) return;

    _ensureTableEntry(t);

    if (rxCurrentTable.value != t) {
      rxCurrentTable.value = t;
    }

    final bill = findLatestOpenBillForTable(t);
    if (bill != null) {
      // latestOnly keeps rxKotItems minimal; kotUnifiedItems is cumulative
      refreshKotItemsForTable(t, bill.orderId, latestOnly: latestOnly);
      rebuildUnifiedKotList(tableName: t);
    } else {
      rebuildUnifiedKotList(tableName: t); // Also run for local-only items
    }

    getTotalPrice(forTable: t); // also includes server KOT
    update();
  }

  bool hasServerKotForTable(String tableName) {
    final b = findLatestOpenBillForTable(tableName.trim());
    return b != null && b.listFood.isNotEmpty;
  }

  final kotUnifiedItems = <ExtraItem>[].obs;
  // In ControllerOrder.dart
  String _resolveTableName(String? prefer) {
    final p = (prefer ?? '').trim();
    if (p.isNotEmpty) return p;

    final cur = rxCurrentTable.value.trim();
    if (cur.isNotEmpty) return cur;

    try {
      final sel = Get.find<ControllerTable>().selectedTable.value;
      final sn = (sel?.tableName ?? '').trim();
      if (sn.isNotEmpty) return sn;
    } catch (_) {}

    return '';
  }

  double getTotalPrice({String? forTable}) {
    double total = 0.0;

    final table = _resolveTableName(forTable);
    if (table.isEmpty) {
      rxGrandTotal.value = 0;
      return 0;
    }

    // Ensure the data structure for the table exists
    _ensureTableEntry(table);
    final data = _tableOrders[table];

    // 1. Add total from the local, unsent cart
    if (data != null) {
      // Add items from the main order list
      data.orderItems.forEach((food, qty) {
        final price = food.price.isNotEmpty
            ? (food.price.first.price ?? 0.0)
            : 0.0;
        total += price * qty;
      });
      // Add items from the "extras" list
      for (final ex in data.extraItems) {
        total += ex.price * ex.qty;
      }
    }

    // 2. Add total from items already sent via KOT (from the database)
    // We get this from the one and only "latest open bill" for the table.
    // This is the single source of truth for persisted items.
    final bill = findLatestOpenBillForTable(table);
    if (bill != null && bill.listFood.isNotEmpty) {
      final serverItems = _itemsFromFoodsAggregated(bill.listFood.toList());
      for (final item in serverItems) {
        total += item.price * item.qty;
      }
    }

    // Update the reactive total and return it
    rxGrandTotal.value = total;
    return total;
  }
  // =========================================================================
  // BUG FIX END
  // =========================================================================

  Future<EntityOrder?> _waitForServerBillWithItems(
    String tableName, {
    int retries = 12,
    Duration interval = const Duration(milliseconds: 200),
  }) async {
    final t = tableName.trim();
    for (var i = 0; i < retries; i++) {
      final b = findLatestOpenBillForTable(t);
      if (b != null && b.listFood.isNotEmpty) return b;
      await Future.delayed(interval);
    }
    // One last try (may still be null/empty)
    return findLatestOpenBillForTable(t);
  }

  Map<String, List<MapEntry<dynamic, int>>> getBillGroupedItemsForTable(
    String tableName,
  ) {
    final t = tableName.trim();
    _ensureTableEntry(t);
    final data = _tableOrders[t]!;

    final Map<String, List<MapEntry<dynamic, int>>> grouped = {
      "Local": data.orderItems.entries.toList(),
      "Extras": data.extraItems.map((e) => MapEntry(e, e.qty)).toList(),
    };

    final bill = findLatestOpenBillForTable(t);
    if (bill != null) {
      final serverAgg = _itemsFromFoodsAggregated(bill.listFood.toList());
      grouped["Server KOT"] = serverAgg.map((e) => MapEntry(e, e.qty)).toList();
    }

    return grouped;
  }

  void refreshKotItemsForTable(
    String tableName,
    int? orderId, {
    bool latestOnly = true,
  }) {
    _ensureTableEntry(tableName);
    final data = _tableOrders[tableName]!;
    data.kotItems.clear();

    if (orderId == null) {
      update();
      return;
    }
    final bill = boxEntityOrder.get(orderId);
    if (bill == null) {
      update();
      return;
    }

    final foods = bill.listFood.toList();
    if (foods.isEmpty) {
      update();
      return;
    }

    if (latestOnly) {
      // Find the newest KOT group
      final groups = _groupFoodsByKot(foods);
      KotGroup? latest;
      DateTime latestTs = DateTime.fromMillisecondsSinceEpoch(0);
      int latestKn = -1;

      for (final g in groups) {
        final tsG = _ts(g.createdOn);
        if (latest == null ||
            tsG.isAfter(latestTs) ||
            (tsG.isAtSameMomentAs(latestTs) && g.kotNumber > latestKn)) {
          latest = g;
          latestTs = tsG;
          latestKn = g.kotNumber;
        }
      }

      final latestFoods = latest?.items ?? const <EntityOrderFood>[];
      data.kotItems.addAll(
        _itemsFromFoods(latestFoods),
      ); // NOT aggregated (show per line)
    } else {
      // Cumulative (all KOTs) — use only for bill totals/preview, not KOT tab
      data.kotItems.addAll(_itemsFromFoodsAggregated(foods));
    }

    update();
  }

  // Remember if we just sent a KOT from this device (Captain) per table.
  // Will be consumed on first navigation.
  final Map<String, DateTime> _recentLocalKot = {};
  static const Duration localKotWindow = Duration(seconds: 20);

  void markLocalKotSent(String tableName) {
    final t = tableName.trim();
    if (t.isEmpty) return;
    _recentLocalKot[t] = DateTime.now();
  }

  // Consume the flag: return true only once within the time window.
  bool _consumeLocalKotFlag(String tableName) {
    final t = tableName.trim();
    final ts = _recentLocalKot[t];
    if (ts == null) return false;
    final within = DateTime.now().difference(ts) <= localKotWindow;
    // Remove so it won’t force Bill next time.
    _recentLocalKot.remove(t);
    return within;
  }

  // Decide which tab to open.
  int initialTabIndexFor(String tableName) {
    final t = tableName.trim();
    if (t.isEmpty) return 0;

    if (hasUnsentItemsForTable(t)) return 1;

    if (_consumeLocalKotFlag(t)) return 1;

    if (hasServerKotForTable(t)) return 0;

    // Default -> KOT tab
    return 0;
  }

  // =========================================================================
  void rebuildUnifiedKotList({required String tableName}) {
    final t = tableName.trim();
    if (t.isEmpty) {
      kotUnifiedItems.clear();
      return;
    }

    // --- 1. Get items from the database (already sent KOTs) ---
    final activeBill = findLatestOpenBillForTable(t);
    final serverFoods = activeBill?.listFood.toList() ?? [];
    final serverItems = _itemsFromFoodsAggregated(serverFoods);

    // --- 2. Get items from the local cart (unsent) ---
    _ensureTableEntry(t);
    final data = _tableOrders[t];
    final localItems = <ExtraItem>[];

    if (data != null) {
      data.orderItems.forEach((food, qty) {
        localItems.add(
          ExtraItem(
            id: (food.foodId ?? 0).toString(),
            name: food.foodName ?? '',
            qty: qty,
            price: food.price.isNotEmpty
                ? (food.price.first.price ?? 0.0)
                : 0.0,
          ),
        );
      });
      localItems.addAll(data.extraItems);
    }
    // Convert all server KotUiItem(s) into ExtraItem(s)
    final List<ExtraItem> serverConverted = [
      for (final s in serverItems)
        ExtraItem(
          id: (s.id ?? 0).toString(),
          name: s.name,
          qty: s.qty,
          price: s.price,
        ),
    ];

    // Combine both lists now that both are ExtraItem type
    final allItems = [...serverConverted, ...localItems];
    final Map<String, ExtraItem> aggregatedMap = {};

    for (final item in allItems) {
      final key =
          '${item.id}|${item.price.toStringAsFixed(2)}|${item.name.toLowerCase()}';
      final existing = aggregatedMap[key];
      if (existing != null) {
        existing.qty += item.qty;
      } else {
        aggregatedMap[key] = item.copyWith();
      }
    }

    // Update observable list
    kotUnifiedItems.assignAll(aggregatedMap.values.toList());
    update();
  }
  // =========================================================================
  // FIX END
  // =========================================================================

  var selectedCategoryUuid = RxnString(ALL_ITEMS_UUID);
  late final ControllerSetting controllerSetting;
  final rxClientKotList = <KotGroup>[].obs; // now KotGroup not EntityKot

  void updateClientKotListFromFoods(List<EntityOrderFood> foods) {
    rxClientKotList.assignAll(_groupFoodsByKot(foods));
  }

  final RxBool rxBillSettled = false.obs;

  void loadPendingTableOrders() {
    _tableOrders.clear();

    final bookedBills = boxEntityOrder
        .getAll()
        .where((b) => b.status == BillStatus.booked.value)
        .toList();

    for (final bill in bookedBills) {
      final tableName = (bill.tableName ?? '').trim();
      if (tableName.isEmpty) continue;

      final data = TableOrderData();
      // DO NOT copy DB foods into local cart buckets!
      // Show DB foods via kotItems only. Keep orderItems/extraItems for unsent items.
      final foods = bill.listFood.toList();

      // Fix: Ignore bills that have no items (ghost bills)
      if (foods.isEmpty) continue;

      // Latest-only items for KOT tab
      final groups = _groupFoodsByKot(foods);
      groups.sort((a, b) => _ts(b.createdOn).compareTo(_ts(a.createdOn)));
      final latest = groups.isNotEmpty
          ? groups.first.items
          : <EntityOrderFood>[];
      data.kotItems.addAll(_itemsFromFoods(latest));

      _tableOrders[tableName] = data;

      try {
        Get.find<ControllerTable>().markTableBooked(tableName);
      } catch (_) {}
    }

    update();
  }

  void _seedCountersFromDbToSettings() {
    try {
      int maxOrder = 0;
      int maxKot = 0;

      final bills = boxEntityOrder.getAll();
      for (final b in bills) {
        maxOrder = math.max(maxOrder, (b.orderNumber ?? 0));
        for (final f in b.listFood.toList()) {
          maxKot = math.max(maxKot, (f.kotNumber ?? 0));
        }
      }

      if (Get.isRegistered<ControllerSetting>()) {
        Get.find<ControllerSetting>().bumpCountersToAtLeast(
          nextOrderNumber: (maxOrder > 0) ? maxOrder + 1 : null,
          nextKotNumber: (maxKot > 0) ? maxKot + 1 : null,
        );
      }
    } catch (_) {}
  }

  bool _wasLocalKotJustSent(String tableName) {
    final t = tableName.trim();
    final ts = _recentLocalKot[t];
    if (ts == null) return false;
    return DateTime.now().difference(ts) <= localKotWindow;
  }

  // Optional: detect if a server KOT belongs to this terminal (only if you store origin)
  bool hasKotFromThisTerminal(String tableName) {
    final t = tableName.trim();
    final bill = findLatestOpenBillForTable(t);
    if (bill == null) return false;

    try {
      final me = _currentOrigin().toLowerCase();
      for (final f in bill.listFood.toList()) {
        final d = f as dynamic;
        final origin =
            (d.origin ??
                    d.source ??
                    d.deviceId ??
                    d.terminal ??
                    d.createdBy ??
                    '')
                .toString()
                .toLowerCase();
        if (origin.isNotEmpty && (origin == me || origin.contains('captain'))) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  @override
  void onInit() {
    super.onInit();
    controllerSetting = Get.isRegistered<ControllerSetting>()
        ? Get.find<ControllerSetting>()
        : Get.put(ControllerSetting());

    _fetchCategoriesAndPrepareDisplayList();
    _fetchAllFoodItems();
    filterFoodItemsForSelectedCategory();

    rebuildTableBillMap();
    loadPendingTableOrders();

    // 👇 seed counters from DB snapshot
    _seedCountersFromDbToSettings();

    try {
      Get.find<ControllerTable>().refreshBookedFromBills();
    } catch (_) {}
  }

  void _debugTotalsForTable(String tableName) {
    final t = tableName.trim();
    final active = findLatestOpenBillForTable(t);
    final foodsCount = active?.listFood.length ?? 0;
    final data = _tableOrders[t];
    debugPrint(
      "TOT_DEBUG[$t] locals: ${data?.orderItems.length ?? 0} foods + ${data?.extraItems.length ?? 0} extras, "
      "rxKotItems(latest): ${data?.kotItems.length ?? 0}, "
      "kotUnified(all): ${kotUnifiedItems.length}, "
      "activeBillFoods: $foodsCount",
    );
  }

  String _generateUuid() => _uuidGen.v4();

  void _ensureBillHasUuid(EntityOrder bill) {
    try {
      final dynamic dyn = bill as dynamic;
      String? existing;
      try {
        existing = dyn.uuid as String?;
      } catch (_) {
        try {
          existing = dyn.billUuid as String?;
        } catch (_) {
          existing = null;
        }
      }
      if (existing == null || existing.isEmpty) {
        final newUuid = _generateUuid();
        try {
          dyn.uuid = newUuid;
        } catch (_) {
          try {
            dyn.billUuid = newUuid;
          } catch (_) {}
        }
        try {
          boxEntityOrder.put(bill);
        } catch (_) {}
        debugPrint("🆔 Assigned Bill UUID: $newUuid (orderId=${bill.orderId})");
      }
    } catch (e, st) {
      debugPrint("⚠ _ensureBillHasUuid failed: $e\n$st");
    }
  }

  String? _readBillUuid(EntityOrder bill) {
    try {
      final dynamic d = bill as dynamic;
      try {
        final v = d.uuid;
        if (v is String && v.isNotEmpty) return v;
      } catch (_) {}
      try {
        final v = d.billUuid;
        if (v is String && v.isNotEmpty) return v;
      } catch (_) {}
    } catch (_) {}
    return null;
  }

  RxList<EntityCategoryTax> get rxCategories => rxDisplayCategoryList;

  void _fetchCategoriesAndPrepareDisplayList() {
    rxMasterCategoryList.value = boxEntityCategory.getAll();

    final allCategory = EntityCategoryTax(categoryName: ALL_ITEMS_NAME);
    rxDisplayCategoryList.value = [allCategory, ...rxMasterCategoryList];
  }

  void refreshFoodList() {
    _fetchAllFoodItems();
    filterFoodItemsForSelectedCategory();
  }

  RxInt get totalItemsCount {
    int total = 0;
    rxOrderItems.forEach((_, qty) => total += qty);
    for (final ex in rxExtraItems) {
      total += ex.qty;
    }
    return total.obs;
  }

  String getCategoryNameByUuid(String? categoryUuid) {
    if (categoryUuid == null || categoryUuid.isEmpty) return "Others";
    if (categoryUuid.toUpperCase() == ALL_ITEMS_UUID) return ALL_ITEMS_NAME;
    final category = rxMasterCategoryList.firstWhereOrNull(
      (cat) => (cat.categoryName ?? '').trim() == categoryUuid.trim(),
    );
    return category?.categoryName?.toUpperCase() ?? "OTHERS";
  }

  Map<String, List<MapEntry<dynamic, int>>> getGroupedOrderItemsForKot({
    bool includeServerKot = false,
  }) {
    final Map<String, List<MapEntry<dynamic, int>>> grouped = {};
    grouped["Local"] = rxOrderItems.entries.toList();
    grouped["Extras"] = rxExtraItems.map((e) => MapEntry(e, e.qty)).toList();

    if (includeServerKot) {
      grouped["Server KOT"] = kotUnifiedItems
          .map((e) => MapEntry(e, e.qty))
          .toList();
    }
    return grouped;
  }

  var rxSearchQuery = "".obs;

  void searchFoodByName(String query) {
    rxSearchQuery.value = query.trim().toLowerCase();

    if (rxSearchQuery.value.isEmpty) {
      filterFoodItemsForSelectedCategory();
      return;
    }

    rxDisplayedFoodItems.value = rxMasterFoodList
        .where(
          (food) =>
              (food.foodName ?? "").toLowerCase().contains(rxSearchQuery.value),
        )
        .toList();
  }

  void _fetchAllFoodItems() {
    // Step 1: Load all foods from ObjectBox
    final foods = boxEntityFood.getAll();

    // Step 2: Force-load ToMany price relations
    for (final f in foods) {
      try {
        f.price.toList(); // important
      } catch (_) {}
    }

    // Step 3: Remove duplicate foods having ZERO price list
    for (final f in foods.toList()) {
      if (f.price.isEmpty) {
        boxEntityFood.remove(f.foodId); // delete bad entry
        foods.remove(f); // remove from memory list too
      }
    }

    // Step 4: Update the master reactive list
    rxMasterFoodList.value = foods;
  }

  void selectCategory(String? newSelected) {
    final s = (newSelected ?? ALL_ITEMS_UUID).trim();
    if (s.toUpperCase() == ALL_ITEMS_UUID ||
        s.toLowerCase() == ALL_ITEMS_NAME.toLowerCase()) {
      selectedCategoryUuid.value = ALL_ITEMS_UUID;
    } else {
      selectedCategoryUuid.value = s;
    }
    filterFoodItemsForSelectedCategory();
  }

  void filterFoodItemsForSelectedCategory() {
    final currentUuid = selectedCategoryUuid.value;
    if (currentUuid == ALL_ITEMS_UUID) {
      rxDisplayedFoodItems.value = List.from(rxMasterFoodList);
    } else {
      rxDisplayedFoodItems.value = rxMasterFoodList
          .where((food) => (food.categoryName ?? '').trim() == currentUuid)
          .toList();
    }
  }

  String getFoodPriceDisplay(EntityFood food) {
    if (food.price.isNotEmpty) {
      final firstPrice = food.price.first;
      String display =
          "${firstPrice.price?.toStringAsFixed(2) ?? 'N/A'} ${firstPrice.currency ?? ''}";
      if (firstPrice.roomType != null && firstPrice.roomType!.isNotEmpty) {
        display += " (${firstPrice.roomType})";
      }
      return display;
    }
    return "Price not set";
  }

  // In ControllerOrder class
  void resetFoodListOnOrderTypeChange() {
    rxSearchQuery.value = "";
    filterFoodItemsForSelectedCategory();
  }

  void addToOrder(EntityFood food) {
    rxBillSettled.value = false;

    final orderType = rxOrderType.value.trim();
    final String currentTableName = rxCurrentTable.value.trim();

    // 🔥 Allow Delivery / Takeaway / Quick Bill without table
    if (orderType == "Dine In" && currentTableName.isEmpty) {
      Get.snackbar(
        "Error",
        "Please select a table for Dine In.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final String tableKey = currentTableName.isEmpty
        ? orderType
        : currentTableName;

    rxCurrentTable.value = tableKey; // 🔥 FIX ADDED
    _ensureTableEntry(tableKey);
    final data = _tableOrders[tableKey]!;

    data.orderItems[food] = (data.orderItems[food] ?? 0) + 1;

    // Mark table booked only for dine-in
    if (orderType == "Dine In") {
      final tableController = Get.find<ControllerTable>();
      tableController.markTableBooked(tableKey);
    }

    rebuildUnifiedKotList(tableName: tableKey);
    update();
  }

  // UI pulse to force table/temps tiles to rebuild
  final RxInt tilesPulse = 0.obs;

  void refreshTiles() {
    tilesPulse.value++;
  }

  Future<EntityOrder?> saveBillOnly({
    EntityTable? table,
    String? paymentMode,
    String? customerName,
    String? customerMobile,
    String? customerAddress,
    bool printCopy = false,
  }) async {
    final String tName = (table?.tableName ?? rxCurrentTable.value).trim();
    if (tName.isEmpty) {
      Get.snackbar(
        "Select table",
        "Please select a table first.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }

    var bill = getActiveBillForTableName(tName);

    bill ??= await createBillWithoutOrderNumber(tName, table?.seats ?? 0);

    // If there are unsent items for THIS table, persist them as a KOT now
    final data = _tableOrders[tName];
    final hasLocal =
        (data?.orderItems.isNotEmpty ?? false) ||
        (data?.extraItems.isNotEmpty ?? false);

    if (hasLocal) {
      await saveOrder(tName, bill.tableSeat ?? 0, BillStatus.booked.value);
      bill = getActiveBillForTableName(tName) ?? bill; // refresh
    }

    // Build items for the bill from DB (cumulative KOT items)
    final items = getUnifiedBillItemsFromDb(bill);
    if (items.isEmpty) {
      Get.snackbar(
        "Info",
        "No items to save for this bill.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return bill;
    }

    // Keep bill OPEN (booked) — do NOT settle here
    bill.status = BillStatus.booked.value;
    final totalAmount = items.fold<double>(
      0.0,
      (s, m) => s + ((m['amount'] as num?)?.toDouble() ?? 0.0),
    );

    // ---- APPLY DISCOUNT (option A: use bill.discountAmount & bill.discountPercent) ----
    double discountAmount = (bill.discountAmount ?? 0.0);
    final double discountPercent = (bill.discountPercent ?? 0.0);

    // If percent set, compute and override discountAmount (percent takes precedence)
    if (discountPercent > 0) {
      discountAmount = (discountPercent / 100.0) * totalAmount;
      bill.discountAmount = discountAmount; // keep bill in sync
    }

    final double finalTotal = (totalAmount - discountAmount).clamp(
      0.0,
      double.infinity,
    );

    // Save final total and attach meta wrapper
    bill.totalAmount = finalTotal;

    try {
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final wrapper = {
        'meta': {
          'customerName': bill.customerName ?? '',
          'customerMobile': bill.customerMobile ?? '',
          'customerAddress': bill.customerAddress ?? '',
          'paymentMode': (paymentMode ?? '').trim(),
          'draft': true,
          'savedAt': nowIso,
          // Discount meta
          'originalTotal': totalAmount,
          'discountPercent': discountPercent,
          'discountAmount': discountAmount,
          'finalTotal': finalTotal,
        },
        'items': items,
      };
      (bill as dynamic).itemsJson = jsonEncode(wrapper);
      (bill as dynamic).orderItems = items;
      (bill as dynamic).totalQty = items.fold<int>(
        0,
        (p, e) => p + ((e['qty'] as int?) ?? 0),
      );
      (bill as dynamic).billDate = (bill as dynamic).billDate ?? nowIso;
      (bill as dynamic).createdAt = (bill as dynamic).createdAt ?? nowIso;
    } catch (_) {}

    bill.customerMobile = customerMobile ?? (bill.customerMobile ?? "");
    bill.customerAddress = customerAddress ?? (bill.customerAddress ?? "");

    // Save a “draft/preview” wrapper (still open)
    try {
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final wrapper = {
        'meta': {
          'customerName': bill.customerName ?? '',
          'customerMobile': bill.customerMobile ?? '',
          'customerAddress': bill.customerAddress ?? '',
          'paymentMode': (paymentMode ?? '').trim(),
          'draft': true,
          'savedAt': nowIso,
        },
        'items': items,
      };
      (bill as dynamic).itemsJson = jsonEncode(wrapper);
      (bill as dynamic).orderItems = items;
      (bill as dynamic).totalQty = items.fold<int>(
        0,
        (p, e) => p + ((e['qty'] as int?) ?? 0),
      );
      (bill as dynamic).billDate = (bill as dynamic).billDate ?? nowIso;
      (bill as dynamic).createdAt = (bill as dynamic).createdAt ?? nowIso;
    } catch (_) {}

    // Persist
    boxEntityOrder.put(bill);

    // Guarantee a bill (order) number if somehow missing
    if ((bill.orderNumber ?? 0) <= 0) {
      final nextNo = await controllerSetting.acquireNextorderNumber();
      bill.orderNumber = nextNo;
      boxEntityOrder.put(bill);
    }

    // Optional: print a copy (not a settle)
    if (printCopy) {
      await _tryPrintBill(bill, items);
    }

    // Refresh state for the table and UI
    rebuildUnifiedKotList(tableName: tName);
    refreshKotItemsForTable(tName, bill.orderId);
    getTotalPrice(forTable: tName);
    update();

    // NEW: refresh Receipts and Sales too (same as in eBill)
    await _refreshReceiptsAndSales();

    // Optional: ensure controller state reflects latest + update grid
    ensureLoadedForTable(tName, latestOnly: false);
    refreshTiles(); // recolor + Bill # chip immediately

    // Nice feedback
    Get.snackbar(
      "Bill Saved",
      "Bill #${bill.orderNumber} saved for $tName",
      snackPosition: SnackPosition.BOTTOM,
    );

    debugPrint(
      "📝 Bill saved (OPEN) for $tName, bill#${bill.orderNumber}, total=${totalAmount.toStringAsFixed(2)}",
    );
    return bill;
  }

  void increaseQuantity(EntityFood food) {
    _ensureTableEntry(rxCurrentTable.value);
    final data = _tableOrders[rxCurrentTable.value]!;
    if (data.orderItems.containsKey(food)) {
      data.orderItems[food] = data.orderItems[food]! + 1;
    }
    rebuildUnifiedKotList(
      tableName: rxCurrentTable.value,
    ); // FIX: Update unified view
    update();
  }

  void decreaseQuantity(EntityFood food) {
    _ensureTableEntry(rxCurrentTable.value);
    final data = _tableOrders[rxCurrentTable.value]!;
    if (data.orderItems.containsKey(food)) {
      if (data.orderItems[food]! > 1) {
        data.orderItems[food] = data.orderItems[food]! - 1;
      } else {
        data.orderItems.remove(food);
      }
    }
    rebuildUnifiedKotList(
      tableName: rxCurrentTable.value,
    ); // FIX: Update unified view
    update();
  }

  void addExtraItem({
    required String name,
    required double price,
    required int qty,
  }) {
    rxBillSettled.value = false;
    _ensureTableEntry(rxCurrentTable.value);
    final data = _tableOrders[rxCurrentTable.value]!;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final extra = ExtraItem(id: id, name: name.trim(), price: price, qty: qty);
    data.extraItems.add(extra);

    final tableController = Get.find<ControllerTable>();
    tableController.markTableBooked(rxCurrentTable.value);

    rebuildUnifiedKotList(
      tableName: rxCurrentTable.value,
    ); // FIX: Update unified view
    update();
  }

  void increaseExtraQty(String extraId) {
    _ensureTableEntry(rxCurrentTable.value);
    final data = _tableOrders[rxCurrentTable.value]!;
    final idx = data.extraItems.indexWhere((e) => e.id == extraId);
    if (idx >= 0) data.extraItems[idx].qty += 1;
    rebuildUnifiedKotList(
      tableName: rxCurrentTable.value,
    ); // FIX: Update unified view
    update();
  }

  void decreaseExtraQty(String extraId) {
    _ensureTableEntry(rxCurrentTable.value);
    final data = _tableOrders[rxCurrentTable.value]!;
    final idx = data.extraItems.indexWhere((e) => e.id == extraId);
    if (idx >= 0) {
      if (data.extraItems[idx].qty > 1) {
        data.extraItems[idx].qty -= 1;
      } else {
        data.extraItems.removeAt(idx);
      }
    }
    rebuildUnifiedKotList(
      tableName: rxCurrentTable.value,
    ); // FIX: Update unified view
    update();
  }

  Map<String, double> getSalesByOrderType({int lastNDays = 7}) {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: lastNDays));

    final Map<String, double> salesMap = {};

    final bills = boxEntityOrder.getAll().where((bill) {
      final created = bill.createdOn != null
          ? DateTime.tryParse(bill.createdOn!) ?? now
          : now;
      return created.isAfter(cutoff);
    });

    for (var bill in bills) {
      final type = bill.orderTypeId ?? "Unknown";
      final amount = bill.totalAmount ?? 0.0;
      salesMap[type] = (salesMap[type] ?? 0) + amount;
    }

    return salesMap;
  }

  void removeExtra(String extraId) {
    rxExtraItems.removeWhere((e) => e.id == extraId);
    rebuildUnifiedKotList(
      tableName: rxCurrentTable.value,
    ); // FIX: Update unified view
    update();
  }

  var rxOrderType = "Dine In".obs;

  final List<String> orderTypes = [
    "Dine In",
    "Quick Bill",
    "Delivery",
    "Pick Up",
    "Takeaway",
  ];

  bool _isVirtualMode(String key) {
    return key == "Quick Bill" || key == "Delivery" || key == "Takeaway";
  }

  void selectOrderTypeById({required String id, required String label}) {
    final newLabel = label.trim();
    final prevLabel = rxOrderTypeLabel.value;
    final currentKey = rxCurrentTable.value.trim();

    // Save ID + Label (NEW API SYSTEM)
    rxOrderTypeId.value = id;
    rxOrderTypeLabel.value = newLabel;
    rxBillSettled.value = false;

    // ------------------------------
    // 🍽 If switching AWAY from Dine In, remember last table
    // ------------------------------
    if (prevLabel == "Dine In") {
      if (currentKey.isNotEmpty && !_isVirtualMode(currentKey)) {
        _lastDineInTable = currentKey;
      }
    }

    // ------------------------------
    // 🍽 If switching TO Dine In → restore old table
    // ------------------------------
    if (newLabel == "Dine In") {
      if (_lastDineInTable != null && _lastDineInTable!.isNotEmpty) {
        rxCurrentTable.value = _lastDineInTable!;
        ensureLoadedForTable(_lastDineInTable!, latestOnly: false);
      } else {
        if (currentKey.isNotEmpty && !_isVirtualMode(currentKey)) {
          ensureLoadedForTable(currentKey, latestOnly: false);
        } else {
          rxCurrentTable.value = "";
          rebuildUnifiedKotList(tableName: "");
        }
      }

      resetFoodListOnOrderTypeChange();
      update();
      return;
    }

    // ------------------------------
    // For Delivery / Takeaway / Quick Bill → Use virtual tables
    // ------------------------------
    rxCurrentTable.value = newLabel;
    _ensureTableEntry(newLabel);

    resetFoodListOnOrderTypeChange();
    update();
  }

  Future<void> _refreshReceiptsAndSales() async {
    // Refresh Receipts list (keeps pagination)
    if (Get.isRegistered<ReceiptController>()) {
      try {
        final rc = Get.find<ReceiptController>();
        final pageToFetch = (rc.currentPage.value > 0)
            ? rc.currentPage.value
            : 1;
        rc.fetchFromBills(page: pageToFetch);
      } catch (_) {}
    }

    // Refresh Sales reports
    if (Get.isRegistered<ControllerSales>()) {
      try {
        final sales = Get.find<ControllerSales>();
        await sales.fetchFromBills(); // or: sales.applyCurrentFilters();
      } catch (_) {}
    }
  }

  void markBillSettledAndClear({String? tableNameOverride}) {
    rxBillSettled.value = true;
    final tableName = (tableNameOverride ?? rxCurrentTable.value).trim();

    if (tableName.isNotEmpty && _tableOrders.containsKey(tableName)) {
      _tableOrders[tableName] = TableOrderData();
    }

    final allBills = boxEntityOrder.getAll().where(
      (b) =>
          b.tableName?.trim() == tableName &&
          b.status == BillStatus.booked.value,
    );

    for (final bill in allBills) {
      bill.status = BillStatus.settled.value;
      bill.endTime = DateTime.now().toIso8601String();
      boxEntityOrder.put(bill);
    }

    tableBillMap.remove(tableName);
    if (tableName.isNotEmpty) {
      rebuildUnifiedKotList(tableName: tableName); // Clear the view
    }

    try {
      Get.find<ControllerTable>().clearBooked(tableName);
    } catch (_) {}

    update();
  }

  void addNoteToItem({required String itemId, required String note}) {
    itemNotes[itemId] = note.trim();
    update();
  }

  Map<String, dynamic> buildKotCloseResponse(
    EntityOrder bill,
    int kotNumber,
    String tableName,
    List<EntityOrderFood> items,
  ) {
    return {
      ...billToMap(bill),
      'kotNumber': kotNumber,
      'table': tableName,
      'items': items.map(foodToMap).toList(),
    };
  }

  Map<String, dynamic> _safeDecodeMap(String? s) {
    try {
      if (s == null || s.isEmpty) return <String, dynamic>{};
      final v = jsonDecode(s);
      return v is Map<String, dynamic> ? v : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  void _saveKotCloseJsonToDb(EntityOrder bill, Map<String, dynamic> closeJson) {
    // latest KOT snapshot
    try {
      (bill as dynamic).orderItemsJson = jsonEncode(closeJson);
    } catch (_) {}

    // append to kotHistory in metaJson
    final meta = _safeDecodeMap(bill.metaJson);
    final List<dynamic> history =
        (meta['kotHistory'] as List?)?.toList() ?? <dynamic>[];
    history.add(closeJson);
    meta['kotHistory'] = history;

    try {
      (bill as dynamic).metaJson = jsonEncode(meta);
    } catch (_) {}

    boxEntityOrder.put(bill);
  }

  String getNoteForItem(String itemId) {
    return itemNotes[itemId] ?? '';
  }

  EntityUser? getUserByMobile(String mobile) {
    if (mobile.trim().isEmpty) return null;
    final query = boxEntityUser
        .query(EntityUser_.mobile.equals(mobile))
        .build();
    final result = query.findFirst();
    query.close();
    return result;
  }

  List<EntityUser> searchCustomers(String searchTerm) {
    if (searchTerm.trim().isEmpty) return [];
    final query = boxEntityUser
        .query(EntityUser_.mobile.contains(searchTerm.trim()))
        .build();
    final results = query.find();
    query.close();
    // Return up to 10 results
    return results.take(10).toList();
  }

  EntityUser createUserFromDetails({
    required String mobile,
    String? first,
    String? last,
    String? userType,
    String? countryCode,
    String? address,
  }) {
    final newUser = EntityUser(
      userName: first ?? mobile,
      userPassword: "n/a",
      userType: userType ?? "Customer",
      first: first ?? "",
      last: last ?? "",
      countryCode: countryCode ?? "",
      mobile: mobile,
      dob: "",
      gender: "",
      idProofKey: null,
      idProofValue: null,
      address: address ?? "",
      backendUserId: 0,
    );

    final id = boxEntityUser.put(newUser);
    final saved = boxEntityUser.get(id)!;
    return saved;
  }

  bool isKotPrintedGroup(KotGroup g) => g.isPrinted;

  void markKotGroupPrinted(EntityOrder bill, KotGroup g) {
    var changed = false;
    for (final item in g.items) {
      if (!item.isPrinted) {
        item.setPrinted(true);
        boxEntityOrderFood.put(item);
        changed = true;
      }
    }
    if (changed) rebuildUnifiedKotList(tableName: bill.tableName ?? '');
  }

  EntityOrder? getActiveBillForTableName(String tableName) {
    return findLatestOpenBillForTable(tableName.trim());
  }

  List<KotGroup> getKotsForActiveBillOfTable(String tableName) {
    final bill = findLatestOpenBillForTable(tableName.trim());
    if (bill == null) return <KotGroup>[];
    final foods = bill.listFood.toList();
    return _groupFoodsByKot(foods);
  }

  bool areAllKotsPrintedForTable(String tableName) {
    final groups = getKotsForActiveBillOfTable(tableName);
    if (groups.isEmpty) return false;
    for (final g in groups) {
      if (!g.isPrinted) return false;
    }
    return true;
  }

  Future<EntityOrder> getOrCreateBillForKot(EntityOrderFood foodItem) async {
    // foodItem.orderId set? return that bill
    if (foodItem.orderId != null) {
      final b = boxEntityOrder.get(foodItem.orderId!);
      if (b != null) {
        _ensureBillHasUuid(b);
        return b;
      }
    }

    // create a new bill (fallback)
    final now = DateTime.now().toIso8601String();

    final newBill = EntityOrder(
      orderNumber: 0,
      status: "booked",
      startTime: now,
      endTime: null,
      tableName: (foodItem.tableName ?? '').isNotEmpty
          ? foodItem.tableName
          : "Unknown",
      tableSeat: 0,
      orderTypeId: rxOrderType.value,
      userName: "System",
      createdOn: now,
    );
    newBill.orderTypeId = rxOrderTypeId.value; // ⭐ REQUIRED

    _ensureBillHasUuid(newBill);
    newBill.orderId = boxEntityOrder.put(newBill);

    // attach this item
    foodItem.orderId = newBill.orderId;
    newBill.listFood.add(foodItem);
    newBill.listFood.applyToDb();
    boxEntityOrder.put(newBill);

    return newBill;
  }

  List<Map<String, dynamic>> getUnifiedBillItems() {
    final List<Map<String, dynamic>> itemsForBill = [];

    // Use the unified, reactive list which already contains everything
    for (final unifiedItem in kotUnifiedItems) {
      itemsForBill.add({
        'id': int.tryParse(unifiedItem.id) ?? 0,
        'name': unifiedItem.name,
        'qty': unifiedItem.qty,
        'price': unifiedItem.price,
        'amount': (unifiedItem.price) * (unifiedItem.qty),
        'server': true, // All items are treated as billable
      });
    }

    return itemsForBill;
  }

  Future<void> saveOrder(String tableName, int tableSeat, String booked) async {
    rxBillSettled.value = false;

    // IMPORTANT: work on this table's bucket, not rxCurrentTable
    _ensureTableEntry(tableName);
    final tableData = _tableOrders[tableName]!;

    // Initialize printed tracker if not present
    tableData.printedFoodIds ??= <int>{};

    debugPrint(
      '➡️ saveOrder(table=$tableName, seat=$tableSeat, status=$booked)',
    );

    if (tableData.orderItems.isEmpty && tableData.extraItems.isEmpty) {
      debugPrint("⚠ No order items or extras to save for [$tableName]");
      return;
    }

    // Log cart snapshot before save
    logJson('CART_BEFORE_SAVE', {
      'table': tableName,
      'orderItems': [
        for (final e in tableData.orderItems.entries)
          {
            'id': e.key.foodId ?? 0,
            'name': e.key.foodName ?? '',
            'qty': e.value,
          },
      ],
      'extras': [
        for (final ex in tableData.extraItems)
          {
            'id': ex.id,
            'name': ex.name,
            'qty': ex.qty,
            'price': ex.price,
            'amount': (ex.price) * (ex.qty),
          },
      ],
    });

    final now = DateTime.now().toUtc().toIso8601String();
    final tableKey = tableName.trim();
    final existingOrderId = tableBillMap[tableKey];

    // create or get bill
    EntityOrder bill;
    if (existingOrderId != null) {
      bill = boxEntityOrder.get(existingOrderId)!;
      _ensureBillHasUuid(bill);
      debugPrint(
        "↪️ Using existing bill id=$existingOrderId for table=$tableName",
      );
    } else {
      final AuthService authService = Get.find();
      final String currentUserName = authService.userName.isNotEmpty
          ? authService.userName
          : 'Guest';

      bill = EntityOrder(
        orderNumber: 0, // NO BILL NUMBER HERE
        status: BillStatus.pending.value,
        restUuid: _getRestaurantUuid(),
        startTime: now,
        endTime: null,
        tableName: tableName,
        tableSeat: tableSeat,
        orderTypeId: rxOrderType.value,
        userName: currentUserName,
        createdOn: now,
      );

      _ensureBillHasUuid(bill);
      bill.orderId = boxEntityOrder.put(bill);
      tableBillMap[tableKey] = bill.orderId;
      debugPrint(
        "✅ New bill created id=${bill.orderId}, orderNo=${bill.orderNumber} (table=$tableName)",
      );
    }

    // Acquire next KOT number
    final kotNumber = await controllerSetting.acquireNextKotNumber();
    debugPrint("🧾 KOT number acquired: $kotNumber (table=$tableName)");

    // 1) Aggregate normal items by foodId (SKIP printed)
    final Map<int, _AggLine> agg = {};
    tableData.orderItems.forEach((food, qty) {
      final id = food.foodId ?? 0;
      if (id <= 0) return; // extras handled below

      // ✅ skip already printed items
      if (tableData.printedFoodIds.contains(id)) return;

      final prev = agg[id];
      if (prev == null) {
        agg[id] = _AggLine(food, qty);
      } else {
        prev.qty += qty;
      }
    });

    // ✅ Stop here if no new items to print
    if (agg.isEmpty && tableData.extraItems.isEmpty) {
      Get.snackbar(
        "No new items",
        "All items already sent to KOT.",
        snackPosition: SnackPosition.BOTTOM,
      );
      debugPrint("⚠ No new KOT items for $tableName — skipping print.");
      return;
    }

    // START: STOCK DEDUCTION LOGIC (unchanged)
    final List<EntityFood> foodsToUpdateInDb = [];
    agg.forEach((foodId, line) {
      final food = line.food;
      final orderedQty = line.qty;
      if (food.stock != null) {
        final currentStock = food.stock!;
        food.stock = currentStock - orderedQty;
        foodsToUpdateInDb.add(food);
        debugPrint(
          "📦 Stock Update: '${food.foodName}' | Old: $currentStock | Ordered: $orderedQty | New: ${food.stock}",
        );
      }
    });

    if (foodsToUpdateInDb.isNotEmpty) {
      boxEntityFood.putMany(foodsToUpdateInDb);
      debugPrint(
        "💾 Persisted stock updates for ${foodsToUpdateInDb.length} items.",
      );
      refreshFoodList();
    }
    // END: STOCK DEDUCTION LOGIC

    // 2) Aggregate extras by (name|price)
    final Map<String, ExtraItem> aggExtras = {};
    for (final ex in tableData.extraItems) {
      final key = "${ex.name.trim().toLowerCase()}|${ex.price}";
      final prev = aggExtras[key];
      if (prev == null) {
        aggExtras[key] = ExtraItem(
          id: ex.id,
          name: ex.name,
          price: ex.price,
          qty: ex.qty,
        );
      } else {
        prev.qty += ex.qty;
      }
    }

    // 3) Build KOT rows from aggregates
    final newFoods = <EntityOrderFood>[];

    agg.forEach((_, line) {
      final food = line.food;
      final price = food.price.isNotEmpty
          ? (food.price.first.price ?? 0.0)
          : 0.0;
      newFoods.add(
        EntityOrderFood(
          orderId: bill.orderId,
          foodId: food.foodId,
          name: food.foodName ?? '',
          category: (food.categoryName ?? ''),
          taxPercentage: 0,
          quantity: line.qty,
          price: price,
          kotNumber: kotNumber,
          uuid: _generateUuid(),
          createdOn: now,
          tableName: tableName,
          origin: _currentOrigin(),
          orderType: bill.orderTypeId,
        ),
      );
    });

    aggExtras.forEach((_, ex) {
      newFoods.add(
        EntityOrderFood(
          orderId: bill.orderId,
          foodId: 0,
          name: ex.name,
          category: 'Extras',
          taxPercentage: 0,
          quantity: ex.qty,
          price: ex.price,
          kotNumber: kotNumber,
          uuid: _generateUuid(),
          createdOn: now,
          tableName: tableName,
          origin: _currentOrigin(),
          orderType: bill.orderTypeId,
        ),
      );
    });

    // Persist relation
    bill.listFood.addAll(newFoods);
    bill.listFood.applyToDb();
    boxEntityOrder.put(bill);
    _dedupeKotLines(bill, kotNumber);

    // Build the flattened JSON for logs/history and save it
    final closeResp = buildKotCloseResponse(
      bill,
      kotNumber,
      tableName,
      newFoods,
    );
    _saveKotCloseJsonToDb(bill, closeResp);

    debugPrintLarge(prettyKot(bill, kotNumber, tableName, newFoods));
    logJson('KOT_ITEMS_BUILT', closeResp);
    logJson('KOT_PERSISTED', {
      'bill': billToMap(bill),
      'kotNumber': kotNumber,
      'itemsCount': newFoods.length,
    });

    final kotItems = [
      for (final f in newFoods)
        {
          'id': f.foodId ?? 0,
          'name': f.name ?? '',
          'qty': f.quantity ?? 0,
          'price': f.price ?? 0.0,
          'amount': (f.price ?? 0.0) * (f.quantity ?? 0),
          if ((f.category ?? '').toLowerCase() == 'extras') 'extra': true,
        },
    ];
    final itemsJson = jsonEncode({'items': kotItems});
    debugPrintLarge("[KOT_PAYLOAD]\n$itemsJson");

    // Persist itemsJson for split screen
    for (final foodItem in newFoods) {
      foodItem.itemsJson = itemsJson;
    }
    boxEntityOrderFood.putMany(newFoods);

    await sendKotAndMarkTable(
      bill: bill,
      kotNumber: kotNumber,
      createdOn: now,
      tableName: tableName,
      itemsJson: itemsJson,
    );

    debugPrint(
      "📤 KOT #$kotNumber sent for table=$tableName (items=${newFoods.length})",
    );

    // ✅ Mark items as printed
    for (final line in agg.entries) {
      tableData.printedFoodIds.add(line.key);
    }
    debugPrint("🧾 Marked ${agg.length} items as printed for table=$tableName");

    // CLEAR THIS TABLE'S LOCAL CART (not rxCurrentTable)
    tableData.orderItems.removeWhere(
      (food, _) => tableData.printedFoodIds.contains(food.foodId),
    );
    tableData.extraItems.clear();
    // 🧹 Also rebuild to exclude old printed items from UI
    rebuildUnifiedKotList(tableName: tableName);

    debugPrint("🧹 Cleared local new items for table=$tableName");

    // Refresh UI
    refreshKotItemsForTable(tableName, bill.orderId);
    rebuildUnifiedKotList(tableName: tableName);
    getTotalPrice();
    update();
    debugPrint("🔄 UI refreshed for table=$tableName (billId=${bill.orderId})");

    try {
      if (Get.isRegistered<ControllerKotReports>()) {
        Get.find<ControllerKotReports>().refresh();
      }
    } catch (_) {}

    _debugTotalsForTable(tableName);
    getTotalPrice();
    update();
  }

  Future<EntityOrder> createBillWithoutOrderNumber(
    String tableName,
    int seats,
  ) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final AuthService authService = Get.find();
    final String currentUserName = authService.userName.isNotEmpty
        ? authService.userName
        : 'Guest';

    final bill = EntityOrder(
      orderNumber: 0, // IMPORTANT
      status: BillStatus.pending.value,
      restUuid: _getRestaurantUuid(),
      startTime: now,
      endTime: null,
      tableName: tableName,
      tableSeat: seats,
      orderTypeId: rxOrderType.value,
      userName: currentUserName,
      createdOn: now,
    );

    _ensureBillHasUuid(bill);

    bill.orderId = boxEntityOrder.put(bill);
    tableBillMap[tableName] = bill.orderId;

    return bill;
  }

  List<KotUiItem> _itemsFromFoodsAggregated(List<EntityOrderFood> foods) {
    final Map<String, KotUiItem> byKey = {};

    for (final f in foods) {
      final qty = (f.quantity ?? 0);
      if (qty <= 0) continue;

      final id = f.foodId ?? 0;
      final name = (f.name ?? '').trim();
      final price = f.price ?? 0.0;
      final kotNumber = f.kotNumber ?? 0;
      final uuid = f.uuid;

      // aggregate by id + price + name
      final key = '$id|${price.toStringAsFixed(2)}|${name.toLowerCase()}';

      final cur = byKey[key];
      if (cur == null) {
        byKey[key] = KotUiItem(
          id: f.orderId,
          foodId: id,
          name: name,
          price: price,
          qty: qty,
          kotNumber: kotNumber,
          uuid: uuid,
        );
      } else {
        cur.qty += qty;
      }
    }

    return byKey.values.toList();
  }

  // -----------------------------------------------
  // RETURN ALL CURRENTLY OPEN (BOOKED) BILLS
  // -----------------------------------------------
  List<EntityOrder> getAllOpenBills() {
    return boxEntityOrder
        .query(EntityOrder_.status.equals(BillStatus.booked.value))
        .build()
        .find();
  }

  // -----------------------------------------------
  // GROUP OPEN BILLS BY TABLE NAME
  // -----------------------------------------------
  Map<String, int> openBillCountsByTable() {
    final result = <String, int>{};

    final openBills = getAllOpenBills();
    for (final b in openBills) {
      final table = (b.tableName ?? '').trim();
      if (table.isEmpty) continue;

      result[table] = (result[table] ?? 0) + 1;
    }

    return result;
  }

  // -----------------------------------------------
  // SETTLE ALL OPEN BILLS (CLOSE APP SAFELY)
  // -----------------------------------------------
  Future<void> settleAllOpenBills() async {
    final openBills = getAllOpenBills();
    final now = DateTime.now().toIso8601String();

    for (final b in openBills) {
      b.status = BillStatus.settled.value;
      b.endTime = now;
      boxEntityOrder.put(b);

      // Also clear booked tables
      try {
        Get.find<ControllerTable>().clearBooked(b.tableName ?? '');
      } catch (_) {}
    }

    // refresh UI
    update();

    // 🔄 SYNC COUNTERS TO SERVER
    Get.find<ControllerSetting>().updateRestaurantCountersOnServer();
  }

  Future<void> _tryPrintBill(
    EntityOrder bill,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      // Calculate totals from 'items' param passed in
      final double originalTotal = items.fold<double>(
        0.0,
        (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0.0),
      );

      double discountAmount = 0.0;
      try {
        discountAmount = (bill.discountAmount ?? 0.0);
        final p = (bill.discountPercent ?? 0.0);
        if ((discountAmount <= 0) && (p > 0)) {
          discountAmount = (p / 100.0) * originalTotal;
        }
      } catch (_) {}

      final double finalTotal = (originalTotal - discountAmount).clamp(
        0.0,
        double.infinity,
      );

      debugPrint("🖨️ BILL #${bill.orderNumber} (${bill.tableName})");
      for (final it in items) {
        debugPrint(
          "  ${it['qty']} × ${it['name']} @ ${it['price']} = ${it['amount']}",
        );
      }
      debugPrint("  ORIGINAL: ${originalTotal.toStringAsFixed(2)}");
      if (discountAmount > 0) {
        debugPrint("  DISCOUNT: ${discountAmount.toStringAsFixed(2)}");
      }
      debugPrint("  TOTAL: ${finalTotal.toStringAsFixed(2)}");
    } catch (e) {
      debugPrint("⚠️ Print failed: $e");
    }
  }

  // Return all KOT groups that are not marked printed (for this table)
  List<KotGroup> pendingKotsForTable(String tableName) {
    final groups = getKotsForActiveBillOfTable(tableName.trim());
    return groups.where((g) => !g.isPrinted).toList();
  }

  // Optional: quick logger to see KOT print status per group
  void logKotPrintStatus(String tableName) {
    final groups = getKotsForActiveBillOfTable(tableName.trim());
    for (final g in groups) {
      debugPrint(
        "KOT #${g.kotNumber} printed=${g.isPrinted} items=${g.items.length}",
      );
    }
  }

  // Print (or simulate print) and mark all unprinted KOTs for a table
  Future<void> printPendingKotsForTable(String tableName) async {
    final t = tableName.trim();
    final bill = getActiveBillForTableName(t);
    if (bill == null) return;

    final groups = getKotsForActiveBillOfTable(t);
    for (final g in groups) {
      if (!g.isPrinted) {
        // If you have a real printer call, use it here:
        // await kotPrintByConfigType(
        //   "KOT",
        //   kot: g,
        //   bill: bill,
        //   groupedItems: getGroupedOrderItemsForKot(includeServerKot: true),
        // );

        // Mark the whole group as printed in DB
        markKotGroupPrinted(bill, g);
      }
    }

    // Refresh UI / totals
    refreshKotItemsForTable(t, bill.orderId);
    rebuildUnifiedKotList(tableName: t);
    getTotalPrice(forTable: t);
    update();
  }

  bool areKotsPrintedForTable(String tableName, {bool onlyLatest = true}) {
    final kots = getKotsForActiveBillOfTable(tableName);
    if (kots.isEmpty) return false;

    kots.sort((a, b) => _ts(b.createdOn).compareTo(_ts(a.createdOn)));

    if (onlyLatest) {
      return kots.first.isPrinted;
    }

    for (final g in kots) {
      if (!g.isPrinted) return false;
    }
    return true;
  }

  bool _isBillMoreRecent(EntityOrder a, EntityOrder b) {
    final da = _ts(a.createdOn);
    final db = _ts(b.createdOn);
    if (da.isAfter(db)) return true;
    if (da.isBefore(db)) return false;

    final nba = a.orderNumber ?? 0;
    final nbb = b.orderNumber ?? 0;
    if (nba != nbb) return nba > nbb;

    final ida = a.orderId;
    final idb = b.orderId;
    return (ida ?? 0) > (idb ?? 0);
  }

  EntityOrder? findLatestOpenBillForTable(String tableName) {
    final normalized = tableName.trim();

    // Fetch only bills that:
    // 1) match table
    // 2) are OPEN (booked)
    // 3) HAVE A REAL BILL NUMBER (orderNumber > 0)
    //    → ensures it was saved via Save Bill

    final q = boxEntityOrder
        .query(
          EntityOrder_.tableName.equals(normalized) &
              EntityOrder_.status.equals(BillStatus.booked.value) &
              EntityOrder_.orderNumber.greaterThan(0),
        )
        .build();

    final bills = q.find();
    q.close();

    if (bills.isEmpty) return null;

    // Sort by latest created
    bills.sort((a, b) {
      final ad = DateTime.tryParse(a.createdOn ?? "");
      final bd = DateTime.tryParse(b.createdOn ?? "");
      return (bd ?? DateTime(0)).compareTo(ad ?? DateTime(0));
    });

    return bills.first;
  }

  void rebuildTableBillMap() {
    tableBillMap.clear();
    final q = boxEntityOrder
        .query(EntityOrder_.status.equals(BillStatus.booked.value))
        .build();
    final openBills = q.find();
    q.close();

    for (final b in openBills) {
      final tName = (b.tableName ?? '').trim();
      if (tName.isEmpty) continue;

      if (!tableBillMap.containsKey(tName)) {
        tableBillMap[tName] = b.orderId;
      } else {
        final current = boxEntityOrder.get(tableBillMap[tName]!);
        if (current == null || _isBillMoreRecent(b, current)) {
          tableBillMap[tName] = b.orderId;
        }
      }
    }
  }

  Future<EntityOrder> getOrCreateOpenBillForTable(
    String tableName, {
    int tableSeat = 0,
  }) async {
    final normalized = tableName.trim();
    final existing = findLatestOpenBillForTable(normalized);

    if (existing != null) {
      _ensureBillHasUuid(existing);
      tableBillMap[normalized] = existing.orderId;
      return existing;
    }

    final now = DateTime.now().toIso8601String();
    final currentOrderNo = await controllerSetting.acquireNextorderNumber();
    final AuthService authService = Get.find();

    final String currentUserName = authService.userName.isNotEmpty
        ? authService.userName
        : 'Guest';

    // STEP 1: Create bill WITHOUT tableMongoId (no error)
    final bill = EntityOrder(
      orderNumber: currentOrderNo,
      status: BillStatus.booked.value,
      startTime: now,
      endTime: null,
      tableName: normalized,
      tableSeat: tableSeat,
      orderTypeId: rxOrderType.value,
      userName: currentUserName,
      createdOn: now,
    );

    // STEP 2: Assign tableMongoId AFTER creation
    bill.tableMongoId =
        Get.find<ControllerTable>().selectedTable.value?.mongoId ?? "";

    // STEP 3: Save bill
    _ensureBillHasUuid(bill);
    bill.orderTypeId = rxOrderTypeId.value; // ⭐ Correct backend MongoId
    boxEntityOrder.put(bill); // Save updated bill

    bill.orderId = boxEntityOrder.put(bill);

    tableBillMap[normalized] = bill.orderId;

    return bill;
  }

  Future<KotGroup?> ensureKotForTable({
    required String tableName,
    int tableSeat = 0,
  }) async {
    final normalized = tableName.trim();
    if (normalized.isEmpty) return null;

    final bill = await getOrCreateOpenBillForTable(
      normalized,
      tableSeat: tableSeat,
    );
    final data = _tableOrders[normalized];
    final hasLocalItems =
        (data?.orderItems.isNotEmpty ?? false) ||
        (data?.extraItems.isNotEmpty ?? false);

    if (!hasLocalItems) {
      // return latest existing kot if present
      final groups = getKotsForActiveBillOfTable(normalized);
      if (groups.isNotEmpty) return groups.last;
      return null;
    }

    await saveOrder(normalized, tableSeat, BillStatus.booked.value);
    final afterGroups = getKotsForActiveBillOfTable(normalized);
    return afterGroups.isNotEmpty ? afterGroups.last : null;
  }

  Future<KotGroup?> ensureKotForCurrentTable({int tableSeat = 0}) async {
    final t = rxCurrentTable.value.trim();
    if (t.isEmpty) return null;
    return ensureKotForTable(tableName: t, tableSeat: tableSeat);
  }

  Future<void> sendKotAndMarkTable({
    required EntityOrder bill,
    required int kotNumber,
    required String createdOn,
    required String tableName,
    required String itemsJson,
  }) async {
    await sendKotViaSocket(
      bill: bill,
      kotNumber: kotNumber,
      createdOn: createdOn,
      tableName: tableName,
      itemsJson: itemsJson,
    );

    try {
      final tableController = Get.find<ControllerTable>();
      tableController.markTableSent(tableName);
      debugPrint("✅ Table $tableName marked as booked/sent.");
    } catch (e) {
      debugPrint("⚠ Could not mark table booked: $e");
    }
  }

  // IN FILE: ControllerOrder.dart
  // IN CLASS: ControllerOrder
  String generateFakeMongoId() {
    const chars = 'abcdef0123456789';
    final rand = DateTime.now().millisecondsSinceEpoch.toString();

    return List.generate(24, (i) {
      final index = (rand.codeUnitAt(i % rand.length)) % chars.length;
      return chars[index];
    }).join();
  }

  // ✅ NEW FUNCTION TO PROCESS KOTs RECEIVED BY THE SERVER
  Future<void> processAndSaveIncomingKot(Map<String, dynamic> kotData) async {
    debugPrint("🟨 ControllerOrder: Processing incoming KOT data...");

    // --- This logic is moved from ControllerServer._saveKotToLocalDb ---
    final now = DateTime.now().toUtc().toIso8601String();
    final normalizedTable =
        kotData['tableName']?.toString().trim() ?? 'Unknown';
    final int kotNumber =
        int.tryParse(kotData['kotNumber']?.toString() ?? '0') ?? 0;
    final String createdOn = kotData['createdOn']?.toString() ?? now;
    final String? kotUuid = kotData['uuid']?.toString();

    // Find or create the bill for this order
    EntityOrder? bill = findLatestOpenBillForTable(normalizedTable);
    bill ??= await getOrCreateOpenBillForTable(normalizedTable);
    _ensureBillHasUuid(bill);

    // Parse the items from the KOT's JSON
    List items = [];
    try {
      if (kotData['itemsJson'] is String) {
        final dec = jsonDecode(kotData['itemsJson']);
        if (dec is Map && dec['items'] is List) items = dec['items'];
      }
    } catch (e) {
      debugPrint("⚠️ processAndSaveIncomingKot: itemsJson parse failed: $e");
      return;
    }
    if (items.isEmpty) {
      debugPrint("ℹ️ processAndSaveIncomingKot: KOT had no items to process.");
      return;
    }

    // Create EntityOrderFood objects
    final newFoods = <EntityOrderFood>[];
    for (final raw in items) {
      if (raw is! Map) continue;
      newFoods.add(
        EntityOrderFood(
          orderId: bill.orderId,
          foodId: int.tryParse(raw['id']?.toString() ?? '0'),
          name: raw['name']?.toString() ?? '',
          category: raw['category']?.toString() ?? 'Extras',
          quantity: int.tryParse(raw['qty']?.toString() ?? '0'),
          price: double.tryParse(raw['price']?.toString() ?? '0.0'),
          kotNumber: kotNumber,
          uuid: kotUuid ?? _generateUuid(),
          origin: kotData['origin']?.toString() ?? 'captain',
          createdOn: createdOn,
          tableName: normalizedTable,
          restUuid: _getRestaurantUuid(),

          orderType: kotData['orderType']?.toString() ?? bill.orderTypeId,
          taxPercentage: null,
        ),
      );
      debugPrint("🏪 Assigned restUuid to Bill: ${_getRestaurantUuid()}");
    }

    if (newFoods.isEmpty) return;

    // Save the new food items to the database
    boxEntityOrderFood.putMany(newFoods);
    bill.listFood.addAll(newFoods);
    bill.listFood.applyToDb();
    boxEntityOrder.put(bill);

    debugPrint(
      "✅ ControllerOrder: Saved ${newFoods.length} items for KOT #$kotNumber to DB.",
    );

    // --- THIS IS THE CRUCIAL FIX ---
    // Now, refresh the state of THIS controller, which the UI is watching.
    // This ensures the total and item list are updated correctly.
    ensureLoadedForTable(normalizedTable, latestOnly: false);

    debugPrint(
      "✅ ControllerOrder: UI state refreshed for table '$normalizedTable'. Total should now be correct.",
    );
  }

  Future<Map<String, dynamic>?> sendKotViaSocket({
    required EntityOrder bill,
    required int kotNumber,
    required String createdOn,
    required String tableName,
    required String itemsJson,
  }) async {
    final kotJsonData = {
      'kotNumber': kotNumber,
      'uuid': _generateUuid(),
      'tableName': tableName,
      'orderNumber': bill.orderNumber,
      'billUuid': _readBillUuid(bill),
      'createdOn': createdOn,
      'itemsJson': itemsJson,
      'orderType': bill.orderTypeId,
      'origin': _currentOrigin(),

      // Optional: explicit hint to any listeners that DB was already updated
      'alreadyPersistedLocally': true,
    };

    final message = jsonEncode({"type": "kot", "data": kotJsonData});

    Map<String, dynamic>? response;

    // Online server call (no change)
    try {
      final payload = {"type": "kot", "data": kotJsonData};
      if (Get.isRegistered<ControllerServerSelection>()) {
        final sel = Get.find<ControllerServerSelection>();
        final resp = await sel.sendRequest(payload);
        if ((resp['status'] ?? '') == 'error') {
          // fallback attempt
          sel.sendToServer(jsonEncode(payload));
        }
      } else {
        debugPrint("ℹ️ No ControllerServerSelection — local broadcast only");
      }
    } catch (e) {
      debugPrint("⚠ Error sending KOT to server: $e");
    }

    // Local KDS broadcast — IMPORTANT: do NOT persist again here
    try {
      if (Get.isRegistered<ControllerServer>()) {
        final srv = Get.find<ControllerServer>();

        // Do NOT call: srv.handleIncomingKotFromFlutter(kotJsonData);
        // It writes to DB again and doubles your lines.

        // Just broadcast so KDS screens refresh
        srv.messages.add(message);
        srv.sendToKDS('$message\n');
      } else if (Get.isRegistered<KOTController>()) {
        // If this only displays KOTs and doesn't write to DB, keep it.
        Get.find<KOTController>().processSingleMessage(message);
      } else {
        debugPrint(
          "⚠ No ControllerServer or KOTController; KDS may not refresh",
        );
      }
    } catch (e) {
      debugPrint("⚠ Local KDS update failed: $e");
    }

    return response;
  }

  void _dedupeKotLines(EntityOrder bill, int kotNumber) {
    final lines = bill.listFood.toList();
    final seen = <String, EntityOrderFood>{};
    final toRemove = <EntityOrderFood>[];

    for (final f in lines) {
      if ((f.kotNumber ?? -1) != kotNumber) continue;
      final key =
          '${f.foodId}|${f.price?.toStringAsFixed(2)}|${(f.name ?? '').toLowerCase()}';
      if (seen.containsKey(key)) {
        // exact duplicate line in same KOT -> drop
        toRemove.add(f);
      } else {
        seen[key] = f;
      }
    }

    if (toRemove.isNotEmpty) {
      for (final r in toRemove) {
        bill.listFood.remove(r);
      }
      bill.listFood.applyToDb();
      boxEntityOrder.put(bill);
      debugPrint(
        '🧹 Removed ${toRemove.length} duplicate KOT lines for #$kotNumber',
      );
    }
  }

  void refreshKotUnifiedItems(String billUuid) {
    final all = boxEntityOrder.getAll();
    final bill = all.firstWhereOrNull((b) => _readBillUuid(b) == billUuid);

    // Fallback to find by table name if UUID fails
    String tableName = '';
    if (bill != null) {
      tableName = bill.tableName ?? '';
    }
    rebuildUnifiedKotList(tableName: tableName); // Use the unified function
  }

  List<Map<String, dynamic>> getUnifiedBillItemsFromDb(EntityOrder bill) {
    final foods = bill.listFood.toList();
    final items = _itemsFromFoodsAggregated(foods); // now List<KotUiItem>

    return [
      for (final it in items)
        {
          'id': it.id ?? 0,
          'foodId': it.foodId, // ✅ Added foodId for tax lookup
          'name': it.name,
          'qty': it.qty,
          'price': it.price,
          'amount': (it.price * it.qty),
          'server': true,
        },
    ];
  }

  // In file: screens/home/fragments/order/controller_order.dart
  // In class: ControllerOrder

  // ✅ THIS IS THE FULL, NEW eBill FUNCTION. REPLACE THE OLD ONE WITH THIS.

  // In file: screens/home/fragments/order/controller_order.dart
  Future<void> eBill(
    EntityTable? table,
    String paymentMode, {
    List<PaymentEntry> payments = const [],
    double tipAmount = 0.0,
    String tipPaymentMode = 'Cash',
    double dueAmount = 0.0,
    String? customerName,
    String? customerMobile,
    String? customerAddress,
    String? referenceNo,
    String? waiterName,
    int? waiterId,
    bool printAfterSettle = true,
    bool includeLocalCart = true,
  }) async {
    final String effectiveTableName = (table?.tableName ?? rxCurrentTable.value)
        .trim();

    if (effectiveTableName.isEmpty) {
      Get.snackbar(
        "Error",
        "No active order found. Please re-select the order.",
      );
      return;
    }

    final tName = effectiveTableName;
    EntityOrder? bill = getActiveBillForTableName(tName);

    final data = _tableOrders[tName];
    final hasLocal =
        (data?.orderItems.isNotEmpty ?? false) ||
        (data?.extraItems.isNotEmpty ?? false);

    if (bill == null && hasLocal) {
      bill = await getOrCreateOpenBillForTable(tName);
    }

    if (includeLocalCart && hasLocal) {
      await saveOrder(tName, bill?.tableSeat ?? 0, BillStatus.booked.value);
      bill = getActiveBillForTableName(tName);
    } else {
      bill ??= await _waitForServerBillWithItems(tName);
    }

    if (bill == null) {
      Get.snackbar("Info", "There are no items to bill for this order.");
      return;
    }

    _ensureBillHasUuid(bill);

    // ✅ FIX: Ensure orderTypeId is set before saving/syncing
    if (bill.orderTypeId == null || bill.orderTypeId!.trim().isEmpty) {
      try {
        if (Get.isRegistered<ControllerOrderType>()) {
          final otCtrl = Get.find<ControllerOrderType>();
          // Use current label if available, otherwise fallback to "Dine In"
          final labelToUse = rxOrderTypeLabel.value.isNotEmpty
              ? rxOrderTypeLabel.value
              : "Dine In";

          final resolvedId = otCtrl.getIdByLabel(labelToUse);
          if (resolvedId != null) {
            bill.orderTypeId = resolvedId;
            debugPrint(
              "🔧 Resolved missing orderTypeId to: $resolvedId ($labelToUse)",
            );

            // Also update the reactive variable if it was empty
            if (rxOrderTypeId.value.isEmpty) {
              rxOrderTypeId.value = resolvedId;
            }
          }
        }
      } catch (e) {
        debugPrint("⚠️ Failed to resolve orderTypeId in eBill: $e");
      }
    }

    final itemsForBill = getUnifiedBillItemsFromDb(bill);
    if (itemsForBill.isEmpty) {
      Get.snackbar("Info", "There are no items to bill for this order.");
      return;
    }

    final String payMode = (paymentMode.trim().isEmpty)
        ? 'Cash'
        : paymentMode.trim();
    final nowIso = DateTime.now().toUtc().toIso8601String();

    // 🔵 Bill status logic
    if (dueAmount > 0) {
      bill.status = BillStatus.due.value;
      debugPrint("🔵 Bill #${bill.orderNumber} set to 'due'");
    } else {
      bill.status = BillStatus.settled.value;
      bill.endTime = nowIso;
      debugPrint("🟢 Bill #${bill.orderNumber} set to 'settled'");
    }

    // 🧾 Calculate Totals with Tax
    final storage = StorageRepository();
    final taxGroupsJson = storage.taxProductGroups;
    Map<String, dynamic> taxGroupsData = {};
    try {
      if (taxGroupsJson.isNotEmpty) {
        taxGroupsData = jsonDecode(taxGroupsJson);
      }
    } catch (e) {
      debugPrint("❌ Error decoding tax groups: $e");
    }

    double calculatedSubTotal = 0.0;
    double calculatedTotalTax = 0.0;

    for (var item in itemsForBill) {
      final fId = item['foodId'] as int? ?? 0;
      final qty = item['qty'] as int? ?? 0;
      final price = (item['price'] as num?)?.toDouble() ?? 0.0;
      final amount = price * qty;

      calculatedSubTotal += amount;

      // Calculate Tax
      double itemTaxAmount = 0.0;
      final foodEntity = boxEntityFood.get(fId);
      final taxGroupId = foodEntity?.hsnCode ?? "";

      if (taxGroupId.isNotEmpty && taxGroupsData.containsKey(taxGroupId)) {
        final group = taxGroupsData[taxGroupId];
        final taxValue = (group['taxValue'] ?? 0).toDouble();
        final taxType = group['taxType'] ?? 'Percentage';

        if (taxType == 'Percentage') {
          itemTaxAmount = (amount * taxValue) / 100;
        } else {
          itemTaxAmount = taxValue * qty;
        }
      }

      calculatedTotalTax += itemTaxAmount;
      item['taxAmount'] = itemTaxAmount; // Store for meta
    }

    final double totalAmount = calculatedSubTotal + calculatedTotalTax;

    // ---- APPLY DISCOUNT (option A: bill.discountAmount & bill.discountPercent) ----
    double discountAmount = (bill.discountAmount ?? 0.0);
    final double discountPercent = (bill.discountPercent ?? 0.0);

    if (discountPercent > 0) {
      discountAmount = (discountPercent / 100.0) * totalAmount;
      bill.discountAmount = discountAmount;
    }

    final double finalTotal = (totalAmount - discountAmount).clamp(
      0.0,
      double.infinity,
    );

    // Save amounts to bill + meta
    bill.totalAmount = finalTotal;

    try {
      final wrapper = {
        'meta': {
          'customerName': bill.customerName ?? '',
          'customerMobile': bill.customerMobile ?? '',
          'customerAddress': bill.customerAddress ?? '',
          'paymentMode': payMode,
          'referenceNo': referenceNo ?? '',
          'waiterName': bill.waiterName ?? '',
          'settledAt': nowIso,
          'dueAmount': dueAmount,
          'tipAmount': tipAmount,
          'subTotal': calculatedSubTotal, // ✅ Added
          'totalTax': calculatedTotalTax, // ✅ Added
          'originalTotal': totalAmount,
          'discountPercent': discountPercent,
          'discountAmount': discountAmount,
          'finalTotal': finalTotal,
        },
        'items': itemsForBill,
      };
      (bill as dynamic).itemsJson = jsonEncode(wrapper);
      (bill as dynamic).totalQty = itemsForBill.fold<int>(
        0,
        (p, e) => p + ((e['qty'] as int?) ?? 0),
      );
    } catch (e) {
      debugPrint("⚠️ JSON build failed: $e");
    }

    bill.customerName = customerName ?? bill.customerName ?? "";
    bill.customerMobile = customerMobile ?? bill.customerMobile ?? "";
    bill.customerAddress = customerAddress ?? bill.customerAddress ?? "";

    // ✅ Save waiter info
    bill.waiterName = waiterName ?? bill.waiterName;
    bill.waiterId = waiterId ?? bill.waiterId;

    // 🧠 JSON for meta + items
    try {
      final wrapper = {
        'meta': {
          'customerName': bill.customerName ?? '',
          'customerMobile': bill.customerMobile ?? '',
          'customerAddress': bill.customerAddress ?? '',
          'paymentMode': payMode,
          'referenceNo': referenceNo ?? '',
          'waiterName': bill.waiterName ?? '', // ✅ include waiter in JSON
          'settledAt': nowIso,
          'dueAmount': dueAmount,
          'tipAmount': tipAmount,
          'subTotal': calculatedSubTotal, // ✅ Added
          'totalTax': calculatedTotalTax, // ✅ Added
        },
        'items': itemsForBill,
      };
      (bill as dynamic).itemsJson = jsonEncode(wrapper);
      (bill as dynamic).totalQty = itemsForBill.fold<int>(
        0,
        (p, e) => p + ((e['qty'] as int?) ?? 0),
      );
    } catch (e) {
      debugPrint("⚠️ JSON build failed: $e");
    }

    // 💵 Attach payment
    try {
      // ✅ Fixed: Only create default payment if bill is settled AND no payments provided
      final List<Payment> paymentEntities;

      if (payments.isNotEmpty) {
        // Use provided payments
        paymentEntities = payments
            .map(
              (p) => Payment(price: p.amount, mode: p.mode, utr: p.reference),
            )
            .toList();
      } else if (dueAmount <= 0) {
        // Fully settled with no payment records = assume full payment in selected mode
        paymentEntities = [
          Payment(price: finalTotal, mode: payMode, utr: referenceNo),
        ];
      } else {
        // Due bill with no payments = empty array (nothing paid yet)
        paymentEntities = [];
      }

      await attachPaymentsToBill(
        bill,
        itemsForBill,
        paymentEntities,
        paymentLabel: payMode,
        overallReference: referenceNo,
        due: dueAmount,
        tip: tipAmount,
        tipMode: tipPaymentMode,
      );
    } catch (e, st) {
      debugPrint("⚠️ Failed to attach payments: $e\n$st");
    }

    // 💾 Persist bill
    boxEntityOrder.put(bill);
    // 👇 FIX: Ensure bill has all KOT items before sync
    final kotItems = bill.listFood.toList();

    // If itemsFromKOT are missing, load them from DB
    if (kotItems.isEmpty) {
      final foods = boxEntityOrderFood
          .query(EntityOrderFood_.orderId.equals(bill.orderId))
          .build()
          .find();

      if (foods.isNotEmpty) {
        bill.listFood.clear();
        bill.listFood.addAll(foods);
        bill.listFood.applyToDb();
      }
    }
    bill = boxEntityOrder.get(bill.orderId)!;
    // final storage = StorageRepository(); // Already defined above
    if (storage.isSyncFeature &&
        (bill.status == BillStatus.settled.value ||
            bill.status == BillStatus.due.value)) {
      await pushOrder(bill);
    }
    debugPrint(
      "💾 Bill ${bill.orderNumber} saved with waiter='${bill.waiterName}'",
    );

    // 🔄 Refresh sales report immediately
    try {
      if (Get.isRegistered<ControllerSales>()) {
        final sales = Get.find<ControllerSales>();
        await sales.fetchFromBills();
        sales.update();
      }
    } catch (e) {
      debugPrint("⚠️ Failed to refresh sales: $e");
    }

    // 🖨️ Print Bill (with waiter shown)
    if (printAfterSettle) {
      await _tryPrintBill(bill, itemsForBill);
    }

    // 🧹 Mark table settled
    if (bill.status == BillStatus.settled.value) {
      final tableController = Get.find<ControllerTable>();
      tableController.handleOrderSettled(tName);
      markBillSettledAndClear(tableNameOverride: tName);
    } else {
      Get.find<ControllerTable>().refreshBookedFromBills();
      update();
    }
    try {
      if (Get.isRegistered<ReceiptController>()) {
        Get.find<ReceiptController>().refresh();
      }
    } catch (_) {}

    // Optional report refresh
    try {
      if (Get.isRegistered<ControllerKotReports>()) {
        Get.find<ControllerKotReports>().refresh();
      }
    } catch (_) {}

    // 🔄 SYNC COUNTERS TO SERVER
    controllerSetting.updateRestaurantCountersOnServer();

    debugPrint(
      "✅ Bill ${bill.orderId} (${bill.orderNumber}) settled. Waiter='${bill.waiterName}', Total=₹${totalAmount.toStringAsFixed(2)}",
    );
  }

  String mapStatus(String? status) {
    switch (status) {
      case "settled":
        return "Completed";
      case "booked":
      case "pending":
      case "due":
        return "Active";
      case "cancelled":
      case "deleted":
        return "Cancelled";
      default:
        return "Active";
    }
  }

  String mapPaymentStatus(EntityOrder order) {
    final total = order.totalAmount ?? 0.0;
    if (total <= 0) return "Paid";

    final paid = order.payments.fold<double>(
      0,
      (sum, p) => sum + (p.price ?? 0),
    );

    if (paid >= total) return "Paid";
    if (paid > 0) return "PartiallyPaid";
    return "Unpaid"; // ✅ Fixed: Return "Unpaid" when nothing is paid
  }

  Future<void> pushOrder(EntityOrder order) async {
    final api = ApiClient();
    final storage = StorageRepository();

    // 1. Get tax groups from storage
    final taxGroupsJson = storage.taxProductGroups;
    Map<String, dynamic> taxGroupsData = {};
    try {
      if (taxGroupsJson.isNotEmpty) {
        taxGroupsData = jsonDecode(taxGroupsJson);
      }
    } catch (e) {
      debugPrint("❌ Error decoding tax groups: $e");
    }

    double calculatedSubTotal = 0.0;
    double calculatedTotalTax = 0.0;
    final items = <Map<String, dynamic>>[]; // ✅ Restored items list

    debugPrint("🔍 pushOrder: listFood length = ${order.listFood.length}");

    for (final f in order.listFood.toList()) {
      final fId = f.foodId ?? 0;
      final menuItem = boxEntityFood.get(fId);

      if (menuItem == null) {
        debugPrint("⚠️ pushOrder: MenuItem not found for foodId=$fId");
        continue;
      }
      debugPrint("✅ pushOrder: Found item '${menuItem.foodName}' (ID: $fId)");

      final foodEntity = boxEntityFood.get(fId);

      final qty = f.quantity ?? 0;
      final price = f.price ?? 0.0;
      final itemTotal = price * qty;

      calculatedSubTotal += itemTotal;

      // Calculate Tax
      double itemTaxAmount = 0.0;
      final taxGroupId =
          foodEntity?.hsnCode ?? ""; // mapped from taxProductGroupId

      if (taxGroupId.isNotEmpty && taxGroupsData.containsKey(taxGroupId)) {
        final group = taxGroupsData[taxGroupId];
        final taxValue = (group['taxValue'] ?? 0).toDouble();
        final taxType = group['taxType'] ?? 'Percentage';

        if (taxType == 'Percentage') {
          itemTaxAmount = (itemTotal * taxValue) / 100;
        } else {
          itemTaxAmount = taxValue * qty;
        }
      }

      calculatedTotalTax += itemTaxAmount;

      items.add({
        "menuItemId": foodEntity?.mongoId ?? "",
        "name": {"en": menuItem.foodName ?? "", "ar": menuItem.foodName ?? ""},
        "quantity": qty,
        "price": price,
        "taxAmount": itemTaxAmount,
        "notes": "",
      });
    }

    // Helper to map local modes to server enums
    String mapToValidServerEnum(String mode) {
      final m = mode.trim().toLowerCase();
      if (m.contains("cash")) return "Cash";
      if (m.contains("card") ||
          m.contains("visa") ||
          m.contains("master") ||
          m.contains("credit") ||
          m.contains("debit"))
        return "Card";
      if (m.contains("upi") ||
          m.contains("paytm") ||
          m.contains("google") ||
          m.contains("phonepe") ||
          m.contains("gpay") ||
          m.contains("bhim"))
        return "UPI";
      return "Other";
    }

    List<Map<String, dynamic>> paymentList;

    if (order.payments.isEmpty) {
      // If settled but no payments recorded, assume full Cash (legacy behavior)
      if (order.status == BillStatus.settled.value) {
        paymentList = [
          {
            "method": "Cash",
            "amount": calculatedSubTotal + calculatedTotalTax,
            "transactionId": "",
          },
        ];
      } else {
        // For Due/Booked/Active with no payments, send empty list (paid = 0)
        paymentList = [];
      }
    } else {
      paymentList = order.payments.map((p) {
        return {
          "method": mapToValidServerEnum(p.mode), // ✅ Use mapping
          "amount": p.price ?? 0,
          "transactionId": p.utr ?? "",
        };
      }).toList();
    }

    // ✅ Calculate amountPaid from paymentList
    final double calculatedAmountPaid = paymentList.fold<double>(
      0.0,
      (sum, item) => sum + ((item["amount"] as num?)?.toDouble() ?? 0.0),
    );

    String? resolveTableId() {
      final tableCtrl = Get.find<ControllerTable>();

      // Physical table → actual mongoId
      if (tableCtrl.selectedTable.value != null) {
        return tableCtrl.selectedTable.value!.mongoId;
      }

      // Temp order → send generated fake ObjectId
      if (tableCtrl.selectedTempTable.value != null) {
        return tableCtrl.selectedTempTable.value!.tableMongoId;
      }

      return null; // fallback
    }

    final body = {
      "restaurantId": storage.restaurantId,
      "orderTypeId": _resolveOrderTypeIdForSync(order.orderTypeId),

      "billNumber": "Bill-${order.orderNumber}",
      "brandId": storage.brandId,
      "tableId": resolveTableId(),
      "waiterId": storage.userId,
      "customerName": order.customerName ?? "",
      "customerPhone": order.customerMobile ?? "",
      "items": items,
      "totalAmount": calculatedSubTotal + calculatedTotalTax,
      "amountPaid": calculatedAmountPaid, // ✅ Use calculated amount
      "status": mapStatus(order.status),
      "paymentStatus": mapPaymentStatus(order),
      "subTotal": calculatedSubTotal,
      "payments": paymentList,
      "createdBy": storage.userId,
      "updatedBy": storage.userId,
      "createdAt": order.createdOn ?? DateTime.now().toUtc().toIso8601String(),
      "updatedAt": DateTime.now().toUtc().toIso8601String(),
      "closedAt": DateTime.now().toUtc().toIso8601String(),
    };

    // 🔵 PRINT WHAT YOU ARE SENDING
    debugPrint("🟦================ PUSH ORDER START ================");
    debugPrint("➡️ URL: ${ApiConstant.createOrder}");
    debugPrint("➡️ TOKEN: ${storage.accessToken}");
    debugPrint("➡️ REQUEST BODY:");
    debugPrint(jsonEncode(body));
    debugPrint("🟦=================================================");

    // 📩 API CALL
    Response resp;
    bool isUpdate = false;

    if (order.mongoId != null && order.mongoId!.isNotEmpty) {
      // UPDATE (PATCH)
      isUpdate = true;
      debugPrint(
        "🔄 pushOrder: Updating existing bill (PATCH) -> ${order.mongoId}",
      );
      resp = await api.patchRequestWithToken(
        "${ApiConstant.apiBase}/bills/${order.mongoId}",
        body,
      );
    } else {
      // CREATE (POST)
      isUpdate = false;
      debugPrint("🆕 pushOrder: Creating new bill (POST)");
      resp = await api.postRequestWithToken(ApiConstant.createOrder, body);
    }

    // 🔴 PRINT RESPONSE
    debugPrint("🟥================ API RESPONSE =================");
    debugPrint("⬅️ Status Code: ${resp.statusCode}");
    debugPrint("⬅️ Body: ${jsonEncode(resp.body)}");
    debugPrint("🟥================================================");

    // 🟢 SUCCESS CHECK
    final successCode = isUpdate ? 200 : 201;

    if (resp.statusCode == successCode && resp.body?["success"] == true) {
      final data = resp.body?["data"];
      if (data != null) {
        final serverId = data["_id"]?.toString() ?? data["id"]?.toString();
        if (serverId != null && serverId.isNotEmpty) {
          order.mongoId = serverId;
          debugPrint("✅ Saved mongoId: $serverId");
        }
      }
      order.isSync = true;
      boxEntityOrder.put(order);
      debugPrint("✅ ORDER SYNCED SUCCESSFULLY");
    } else {
      // ⚠️ Handle 400 "Bill number already exists"
      if (!isUpdate &&
          resp.statusCode == 400 &&
          resp.body.toString().contains("Bill number already exists")) {
        debugPrint(
          "⚠️ Bill exists on server but ID missing locally. Recovering...",
        );

        try {
          final searchUrl =
              "${ApiConstant.apiBase}/bills?billNumber=Bill-${order.orderNumber}&restaurantId=${storage.restaurantId}";
          final searchResp = await api.getRequestWithToken(searchUrl);

          if (searchResp.statusCode == 200 &&
              searchResp.body?["success"] == true) {
            final List docs = searchResp.body?["data"] ?? [];
            if (docs.isNotEmpty) {
              final serverBill = docs.first;
              final serverId =
                  serverBill["_id"]?.toString() ?? serverBill["id"]?.toString();

              if (serverId != null && serverId.isNotEmpty) {
                order.mongoId = serverId;
                boxEntityOrder.put(order);
                debugPrint("✅ Recovered ID: $serverId. Retrying with PATCH...");

                // 🔄 RETRY WITH PATCH
                final retryResp = await api.patchRequestWithToken(
                  "${ApiConstant.apiBase}/bills/$serverId",
                  body,
                );

                if (retryResp.statusCode == 200 &&
                    retryResp.body?["success"] == true) {
                  order.isSync = true;
                  boxEntityOrder.put(order);
                  debugPrint("✅ RETRY SYNC SUCCESSFUL (PATCH)");
                  return; // Exit success
                } else {
                  debugPrint("❌ RETRY FAILED: ${retryResp.body}");
                }
              }
            }
          }
        } catch (e) {
          debugPrint("❌ Recovery failed: $e");
        }
      }

      debugPrint("❌ SYNC FAILED → ${jsonEncode(resp.body)}");
    }
  }

  // helper inside same file (or ControllerOrder)
  String _resolveOrderTypeIdForSync(String? maybeIdOrLabel) {
    if (maybeIdOrLabel == null || maybeIdOrLabel.trim().isEmpty) return "";

    final v = maybeIdOrLabel.trim();

    // already a mongodb hex id?
    final objectIdRegex = RegExp(r'^[a-fA-F0-9]{24}$');
    if (objectIdRegex.hasMatch(v)) return v;

    // otherwise try to look up by label using ControllerOrderType
    try {
      final orderTypeCtrl = Get.find<ControllerOrderType>();
      final found = orderTypeCtrl.rxOrderTypes.firstWhereOrNull((m) {
        final name = ((m["name"] ?? {})["en"] ?? "").toString().trim();
        return name.toLowerCase() == v.toLowerCase();
      });
      if (found != null) return found["_id"]?.toString() ?? "";
    } catch (_) {}

    // fallback: return empty -> server will validate/fail
    return "";
  }

  // Avoid log truncation in adb logs
  void debugPrintLarge(String message) {
    if (!kDebugMode) return;
    const chunk = 800;
    for (var i = 0; i < message.length; i += chunk) {
      debugPrint(message.substring(i, math.min(i + chunk, message.length)));
    }
  }

  void logJson(String tag, Map<String, dynamic> data) {
    if (!kDebugMode) return;
    final enc = const JsonEncoder.withIndent('  ');
    debugPrintLarge('[$tag]\n${enc.convert(data)}');
  }

  Map<String, dynamic> billToMap(EntityOrder b) => {
    'orderId': b.orderId,
    'orderNumber': b.orderNumber,
    'status': b.status,
    'tableName': b.tableName,
    'tableSeat': b.tableSeat,
    'orderType': b.orderTypeId,
    'startTime': b.startTime,
    'endTime': b.endTime,
    'totalAmount': b.totalAmount,
  };

  Map<String, dynamic> foodToMap(EntityOrderFood f) => {
    'id': f.foodId ?? 0,
    'name': f.name ?? '',
    'category': f.category ?? '',
    'qty': f.quantity ?? 0,
    'price': f.price ?? 0.0,
    'amount': (f.price ?? 0.0) * (f.quantity ?? 0),
    'kot': f.kotNumber ?? 0,
    'uuid': f.uuid ?? '',
  };

  String prettyKot(
    EntityOrder bill,
    int kotNumber,
    String tableName,
    List<EntityOrderFood> items,
  ) {
    final sb = StringBuffer();
    sb.writeln(
      '===== KOT #$kotNumber | Table: $tableName | Order #${bill.orderNumber} =====',
    );
    for (final i in items) {
      final qty = i.quantity ?? 0;
      final price = i.price ?? 0.0;
      final amt = price * qty;
      sb.writeln(
        '• ${i.name}  x$qty  @ ${price.toStringAsFixed(2)}  = ${amt.toStringAsFixed(2)}',
      );
    }
    sb.writeln('===== /KOT =====');
    return sb.toString();
  }

  String prettyBill(EntityOrder bill, List<Map<String, dynamic>> items) {
    final sb = StringBuffer();
    sb.writeln('===== BILL #${bill.orderNumber} | ${bill.tableName} =====');
    double total = 0;
    for (final e in items) {
      final name = (e['name'] ?? '') as String;
      final qty = (e['qty'] as num?)?.toInt() ?? 0;
      final price = (e['price'] as num?)?.toDouble() ?? 0.0;
      final amount = (e['amount'] as num?)?.toDouble() ?? (price * qty);
      total += amount;
      sb.writeln(
        '• $name  x$qty  @ ${price.toStringAsFixed(2)}  = ${amount.toStringAsFixed(2)}',
      );
    }
    sb.writeln('Total: ${total.toStringAsFixed(2)}');
    sb.writeln('===== /BILL =====');
    return sb.toString();
  }

  void printKotPreview(KotGroup g) {
    try {
      if (Get.context != null) {
        final ctx = Get.context!;
        final items = g.items;

        showDialog(
          context: ctx,
          builder: (dctx) {
            return AlertDialog(
              title: Text('KOT ${g.kotNumber}'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Items: ${items.length}'),
                    const SizedBox(height: 8),
                    if (items.isEmpty)
                      const Text('No items.')
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final it = items[i];
                          final name = it.name ?? 'Item';
                          final qty = it.quantity ?? 1;
                          return ListTile(
                            title: Text(name.toString()),
                            trailing: Text('x$qty'),
                          );
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dctx).pop(),
                  child: const Text('Close'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // mark printed
                    final bill = getActiveBillForTableName(g.tableName ?? '');
                    if (bill != null) {
                      markKotGroupPrinted(bill, g);
                    }
                    Navigator.of(dctx).pop();
                  },
                  child: const Text('Mark Printed'),
                ),
              ],
            );
          },
        );
      } else {
        debugPrint('No Get.context available for printKotPreview');
      }
    } catch (e, st) {
      debugPrint('printKotPreview failed: $e\n$st');
    }
  }

  List<KotGroup> getAllKots() {
    final result = <KotGroup>[];
    final bills = boxEntityOrder.getAll();
    for (final b in bills) {
      result.addAll(_groupFoodsByKot(b.listFood.toList()));
    }
    return result;
  }

  // group foods into logical KOTs by kotNumber (and createdOn as tie-breaker)
  List<KotGroup> _groupFoodsByKot(List<EntityOrderFood> foods) {
    final map = <int, List<EntityOrderFood>>{};
    final createdOnByKot = <int, String?>{};
    final uuidByKot = <int, String?>{};
    final tableByKot = <int, String?>{};

    for (final f in foods) {
      final kn = f.kotNumber ?? -1;
      if (kn < 0) continue;
      (map[kn] ??= <EntityOrderFood>[]).add(f);
      // Keep the newest createdOn/uuid per KOT
      if (!createdOnByKot.containsKey(kn) ||
          _ts(f.createdOn).isAfter(_ts(createdOnByKot[kn]))) {
        createdOnByKot[kn] = f.createdOn;
        uuidByKot[kn] = f.uuid;
        tableByKot[kn] = f.tableName;
      }
    }

    final groups = <KotGroup>[];
    map.forEach((kn, items) {
      groups.add(
        KotGroup(
          kotNumber: kn,
          items: items,
          createdOn: createdOnByKot[kn],
          uuid: uuidByKot[kn],
          tableName: tableByKot[kn],
        ),
      );
    });
    return groups;
  }

  // draft

  Future<void> saveDraftUnprinted({
    String? tableName,
    bool clearLocal = true,
    int tableSeat = 0,
  }) async {
    final t = _resolveTableName(tableName);
    if (t.isEmpty) return;

    _ensureTableEntry(t);
    final data = _tableOrders[t]!;
    final hasLocal = data.orderItems.isNotEmpty || data.extraItems.isNotEmpty;
    if (!hasLocal) return;

    // Ensure bill exists (keeps table "booked" across reloads)
    final bill = await getOrCreateOpenBillForTable(t, tableSeat: tableSeat);
    _ensureBillHasUuid(bill);

    final now = DateTime.now().toUtc().toIso8601String();
    final draftRows = <EntityOrderFood>[];

    // Normal items as DRAFT (kotNumber = null)
    data.orderItems.forEach((food, qty) {
      final price = food.price.isNotEmpty
          ? (food.price.first.price ?? 0.0)
          : 0.0;
      draftRows.add(
        EntityOrderFood(
          orderId: bill.orderId,
          foodId: food.foodId ?? 0,
          name: food.foodName ?? '',
          category: (food.categoryName ?? ''),
          taxPercentage: 0,
          quantity: qty,
          price: price,
          kotNumber: null, // DRAFT (unsent)
          uuid: _generateUuid(),
          createdOn: now,
          tableName: t,
          origin: _currentOrigin(),
          orderType: bill.orderTypeId,
        ),
      );
    });

    // Extras as DRAFT (kotNumber = null)
    for (final ex in data.extraItems) {
      draftRows.add(
        EntityOrderFood(
          orderId: bill.orderId,
          foodId: 0,
          name: ex.name,
          category: 'Extras',
          taxPercentage: 0,
          quantity: ex.qty,
          price: ex.price,
          kotNumber: null, // DRAFT (unsent)
          uuid: _generateUuid(),
          createdOn: now,
          tableName: t,
          origin: _currentOrigin(),
          orderType: bill.orderTypeId,
        ),
      );
    }

    if (draftRows.isEmpty) return;

    // Persist to DB (no sockets, no print)
    bill.listFood.addAll(draftRows);
    bill.listFood.applyToDb();
    bill.restUuid = bill.restUuid ?? _getRestaurantUuid();

    boxEntityOrder.put(bill);

    // Optional meta flags
    final meta = _safeDecodeMap(bill.metaJson);
    meta['hasDraftLines'] = true;
    meta['lastDraftAt'] = now;
    try {
      (bill as dynamic).metaJson = jsonEncode(meta);
      boxEntityOrder.put(bill);
    } catch (_) {}

    // Clear local cart (so duplicates aren't re-saved)
    if (clearLocal) {
      data.orderItems.clear();
      data.extraItems.clear();
    }

    // Keep table marked as booked and refresh UI
    try {
      Get.find<ControllerTable>().markTableBooked(t);
    } catch (_) {}

    rebuildUnifiedKotList(tableName: t); // unified list includes draft rows
    getTotalPrice(forTable: t); // totals include draft rows too
    update();

    debugPrint(
      "💾 Draft saved (kotNumber=null) for $t — rows=${draftRows.length}",
    );
  }
}

class TableOrderData {
  /// Items added to cart but not yet printed (food items).
  RxMap<EntityFood, int> orderItems;

  /// Extra non-menu items (manual add-ons, like "Water Bottle").
  RxList<ExtraItem> extraItems;

  /// Items already printed as part of a KOT (read-only in UI).
  RxList<KotUiItem> kotItems;

  /// Tracks food IDs that have been printed, to prevent duplication.
  Set<int> printedFoodIds;

  TableOrderData({
    RxMap<EntityFood, int>? orderItems,
    RxList<ExtraItem>? extraItems,
    RxList<KotUiItem>? kotItems,
    Set<int>? printedFoodIds,
  }) : orderItems = orderItems ?? <EntityFood, int>{}.obs,
       extraItems = extraItems ?? <ExtraItem>[].obs,
       kotItems = kotItems ?? <KotUiItem>[].obs,
       printedFoodIds = printedFoodIds ?? <int>{};
}

// helper to aggregate normal foods by foodId
class _AggLine {
  final EntityFood food;
  int qty;
  _AggLine(this.food, this.qty);
}

extension _BillJsonMeta on EntityOrder {
  Map<String, dynamic> readItemsWrapper() {
    try {
      final j = (this as dynamic).itemsJson as String?;
      if (j != null && j.isNotEmpty) {
        final d = jsonDecode(j);
        if (d is Map<String, dynamic>) return d;
      }
    } catch (_) {}
    return <String, dynamic>{};
  }
}

// Small helper to represent a KOT batch from listFood
class KotGroup {
  final int kotNumber;
  final String? uuid;
  final String? createdOn;
  final String? tableName;
  final List<EntityOrderFood> items;

  KotGroup({
    required this.kotNumber,
    required this.items,
    this.uuid,
    this.createdOn,
    this.tableName,
  });

  bool get isPrinted => items.isNotEmpty && items.every((i) => i.isPrinted);
}
