// import 'dart:convert';
// import 'dart:async';
// import 'package:cap/captain/serverList/controller_server_selection.dart';
// import 'package:cap/objectbox.g.dart';
// import 'package:cap/screens/category_food/controller_category_food.dart';
// import 'package:cap/services/controller_server.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// import '../../model/entity_kot.dart';

// class KOT {
//   final int id;
//   final int kotNumber;
//   final String table;
//   final String customer;
//   String status;
//   final List<String> items;
//   final int qty;
//   final Duration time;
//   final String origin;

//   KOT({
//     required this.id,
//     required this.kotNumber,
//     required this.table,
//     required this.customer,
//     required this.status,
//     required this.items,
//     required this.qty,
//     required this.time,
//     required this.origin,
//   });

//   @override
//   String toString() {
//     return "KOT(id: $id, kotNo: $kotNumber, table: $table, origin: $origin, status: $status, qty: $qty, items: $items, time: $time)";
//   }
// }

// class KOTController extends GetxController {
//   var kotList = <KOT>[].obs;
//   Box<EntityKot> boxEntityKot = Get.find();
//   var tokenViewMode = true.obs;
//   var orderType = "All".obs;
//   var kotStatus = "All".obs;
//   var onlyTokenNumber = false.obs;
//   var enhancedTokenView = true.obs;
//   var displayLogo = false.obs;
//   var displayBrandName = false.obs;
//   var displayCustomerName = false.obs;

//   Timer? _timer;

//   int get pendingCount =>
//       kotList.where((kot) => kot.status != "Settled").length;

//   @override
//   void onInit() {
//     super.onInit();
//     debugPrint("📢 KOTController initialized");

//     kotList.clear();

//     if (Get.isRegistered<ControllerServer>()) {
//       final server = Get.find<ControllerServer>();

//       ever<List<String>>(server.messages, (list) {
//         if (list.isNotEmpty) {
//           final lastMsg = list.last;
//           processSingleMessage(lastMsg);
//         }
//       });

//       _startTimer();
//     } else {
//       debugPrint("⚠️ ControllerServer is NOT registered yet!");
//     }
//   }

//   /// Call this to push a new KOT from server or local creation
//   void receiveNewKOT(Map<String, dynamic> kotData) {
//     _addOrUpdateKot(kotData); // reuse your existing private method
//     debugPrint("📡 KOT #${kotData['kotNumber']} received via receiveNewKOT");
//   }

//   void _startTimer() {
//     _timer?.cancel();
//     _timer = Timer.periodic(const Duration(seconds: 1), (_) {
//       kotList.refresh();
//     });
//   }
// void processSingleMessage(String msg) {
//   try {
//     final parsed = jsonDecode(msg);

//     final type = parsed['type']?.toString() ?? '';

//     if (type == 'kot') {
//       final data = parsed['data'];
//       if (data != null) _addOrUpdateKot(data);
//       debugPrint("📩 Processing new KOT message: $msg");
//     }

//     // ✅ NEW: handle status update
//     else if (type == 'kotStatusUpdate') {
//       final kotNumber = parsed['kotNumber'] as int?;
//       final status = parsed['status']?.toString();

//       if (kotNumber != null && status != null) {
//         final index = kotList.indexWhere((k) => k.kotNumber == kotNumber);
//         if (index != -1) {
//           kotList[index].status = status;
//           kotList.refresh();

//           Get.snackbar(
//             "KOT #$kotNumber",
//             "Status updated ➜ $status",
//             snackPosition: SnackPosition.BOTTOM,
//             duration: const Duration(seconds: 2),
//           );

//           debugPrint("✅ KOT #$kotNumber status updated locally to $status");
//         }
//       }
//     }
//   } catch (e) {
//     debugPrint("⚠️ Error parsing server message: $e");
//   }
// }

//   void _addOrUpdateKot(Map<String, dynamic> kotData) {
//     final existingIndex = kotList.indexWhere((k) => k.id == kotData['kotId']);

//     final itemsJsonStr = kotData['itemsJson'];
//     final items = (jsonDecode(itemsJsonStr ?? '{"items": []}')['items'] as List)
//         .map<String>((it) => "${it['qty']} × ${it['name']}")
//         .toList();

//     final qty = items.fold<int>(0, (p, it) {
//       final match = RegExp(r'^(\d+)').firstMatch(it);
//       return p + (match != null ? int.parse(match.group(1)!) : 0);
//     });

