import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/captain/serverList/controller_server_selection.dart';
import 'package:splash_screen_03/model/entity_bill_food.dart';
import 'package:splash_screen_03/model/entity_kot.dart';
import 'package:splash_screen_03/objectbox.g.dart';
import 'package:splash_screen_03/services/controller_server.dart';

// UI model for a KDS card
class KOT {
  final int id;
  final int kotNumber;
  final String table;
  final String customer;
  String status;
  final List<String> items;
  final int qty;
  final DateTime createdOn;
  final String origin;
  final String orderType;

  KOT({
    required this.id,
    required this.kotNumber,
    required this.table,
    required this.customer,
    required this.status,
    required this.items,
    required this.qty,
    required this.createdOn,
    required this.origin,
    required this.orderType,
  });

  Duration get age => DateTime.now().difference(createdOn);

  @override
  String toString() {
    return "KOT(id: $id, kotNo: $kotNumber, table: $table, origin: $origin, orderType: $orderType, status: $status, qty: $qty, items: $items, age: $age)";
  }
}

class KOTController extends GetxController {
  var kotList = <KOT>[].obs;
  Box<EntityOrderFood> boxEntityKot = Get.find();

  // Filters
  var tokenViewMode = true.obs;
  var orderType = "All".obs;
  var kotStatus = "All".obs;

  // Display toggles (hooked from UI)
  var onlyTokenNumber = false.obs;
  var enhancedTokenView = true.obs;
  var displayLogo = false.obs;
  var displayBrandName = false.obs;
  var displayCustomerName = false.obs;

  // Sorting
  final bool latestFirst = true;

  Timer? _timer;

  int get pendingCount =>
      kotList.where((kot) => kot.status != "Settled").length;

  @override
  void onInit() {
    super.onInit();
    debugPrint("📢 KOTController initialized");

    // Restore saved KOTs (only those having itemsJson)
    final savedKots = boxEntityKot
        .getAll()
        .where(
          (k) =>
              (k.status ?? '') != 'Served' &&
              (k.itemsJson?.isNotEmpty ?? false),
        )
        .map(_kotFromEntity)
        .where((kot) => kot.age.inHours < 24)
        .toList();

    kotList.assignAll(savedKots);
    _sortKotList();
    debugPrint(
      "📦 Restored ${savedKots.length} KOTs from storage (within 24 hours)",
    );

    _startTimer();

    // Wait until ControllerServer is registered, then listen to messages
    everAll([1.obs], (_) async {
      while (!Get.isRegistered<ControllerServer>()) {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      final server = Get.find<ControllerServer>();
      debugPrint("✅ ControllerServer found and registered for KOT listening");

      ever<List<String>>(server.messages, (list) {
        if (list.isNotEmpty) {
          final lastMsg = list.last.trim();
          // Ignore non-JSON log lines
          if (!(lastMsg.startsWith('{') || lastMsg.startsWith('['))) return;
          processSingleMessage(lastMsg);
        }
      });
    });
  }

  KOT _kotFromEntity(EntityOrderFood entity) {
    final items =
        (jsonDecode(entity.itemsJson ?? '{"items": []}')['items'] as List)
            .map<String>((it) => "${it['qty']} × ${it['name']}")
            .toList();

    final qty = items.fold<int>(0, (p, it) {
      final m = RegExp(r'^(\d+)').firstMatch(it);
      return p + (m != null ? int.parse(m.group(1)!) : 0);
    });

    return KOT(
      id: entity.kotNumber ?? 0,
      kotNumber: entity.kotNumber ?? 0,
      table: entity.tableName ?? "Unknown",
      customer: "Guest",
      status: entity.status ?? "Placed",
      items: items,
      qty: qty,
      createdOn: DateTime.tryParse(entity.createdOn ?? "") ?? DateTime.now(),
      origin: entity.origin ?? "Server",
      orderType: entity.orderType ?? "Dine-In",
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Drop very old KOTs
      kotList.removeWhere((kot) => kot.age.inHours >= 24);
      kotList.refresh();
    });
  }

  // Robust message handler (supports concatenated messages)
  void processSingleMessage(String msg) {
    try {
      final cleaned = msg.trim();
      // Split by newline-delimited or "}{"
      final parts = cleaned
          .split('\n')
          .expand((line) => line.split(RegExp(r'(?<=})\s*(?=\{)')))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      for (final part in parts) {
        final parsed = jsonDecode(part);
        final type = parsed['type']?.toString() ?? '';

        if (type == 'kot') {
          final data = parsed['data'];
          if (data != null) {
            final createdOnString = data['createdOn'] as String?;
            if (createdOnString != null) {
              final createdOn = DateTime.tryParse(createdOnString);
              if (createdOn != null &&
                  DateTime.now().difference(createdOn).inHours >= 24) {
                debugPrint(
                  "Ignoring KOT #${data['kotNumber']} - older than 24 hours.",
                );
                continue;
              }
            }
            _addOrUpdateKot(Map<String, dynamic>.from(data));
          }
          debugPrint("📩 Processing new KOT message: $part");
        } else if (type == 'kotStatusUpdate') {
          final kotNumber = parsed['kotNumber'] as int?;
          final status = parsed['status']?.toString();
          if (kotNumber != null && status != null) {
            final index = kotList.indexWhere((k) => k.kotNumber == kotNumber);
            if (index != -1) {
              kotList[index].status = status;
              kotList.refresh();
              Get.snackbar("KOT #$kotNumber", "Status updated ➜ $status");
            }
          }
        } else if (type == 'billSettled') {
          final data = parsed['data'] ?? {};
          final tableName = (data['tableName'] ?? '').toString();
          final billNo = data['orderNumber']?.toString() ?? '';
         

          // Remove all KOTs for this table (bill settled)
          if (tableName.isNotEmpty) {
            _removeAllKotsForTable(tableName);
          }

          Get.snackbar(
            "💰 Bill #$billNo Settled",
            "Table: $tableName",
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
          );
          debugPrint("📩 Bill Settled received: $part");
        }
      }
    } catch (e) {
      debugPrint("⚠️ Error parsing server message: $e\n$msg");
    }
  }

  // KEY FIX: do not key by table+origin. Key by kotNumber so multiple KOTs per table are shown.
  void _addOrUpdateKot(Map<String, dynamic> kotData) {
    final tableName = (kotData['tableName'] ?? '').toString().trim();
    final kotNumber = _parseIntSafe(kotData['kotNumber']);
    if (kotNumber <= 0) {
      debugPrint("⚠️ KOT missing kotNumber, ignoring payload: $kotData");
      return;
    }

    // Parse itemsJson safely
    final itemsJsonStr = kotData['itemsJson'];
    List itemsList = [];
    try {
      final decoded = (itemsJsonStr is String)
          ? jsonDecode(itemsJsonStr)
          : itemsJsonStr;
      if (decoded is Map && decoded['items'] is List) {
        itemsList = decoded['items'];
      } else if (decoded is List) {
        itemsList = decoded;
      }
    } catch (e) {
      debugPrint("⚠ itemsJson parse failed for KOT #$kotNumber: $e");
    }

    final items = itemsList
        .map((it) => it is Map ? "${it['qty']} × ${it['name']}" : it.toString())
        .toList()
        .cast<String>();

    final qty = items.fold<int>(0, (p, it) {
      final match = RegExp(r'^(\d+)').firstMatch(it);
      return p + (match != null ? int.parse(match.group(1)!) : 0);
    });

    final kot = KOT(
      id: kotNumber,
      kotNumber: kotNumber,
      table: tableName,
      customer: "Guest",
      status: kotData['status']?.toString() ?? "Placed",
      items: items,
      qty: qty,
      createdOn:
          DateTime.tryParse(kotData['createdOn']?.toString() ?? "") ??
          DateTime.now(),
      origin: kotData['origin']?.toString() ?? "captain",
      orderType: kotData['orderType']?.toString() ?? "Dine-In",
    );

    // If same kotNumber exists, update; else add a new KOT card
    final existingIndex = kotList.indexWhere((k) => k.kotNumber == kotNumber);
    if (existingIndex >= 0) {
      kotList[existingIndex] = kot;
      debugPrint("🔁 Updated KOT #$kotNumber (table: $tableName)");
    } else {
      kotList.add(kot);
      debugPrint("🆕 Added KOT #$kotNumber (table: $tableName)");
    }

    _sortKotList();
    kotList.refresh();

    // Persist a single compact row representing this KOT (overwrite by kotNumber)
    final entity = EntityOrderFood(
      kotNumber: kot.kotNumber,
      tableName: kot.table,
      itemsJson: (itemsJsonStr is String)
          ? itemsJsonStr
          : jsonEncode({"items": itemsList}),
      status: kot.status,
      createdOn:
          kotData['createdOn']?.toString() ?? DateTime.now().toIso8601String(),
      origin: kot.origin,
      foodId: null,
      name: '',
      category: '',
      taxPercentage: null,
    );

    try {
      final query = boxEntityKot
          .query(EntityOrderFood_.kotNumber.equals(kot.kotNumber))
          .build();
      final existing = query.findFirst();
      query.close();

      if (existing != null) entity.kotId = existing.kotId;
      boxEntityKot.put(entity);
    } catch (e) {
      debugPrint("⚠ Failed to persist KOT #$kotNumber to storage: $e");
    }
  }