//     final kot = KOT(
//       id: kotData['kotNumber'] ?? 0, // use kotNumber as id if kotId is missing
//       kotNumber: kotData['kotNumber'] ?? 0,
//       table: kotData['tableName'] ?? "Unknown",
//       customer: "Guest",
//       status: kotData['status'] ?? "Placed",
//       items: items,
//       qty: qty,
//       time: DateTime.tryParse(kotData['createdOn'] ?? "") != null
//           ? DateTime.now().difference(
//               DateTime.parse(kotData['createdOn'] ?? ""),
//             )
//           : Duration.zero,
//       origin: kotData['origin'] ?? "Server",
//     );

//     if (existingIndex >= 0) {
//       kotList[existingIndex] = kot;
//     } else {
//       kotList.add(kot);
//     }

//     kotList.refresh();
//     debugPrint("✅ KOT updated/added in KDS: $kot");
//     debugPrint(
//       "🧩 KOT Parsed: id=${kotData['kotId']} | table=${kotData['tableName']} | items=${kot.items.length}",
//     );
//     debugPrint("📋 KOT List now: ${kotList.length}");
//   }

//   final kotUnifiedItems = <ExtraItem>[].obs;
//   void updateKOTStatus(int kotNumber, String newStatus) {
//   final index = kotList.indexWhere((k) => k.kotNumber == kotNumber);

//   if (index != -1) {
//     kotList[index].status = newStatus;
//     kotList.refresh();
//     debugPrint("✅ KOT #$kotNumber status updated to $newStatus");

//     // Notify server (fire-and-forget)
//     if (Get.isRegistered<ControllerServerSelection>()) {
//       final serverSel = Get.find<ControllerServerSelection>();
//       serverSel.sendToServer(jsonEncode({
//         "type": "kotStatusUpdate",
//         "kotNumber": kotNumber,
//         "status": newStatus,
//       }));
//     }

//     // Optional: remove KOT locally if served
//     if (newStatus == "Served") {
//       Future.delayed(const Duration(seconds: 1), () {
//         kotList.removeWhere((k) => k.kotNumber == kotNumber);
//         kotList.refresh();
//         debugPrint("🗑 KOT #$kotNumber removed locally after serving");
//       });
//     }
//   }
// }

//   void rebuildUnifiedKotList({required String tableName}) {
//     final normalizedTable = tableName.trim();

//     try {
//       final kotQuery = boxEntityKot
//           .query(EntityKot_.tableName.equals(normalizedTable))
//           .order(EntityKot_.createdOn, flags: Order.descending)
//           .build();

//       final latestKot = kotQuery.findFirst();
//       kotQuery.close();

//       if (latestKot == null ||
//           latestKot.itemsJson == null ||
//           latestKot.itemsJson!.isEmpty) {
//         kotUnifiedItems.clear();
//         debugPrint("ℹ No KOT found for [$normalizedTable]");
//         return;
//       }

//       // ✅ Decode only latest kot items
//       final mergedItems = <ExtraItem>[];
//       try {
//         final decoded = jsonDecode(latestKot.itemsJson!);
//         final items = (decoded['items'] as List?) ?? [];
//         for (final item in items) {
//           final qtyRaw = item['qty'] ?? 0;
//           final priceRaw = item['price'] ?? 0;

//           mergedItems.add(
//             ExtraItem(
//               id: item['id']?.toString() ?? "0",
//               name: item['name'] ?? "Unnamed",
//               qty: qtyRaw is int
//                   ? qtyRaw
//                   : int.tryParse(qtyRaw.toString()) ?? 0,
//               price: priceRaw is double
//                   ? priceRaw
//                   : double.tryParse(priceRaw.toString()) ?? 0.0,
//             ),
//           );
//         }
//       } catch (e, st) {
//         debugPrint("⚠ Error decoding latest KOT itemsJson: $e\n$st");
//       }

//       // ✅ Assign directly (no merge with old KOTs)
//       kotUnifiedItems.assignAll(mergedItems);
//       debugPrint(
//         "✅ Latest KOT List for [$normalizedTable]: ${kotUnifiedItems.length} items",
//       );
//     } catch (e, st) {
//       debugPrint("⚠ rebuildUnifiedKotList (latest only) failed: $e\n$st");
//       kotUnifiedItems.clear();
//     }
//   }

//   @override
//   void onClose() {
//     _timer?.cancel();
//     super.onClose();
//   }
// }