  // Remove all KOTs for a settled table (and from storage)
  void _removeAllKotsForTable(String tableName) {
    final t = tableName.trim().toLowerCase();
    if (t.isEmpty) return;

    final before = kotList.length;
    kotList.removeWhere((k) => k.table.toLowerCase() == t);
    kotList.refresh();

    // Remove from ObjectBox as well
    try {
      final q = boxEntityKot
          .query(EntityOrderFood_.tableName.equals(tableName))
          .build();
      final removed = q.remove();
      q.close();
      debugPrint(
        "🗑 Removed $removed KOT row(s) from storage for [$tableName]",
      );
    } catch (e) {
      debugPrint("⚠ Failed to remove KOTs from storage for [$tableName]: $e");
    }

    debugPrint(
      "🧹 Bill settled ➜ cleared ${before - kotList.length} KOT(s) for [$tableName]",
    );
  }

  final kotUnifiedItems = <ExtraItem>[].obs;

  // Update status from UI dropdown
  void updateKOTStatus(int kotNumber, String newStatus) {
    final index = kotList.indexWhere((k) => k.kotNumber == kotNumber);

    if (index != -1) {
      kotList[index].status = newStatus;
      kotList.refresh();
      debugPrint("✅ KOT #$kotNumber status updated to $newStatus");

      if (Get.isRegistered<ControllerServerSelection>()) {
        final serverSel = Get.find<ControllerServerSelection>();
        serverSel.sendToServer(
          jsonEncode({
            "type": "kotStatusUpdate",
            "kotNumber": kotNumber,
            "status": newStatus,
          }),
        );
      }

      if (newStatus == "Served") {
        Future.delayed(const Duration(seconds: 1), () {
          kotList.removeWhere((k) => k.kotNumber == kotNumber);
          kotList.refresh();
          debugPrint("🗑 KOT #$kotNumber removed locally after serving");

          // Remove from ObjectBox
          final query = boxEntityKot
              .query(EntityOrderFood_.kotNumber.equals(kotNumber))
              .build();
          final removedCount = query.remove();
          query.close();

          if (removedCount > 0) {
            debugPrint(
              "🗑 Removed $removedCount record(s) for KOT #$kotNumber from storage.",
            );
          } else {
            debugPrint(
              "⚠️ Could not find KOT #$kotNumber in storage to remove.",
            );
          }
        });
      }
    }
  }

  // For POS-side screen that wants only latest KOT items (unchanged)
  void rebuildUnifiedKotList({required String tableName}) {
    final normalizedTable = tableName.trim();

    try {
      final kotQuery = boxEntityKot
          .query(EntityOrderFood_.tableName.equals(normalizedTable))
          .order(EntityOrderFood_.createdOn, flags: Order.descending)
          .build();

      final latestKot = kotQuery.findFirst();
      kotQuery.close();

      if (latestKot == null ||
          latestKot.itemsJson == null ||
          latestKot.itemsJson!.isEmpty) {
        kotUnifiedItems.clear();
        debugPrint("ℹ No KOT found for [$normalizedTable]");
        return;
      }

      final mergedItems = <ExtraItem>[];
      try {
        final decoded = jsonDecode(latestKot.itemsJson!);
        final items = (decoded['items'] as List?) ?? [];
        for (final item in items) {
          final qtyRaw = item['qty'] ?? 0;
          final priceRaw = item['price'] ?? 0;

          mergedItems.add(
            ExtraItem(
              id: item['id']?.toString() ?? "0",
              name: item['name'] ?? "Unnamed",
              qty: qtyRaw is int
                  ? qtyRaw
                  : int.tryParse(qtyRaw.toString()) ?? 0,
              price: priceRaw is double
                  ? priceRaw
                  : double.tryParse(priceRaw.toString()) ?? 0.0,
            ),
          );
        }
      } catch (e, st) {
        debugPrint("⚠ Error decoding latest KOT itemsJson: $e\n$st");
      }

      kotUnifiedItems.assignAll(mergedItems);
      debugPrint(
        "✅ Latest KOT List for [$normalizedTable]: ${kotUnifiedItems.length} items",
      );
    } catch (e, st) {
      debugPrint("⚠ rebuildUnifiedKotList (latest only) failed: $e\n$st");
      kotUnifiedItems.clear();
    }
  }

  void _sortKotList() {
    kotList.sort((a, b) {
      final cmp = a.createdOn.compareTo(b.createdOn);
      return latestFirst ? -cmp : cmp;
    });
  }

  int _parseIntSafe(dynamic v, {int defaultValue = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? defaultValue;
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
