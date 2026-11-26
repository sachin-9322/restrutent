// ControllerServer - Hardened and defensive implementation
// - KOTs are stored as EntityOrderFood rows under EntityOrder.listFood
// - Broadcasts also push JSON to `messages` so in-app KDS (KOTController) updates instantly
// - Defensive socket handling preserved

import 'dart:io';
import 'dart:convert';
import 'package:splash_screen_03/model/entity_printer.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/raw_pritner_service.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Condition;
import 'package:objectbox/objectbox.dart' hide Condition;
import 'package:splash_screen_03/printer/printer_configuration.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/wifi_pritner.dart';
import 'package:uuid/uuid.dart';

import '../model/entity_bill.dart';
import '../model/entity_cateogry_tax.dart';
import '../model/entity_food.dart';
import '../model/entity_table.dart';
import '../model/entity_user.dart';
import '../model/entity_room_type.dart';
import '../model/entity_bill_food.dart';
import '../objectbox.g.dart';

import '../screens/home/fragments/order/controller_order.dart';
import '../screens/home/fragments/table_type/controller_table.dart';

class ControllerServer extends GetxController {
  ServerSocket? _server;
  RawDatagramSocket? _udp;

  final RxBool isRunning = false.obs;
  final RxList<String> messages = <String>[].obs;

  // Generic clients (KDS and possibly others)
  final List<Socket> _clients = [];
  // Captain-only clients (logged in as captain)
  final List<Socket> _captainClients = [];

  // ObjectBox boxes
  late Box<EntityUser> userBox;
  late Box<EntityRoomType> roomTypeBox;
  late Box<EntityTable> tableBox;
  late Box<EntityCategoryTax> categoryTaxBox;
  late Box<EntityFood> foodBox;
  late Box<EntityOrder> boxEntityOrder;
  late Box<EntityOrderFood> boxEntityOrderFood;
// Accumulator buffer per connected client to split TCP stream by lines
final Map<Socket, String> _recvBuf = <Socket, String>{};
  var kdsConnected = true.obs;

  @override
  void onInit() {
    super.onInit();
    userBox = Get.find<Box<EntityUser>>();
    roomTypeBox = Get.find<Box<EntityRoomType>>();
    tableBox = Get.find<Box<EntityTable>>();
    categoryTaxBox = Get.find<Box<EntityCategoryTax>>();
    foodBox = Get.find<Box<EntityFood>>();
    boxEntityOrder = Get.find<Box<EntityOrder>>();
    boxEntityOrderFood = Get.find<Box<EntityOrderFood>>();
  }

  Future<void> startServer({int tcpPort = 4040, int udpPort = 4444}) async {
    if (isRunning.value) {
      messages.add('⚠ startServer called but server already running');
      return;
    }

    try {
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, tcpPort);
      isRunning.value = true;
      messages.add("✅ TCP Server started on ${_server!.address.address}:$tcpPort");

      _server!.listen(_handleClient, onError: (e) {
        messages.add('⚠ Server socket error: $e');
      });

      _udp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, udpPort);
      _udp!.broadcastEnabled = true;

      final serverIp = await _getLocalIp();
      final serverIpPort = "$serverIp:$tcpPort";
      messages.add("📡 Broadcasting server: $serverIpPort on UDP $udpPort");

      // UDP broadcast loop
      Future.doWhile(() async {
        if (_udp == null) return false;
        try {
          _udp!.send(
            serverIpPort.codeUnits,
            InternetAddress('255.255.255.255'),
            udpPort,
          );
        } catch (e) {
          messages.add('⚠ UDP broadcast failed: $e');
        }
        await Future.delayed(const Duration(seconds: 5));
        return _udp != null;
      });
    } catch (e) {
      messages.add("❌ Error starting server: $e");
      stopServer();
    }
  }

  void _handleClient(Socket client) {
  _clients.add(client);
  _recvBuf[client] = '';

  String remote = 'unknown';
  try { remote = client.remoteAddress.address; } catch (_) {}
  messages.add("🔗 Client connected: $remote");

  client.listen(
    (data) async {
      try {
        if (data.isEmpty) return;

        _recvBuf[client] = (_recvBuf[client] ?? '') + utf8.decode(data);

        var buf = _recvBuf[client]!;
        int nl;
        while ((nl = buf.indexOf('\n')) != -1) {
          final line = buf.substring(0, nl).trim();
          buf = buf.substring(nl + 1);
          if (line.isEmpty) continue;
          await _processJsonLine(client, line);
        }
        _recvBuf[client] = buf;
      } catch (e, st) {
        messages.add("⚠ Error handling client data: $e\n$st");
        try {
          await _safeWrite(client, {"status": "error", "message": "Invalid request"});
        } catch (_) {}
      }
    },
    onDone: () {
      String r = 'unknown';
      try { r = client.remoteAddress.address; } catch (_) {}
      messages.add("👋 Client disconnected: $r");
      _clients.remove(client);
      _captainClients.remove(client);
      _recvBuf.remove(client);
      try { client.destroy(); } catch (_) {}
    },
    onError: (error) {
      String r = 'unknown';
      try { r = client.remoteAddress.address; } catch (_) {}
      messages.add("⚠ Client error from $r: $error");
      _clients.remove(client);
      _captainClients.remove(client);
      _recvBuf.remove(client);
      try { client.destroy(); } catch (_) {}
    },
    cancelOnError: true,
  );
}

// IN FILE: ControllerServer.dart
// IN CLASS: ControllerServer
// IN FILE: ControllerServer.dart
// IN CLASS: ControllerServer

Future<void> _processJsonLine(Socket client, String msg) async {
  messages.add("📩 Client (${client.remoteAddress.address}) sent: $msg");

  // Only parse JSON objects
  if (!(msg.startsWith('{') || msg.startsWith('['))) {
    await _safeWrite(client, {"status": "error", "message": "Invalid request"});
    return;
  }

  Map<String, dynamic> req;
  try {
    final parsed = jsonDecode(msg);
    if (parsed is! Map<String, dynamic>) {
      await _safeWrite(client, {"status": "error", "message": "Invalid request"});
      return;
    }
    req = parsed.cast<String, dynamic>();
  } catch (_) {
    await _safeWrite(client, {"status": "error", "message": "Invalid request"});
    return;
  }

  final reqId = req['reqId'];

  // LOGIN
  if (req['type'] == 'login') {
    final username = req['username']?.toString() ?? '';
    final password = req['password']?.toString() ?? '';

    final query = userBox
        .query(
          (EntityUser_.userName.equals(username) &
                  EntityUser_.userPassword.equals(password))
              as Condition<EntityUser>?,
        )
        .build();
    final user = query.findFirst();
    query.close();

    if (user != null) {
      messages.add("✅ Login success: $username");
      await _safeWrite(client, {
        "reqId": reqId,
        "status": "success",
        "message": "Login successful",
        "userType": user.userType,
        "userUuid": user.userUuid,
      });
    } else {
      messages.add("❌ Invalid login: $username");
      await _safeWrite(client, {
        "reqId": reqId,
        "status": "error",
        "message": "Invalid credentials",
      });
    }
    return;
  }

  // KOT
  if (req['type'] == 'kot') {
    final kotData =
        (req['data'] is Map) ? Map<String, dynamic>.from(req['data']) : null;
    if (kotData == null) {
      await _safeWrite(client, {
        "reqId": reqId,
        "status": "error",
        "message": "Invalid KOT data",
      });
      return;
    }

    messages.add(
      "📩 Received KOT #: ${kotData['kotNumber']} for table: ${kotData['tableName']}",
    );
    
    // =======================================================================
    // ✅ THIS IS THE FIX: We delegate all work to ControllerOrder
    // This ensures that after saving, the UI state (like the total) is properly updated.
    // =======================================================================
    try {
      if (Get.isRegistered<ControllerOrder>()) {
        final orderController = Get.find<ControllerOrder>();
        // This new method handles both saving to the DB and refreshing the UI state.
        await orderController.processAndSaveIncomingKot(kotData);
      } else {
        messages.add("⚠️ ControllerOrder not found. Cannot process KOT.");
      }
    } catch (e) {
        messages.add("❌ Failed to process incoming KOT: $e");
    }
    // =======================================================================
    
    // We still trigger the print job from the server.
    await _triggerKOTPrint(kotData);

    // And broadcast the KOT to other clients.
    broadcastKotToCaptains(kotData);
    broadcastKotToKDS(kotData);

    try {
      if (Get.isRegistered<ControllerTable>()) {
        Get.find<ControllerTable>().handleKotReceived(kotData);
      }
    } catch (e) {
      messages.add("⚠ ControllerTable not ready: $e");
    }

    // Send a success response back to the Captain app.
    await _safeWrite(client, {
      "reqId": reqId,
      "status": "ok",
      "message": "KOT received and processed successfully", // Updated message
      "kotNumber": kotData['kotNumber'],
      "tableName": kotData['tableName'],
    });
    return;
  }

  // KOT status update
  if (req['type'] == 'kotStatusUpdate') {
    final kotNumber = req['kotNumber'];
    final status = req['status'];
    messages.add("🔁 Received KOT #$kotNumber status update ➜ $status");

    broadcastKotStatusToCaptains(
      _parseIntSafe(kotNumber),
      status?.toString() ?? '',
    );

    await _safeWrite(client, {
      "reqId": reqId,
      "status": "ok",
      "message": "KOT status update broadcasted",
      "kotNumber": kotNumber,
    });
    return;
  }

  // Bill settled
  if (req['type'] == 'billSettled') {
    final billData =
        (req['data'] is Map) ? Map<String, dynamic>.from(req['data']) : null;
    if (billData == null) {
      await _safeWrite(client, {
        "reqId": reqId,
        "status": "error",
        "message": "Invalid bill data",
      });
      return;
    }

    messages.add(
      "💰 Received Bill Settled ➜ Bill #${billData['orderNumber']} (Table: ${billData['tableName']})",
    );

    broadcastBillSettled(billData);

    await _safeWrite(client, {
      "reqId": reqId,
      "status": "ok",
      "message": "Bill settled broadcasted to KDS & Captains",
      "orderNumber": billData['orderNumber'],
    });
    return;
  }

  // Fallback to your existing GET handlers
  final response = await _processRequest(req);
  if (response != null) {
    if (reqId != null) response['reqId'] = reqId;
    await _safeWrite(client, response);
  } else {
    await _safeWrite(client, {
      "reqId": reqId,
      "status": "error",
      "message": "Invalid request",
    });
  }
}
  /// Safe write wrapper that attempts to write+flush and returns success/failure.
  Future<bool> _safeWrite(Socket client, Map<String, dynamic> data) async {
    try {
      final payload = '${jsonEncode(data)}\n';
      client.add(utf8.encode(payload));
      await client.flush();
      return true;
    } catch (e) {
      String r = 'unknown';
      try {
        r = client.remoteAddress.address;
      } catch (_) {}
      messages.add("⚠ Failed writing to $r: $e");
      _clients.remove(client);
      _captainClients.remove(client);
      try {
        client.destroy();
      } catch (_) {}
      return false;
    }
  }

  Future<dynamic> _processRequest(Map<String, dynamic> req) async {
    if (req["type"] == "login") {
      final username = req["username"]?.toString() ?? '';
      final password = req["password"]?.toString() ?? '';

      final query = userBox
          .query(
            (EntityUser_.userName.equals(username) &
                    EntityUser_.userPassword.equals(password))
                as Condition<EntityUser>?,
          )
          .build();
      final user = query.findFirst();
      query.close();

      if (user != null) {
        messages.add("✅ Login success: $username");
        return {
          "status": "success",
          "message": "Login successful",
          "userType": user.userType,
          "userUuid": user.userUuid,
        };
      } else {
        messages.add("❌ Invalid login: $username");
        return {"status": "error", "message": "Invalid credentials"};
      }
    }

    if (req["method"] == "GET" && req["entity"] == "room_type") {
      final list = roomTypeBox
          .getAll()
          .where((e) => e.isActive == true)
          .map(
            (e) => {
              "id": e.id,
              "roomUuid": e.roomUuid,
              "name": e.name,
              "isActive": e.isActive,
            },
          )
          .toList();
      messages.add("✅ Sent ${list.length} active room types");
      return {"status": "ok", "data": list};
    }

    if (req["method"] == "GET" && req["entity"] == "table_type") {
      final rooms = roomTypeBox.getAll();
      final list = tableBox
          .getAll()
          .where((table) {
            final room = rooms.firstWhereOrNull(
              (r) => r.roomUuid == table.roomUuid,
            );
            return table.isActive == true &&
                room != null &&
                room.isActive == true;
          })
          .map(
            (e) => {
              "tableId": e.tableId,
              "tableUid": e.tableUid,
              "tableName": e.tableName,
              "roomType": e.roomType,
              "roomUuid": e.roomUuid,
              "seats": e.seats,
              "orderNumber": e.orderNumber,
              "isActive": e.isActive,
            },
          )
          .toList();
      messages.add("✅ Sent ${list.length} active tables with active rooms");
      return {"status": "ok", "data": list};
    }

    if (req["method"] == "GET" && req["entity"] == "category_tax") {
      final list = categoryTaxBox
          .getAll()
          .map((e) => {"id": e.id, "categoryName": e.categoryName ?? ""})
          .toList();
      messages.add("✅ Sent ${list.length} category taxes");
      return {"status": "ok", "data": list};
    }

    if (req["method"] == "GET" && req["entity"] == "food") {
      final list = foodBox
          .getAll()
          .where((e) => e.isActive == true)
          .map(
            (e) => {
              "foodId": e.foodId,
              "foodName": e.foodName,
              "category": e.categoryName,
              "isVeg": e.isVeg,
              "kitchenDepartment": e.kitchenDepartment,
              "opentItem": e.opentItem,
              "imgPath": e.imgPath,
              "isSync": e.isSync,
              "price": e.price
                      .map(
                        (p) => {
                          "mrp": p.mrp,
                          "price": p.price,
                          "offerPrice": p.offerPrice,
                          "discountPercent": p.discountPercent,
                          "currency": p.currency,
                          "roomType": p.roomType,
                        },
                      )
                      .toList() ??
                  [],
            },
          )
          .toList();

      messages.add("✅ Sent ${list.length} active food items");
      return {"status": "ok", "data": list};
    }

    return null;
  }

  // Broadcast KOT to KDS sockets and in-app bus (messages)
  void broadcastKotToKDS(Map<String, dynamic> kotData) {
    final kotJsonLine = '${jsonEncode({"type": "kot", "data": kotData})}\n';

    // 1) Broadcast to connected KDS clients
    for (final c in List<Socket>.from(_clients)) {
      try {
        c.write(kotJsonLine);
        c.flush();
      } catch (e) {
        String r = 'unknown';
        try {
          r = c.remoteAddress.address;
        } catch (_) {}
        messages.add("⚠ Removing dead KDS client ($r): $e");
        _clients.remove(c);
        try {
          c.destroy();
        } catch (_) {}
      }
    }

    // 2) Notify in-app listeners (KOTController consumes JSON from `messages`)
    messages.add(jsonEncode({"type": "kot", "data": kotData}));

    messages.add("📤 Broadcasted KOT #: ${kotData['kotNumber']} to KDS");
  }

  // Broadcast KOT to captains (socket) only
  void broadcastKotToCaptains(Map<String, dynamic> kotData) {
    final kotJsonLine = "${jsonEncode({"type": "kot", "data": kotData})}\n";

    for (final c in List<Socket>.from(_captainClients)) {
      try {
        c.write(kotJsonLine);
        c.flush();
      } catch (e) {
        String r = 'unknown';
        try {
          r = c.remoteAddress.address;
        } catch (_) {}
        messages.add("⚠ Removing dead captain client ($r): $e");
        _captainClients.remove(c);
        try {
          c.destroy();
        } catch (_) {}
      }
    }

    messages.add("📤 Broadcasted KOT #: ${kotData['kotNumber']} to captains");
  }

  // Save KOT as EntityOrderFood rows attached to an EntityOrder
  Future<List<EntityOrderFood>> _saveKotToLocalDb(
    Map<String, dynamic> kotData,
  ) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final normalizedTable = kotData['tableName']?.toString().trim() ?? 'Unknown';
    final int kotNumber = _parseIntSafe(kotData['kotNumber']);
    final String createdOn = kotData['createdOn']?.toString() ?? now;
    final String? kotUuid = kotData['uuid']?.toString();

    // Resolve or create a Bill
    EntityOrder? bill = _findBillFromKotPayload(kotData);

    bill ??= await _createNewBookedBill(
      tableName: normalizedTable,
      orderType: kotData['orderType']?.toString() ?? 'Dine-In',
      userName: kotData['userName']?.toString() ?? 'server',
      nowIso: now,
    );

    // Parse itemsJson -> items list
    List items = [];
    try {
      if (kotData['itemsJson'] is String) {
        final dec = jsonDecode(kotData['itemsJson']);
        if (dec is Map && dec['items'] is List) {
          items = dec['items'];
        } else if (dec is List) {
          items = dec;
        }
      } else if (kotData['itemsJson'] is Map) {
        final m = kotData['itemsJson'] as Map;
        if (m['items'] is List) items = m['items'];
      } else if (kotData['items'] is List) {
        items = kotData['items'];
      }
    } catch (e) {
      messages.add("⚠ itemsJson parse failed: $e");
    }

    if (items.isEmpty) {
      messages.add("ℹ KOT had no items, nothing to save.");
      return <EntityOrderFood>[];
    }

    // Build and save EntityOrderFood rows
    final newFoods = <EntityOrderFood>[];
    for (final raw in items) {
      if (raw is! Map) continue;

      final isExtra = raw['extra'] == true;
      final foodId = isExtra ? 0 : _parseIntSafe(raw['id']);
      final qty = _parseIntSafe(raw['qty'], defaultValue: 0);
      final price = _parseDoubleSafe(raw['price']);
      final name = raw['name']?.toString() ?? '';

      String category = 'Extras';
      if (!isExtra && foodId > 0) {
        final f = foodBox.get(foodId);
        category = (f?.categoryName ?? '').toString();
      }

      final item = EntityOrderFood(
        orderId: bill.orderId,
        foodId: foodId,
        name: name,
        category: category,
        taxPercentage: 0,
        quantity: qty,
        price: price,
        kotNumber: kotNumber,
        uuid: kotUuid ?? const Uuid().v4(),
        origin: kotData['origin']?.toString() ?? 'captain',
        createdOn: createdOn,
        tableName: normalizedTable,
        orderType: kotData['orderType']?.toString() ?? bill.orderTypeId,
      );
      newFoods.add(item);
    }

    if (newFoods.isEmpty) {
      messages.add("ℹ No valid KOT items to save.");
      return <EntityOrderFood>[];
    }

    boxEntityOrderFood.putMany(newFoods);

    // Attach to bill relation as well
    final freshBill = boxEntityOrder.get(bill.orderId) ?? bill;
    freshBill.listFood.addAll(newFoods);
    try {
      freshBill.listFood.applyToDb();
    } catch (_) {}
    boxEntityOrder.put(freshBill);
try {
  if (Get.isRegistered<ControllerOrder>()) {
    final orderCtrl = Get.find<ControllerOrder>();
    // Make sure a table bucket exists and is set
    orderCtrl.loadTableOrders(normalizedTable);

    // Fill the per-table read-only list that your UI uses
    orderCtrl.refreshKotItemsForTable(normalizedTable, freshBill.orderId);

    // Optionally keep the unified view in sync too
    orderCtrl.rebuildUnifiedKotList(tableName: normalizedTable);
    orderCtrl.getTotalPrice(forTable: normalizedTable);
    orderCtrl.update();
  }
} catch (e) {
  messages.add("⚠ Failed to refresh KOT items in UI: $e");
}
    messages.add(
      "✅ Saved ${newFoods.length} KOT item(s) to bill #${freshBill.orderNumber} for [$normalizedTable]",
    );

    try {
      if (Get.isRegistered<ControllerOrder>()) {
        final controllerOrder = Get.find<ControllerOrder>();
        controllerOrder.rebuildUnifiedKotList(tableName: normalizedTable);
        messages.add("🔄 Rebuilt kotUnifiedItems for [$normalizedTable]");
      }
    } catch (e) {
      messages.add("⚠ Failed to rebuild kotUnifiedItems: $e");
    }

    return newFoods;
  }

  EntityOrder? _findBillFromKotPayload(Map<String, dynamic> kotData) {
    try {
      // priority: billUuid, orderNumber, then open table bill
      final billUuid = kotData['billUuid']?.toString();
      if (billUuid != null && billUuid.isNotEmpty) {
        final all = boxEntityOrder.getAll();
        final byUuid = all.firstWhereOrNull((b) => _readBillUuid(b) == billUuid);
        if (byUuid != null) return byUuid;
      }

      if (kotData.containsKey('orderNumber') && kotData['orderNumber'] != null) {
        final orderNoStr = kotData['orderNumber'].toString();
        final byNo = boxEntityOrder.getAll().firstWhereOrNull(
          (b) => (b.orderNumber?.toString() ?? '') == orderNoStr,
        );
        if (byNo != null) return byNo;
      }

      final table = kotData['tableName']?.toString().trim() ?? '';
      if (table.isNotEmpty) {
        final q = boxEntityOrder
            .query(
              EntityOrder_.tableName.equals(table) &
                  EntityOrder_.status.equals('booked'),
            )
            .build();
        final candidates = q.find();
        q.close();

        if (candidates.isNotEmpty) {
          candidates.sort((a, b) {
            final da = _ts(a.createdOn);
            final db = _ts(b.createdOn);
            return db.compareTo(da);
          });
          return candidates.first;
        }
      }
    } catch (e) {
      messages.add("⚠ _findBillFromKotPayload failed: $e");
    }
    return null;
  }

  Future<EntityOrder> _createNewBookedBill({
    required String tableName,
    required String orderType,
    required String userName,
    required String nowIso,
  }) async {
    final newOrderNo = await _acquireNextorderNumber();
    final bill = EntityOrder(
      orderNumber: newOrderNo,
      status: 'booked',
      startTime: nowIso,
      endTime: null,
      tableName: tableName,
      tableSeat: 0,
      orderTypeId: orderType,
      userName: userName,
      createdOn: nowIso,
    );
    bill.orderId = boxEntityOrder.put(bill);
    return bill;
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

  int _parseIntSafe(dynamic v, {int defaultValue = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? defaultValue;
  }

  double _parseDoubleSafe(dynamic v, {double defaultValue = 0.0}) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? defaultValue;
  }

  Future<int> _acquireNextorderNumber() async {
    final all = boxEntityOrder.getAll();
    if (all.isEmpty) return 1;
    final max = all
        .map((b) => b.orderNumber ?? 0)
        .fold<int>(0, (p, e) => e > p ? e : p);
    return max + 1;
  }

  void stopServer() {
    try {
      for (var c in List<Socket>.from(_clients)) {
        try {
          c.destroy();
        } catch (_) {}
      }
      _clients.clear();

      for (var c in List<Socket>.from(_captainClients)) {
        try {
          c.destroy();
        } catch (_) {}
      }
      _captainClients.clear();

      _server?.close();
      _server = null;

      _udp?.close();
      _udp = null;

      isRunning.value = false;
      messages.add("🛑 Server stopped");
    } catch (e) {
      messages.add("⚠ Error stopping server: $e");
    }
  }

  Future<String> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      return interfaces.first.addresses.first.address;
    } catch (e) {
      messages.add('⚠ Could not determine local IP: $e');
      return '127.0.0.1';
    }
  }

  // Use this when KOT originates locally (no TCP involved)
  void handleIncomingKotFromFlutter(Map<String, dynamic> kotData) async {
    try {
      final saved = await _saveKotToLocalDb(kotData);

      // Broadcast to both (also emits JSON into messages via KDS broadcast)
      broadcastKotToCaptains(kotData);
      broadcastKotToKDS(kotData);

      if (Get.isRegistered<ControllerTable>()) {
        Get.find<ControllerTable>().handleKotReceived(kotData);
      }

      if (Get.isRegistered<ControllerOrder>()) {
        final tblName = kotData['tableName']?.toString().trim() ?? "Unknown";
        Get.find<ControllerOrder>().rebuildUnifiedKotList(tableName: tblName);
      }
      if (Get.isRegistered<ControllerOrder>()) {
  final tblName = kotData['tableName']?.toString().trim() ?? "Unknown";
  final orderCtrl = Get.find<ControllerOrder>();
  final bill = orderCtrl.getActiveBillForTableName(tblName);
  if (bill != null) {
    orderCtrl.loadTableOrders(tblName);
    orderCtrl.refreshKotItemsForTable(tblName, bill.orderId);
    orderCtrl.rebuildUnifiedKotList(tableName: tblName);
    orderCtrl.getTotalPrice(forTable: tblName);
    orderCtrl.update();
  }
}

      messages.add("✅ handleIncomingKotFromFlutter saved ${saved.length} item(s) and broadcasted.");
    } catch (e) {
      messages.add('⚠ handleIncomingKotFromFlutter failed: $e');
    }
  }

  // Low-level API to push raw message to KDS clients (TCP sockets)
  void sendToKDS(String message) {
    for (final client in List<Socket>.from(_clients)) {
      try {
        client.write(message);
        client.flush();
      } catch (e) {
        debugPrint("⚠️ Error sending to client: $e");
        try {
          client.destroy();
        } catch (_) {}
        _clients.remove(client);
      }
    }
  }

  // Broadcast KOT status update to captains (and messages bus)
  void broadcastKotStatusToCaptains(int kotNumber, String status) {
    final updateLine =
        '${jsonEncode({"type": "kotStatusUpdate", "kotNumber": kotNumber, "status": status})}\n';

    for (final c in List<Socket>.from(_captainClients)) {
      try {
        c.write(updateLine);
        c.flush();
      } catch (e) {
        String r = 'unknown';
        try {
          r = c.remoteAddress.address;
        } catch (_) {}
        messages.add("⚠ Removing dead captain client ($r): $e");
        try {
          c.destroy();
        } catch (_) {}
        _captainClients.remove(c);
      }
    }

    // Also notify in-app listeners (KOTController)
    messages.add(jsonEncode({
      "type": "kotStatusUpdate",
      "kotNumber": kotNumber,
      "status": status,
    }));
  }
  Future<void> _triggerKOTPrint(Map<String, dynamic> kotData) async {
  messages.add("🖨️ Received print trigger for KOT #${kotData['kotNumber']}.");

  try {
    // --- 1. Prepare Bill & Data ---
    final EntityOrder? bill = await _findBillFromKotPayload(kotData);
    if (bill == null) {
      messages.add("⚠️ Print failed: No associated bill for KOT.");
      return;
    }

    // Decode itemsJson -> items list
    List<Map<String, dynamic>> itemsToPrint = [];
    try {
      if (kotData['itemsJson'] is String) {
        final decoded = jsonDecode(kotData['itemsJson']);
        if (decoded is Map && decoded['items'] is List) {
          itemsToPrint = List<Map<String, dynamic>>.from(decoded['items']);
        }
      }
    } catch (e) {
      messages.add("⚠️ Print failed: Could not parse itemsJson ($e)");
      return;
    }

    if (itemsToPrint.isEmpty) {
      messages.add("ℹ️ Print skipped: KOT #${kotData['kotNumber']} has no items.");
      return;
    }

    // Group items (qty)
    final groupedItems = <String, List<MapEntry<dynamic, int>>>{
      'Local': itemsToPrint.map((item) {
        final int qty = _parseIntSafe(item['qty'], defaultValue: 1);
        return MapEntry<dynamic, int>(item, qty);
      }).toList(),
    };

    // Load KOT items from DB
    final kotNumber = _parseIntSafe(kotData['kotNumber']);
    final kotItemsQuery =
        boxEntityOrderFood.query(EntityOrderFood_.kotNumber.equals(kotNumber)).build();
    final List<EntityOrderFood> foodItemsForKot = kotItemsQuery.find();
    kotItemsQuery.close();

    final kotGroup = KotGroup(
      kotNumber: kotNumber,
      items: foodItemsForKot,
      tableName: kotData['tableName']?.toString(),
      createdOn: kotData['createdOn']?.toString(),
      uuid: kotData['uuid']?.toString(),
    );

    messages.add("✅ Prepared data. Checking printer config...");

    // --- 2. Load KOT Printer Configuration ---
    final Box<EntityPrinter> printerBox = Get.find();
    final q = printerBox.query(EntityPrinter_.configType.equals('KOT')).build();
    final pr = q.findFirst();
    q.close();

    // --- 3. Fallback if no printer configured ---
    if (pr == null) {
      messages.add("⚠️ No KOT printer configured. Using default PDF print.");
      await kotPrintByConfigType(
        "KOT",
        kot: kotGroup,
        bill: bill,
        groupedItems: groupedItems,
      );
      return;
    }

    final url = (pr.printUrl ?? '').toLowerCase();
    final isBluetooth = url.startsWith('bluetooth://') || url.contains('bluetooth');
    final copies = (pr.noOfCop ?? 1).clamp(1, 10);

    // --- 4. Bluetooth Mode ---
    if (isBluetooth) {
      if (!Get.isRegistered<RawBtPrinterService>()) {
        Get.put(RawBtPrinterService(), permanent: true);
      }

      final bt = Get.find<RawBtPrinterService>();
      bool connected = await bt.refreshConnectionStatus();

      if (!connected) {
        messages.add("🟡 Bluetooth not connected. Attempting reconnect...");
        connected = await bt.connectByConfigType("KOT");
        await Future.delayed(const Duration(milliseconds: 300));
      }

      if (!connected) {
        messages.add("❌ Bluetooth reconnect failed. Skipping print.");
        return;
      }

      messages.add("🟢 Connected to BT printer: ${pr.printName} (${pr.printUrl})");

      for (int i = 0; i < copies; i++) {
        try {
          await bt.printKotEscPosByConfigType(
            configType: 'KOT',
            kot: kotGroup,
            bill: bill,
            groupedItems: groupedItems,
          );
          messages.add("🖨️ Printed copy ${i + 1} of $copies for KOT #${kotNumber}");
        } catch (e) {
          messages.add("⚠️ BT print copy ${i + 1} failed: $e");
        }
      }
    }
    // --- 5. USB / Network / Default ---
    else {
      messages.add("🌐 Non-Bluetooth printer (${pr.printUrl}). Using kotPrintByConfigType.");
      await kotPrintByConfigType(
        "KOT",
        kot: kotGroup,
        bill: bill,
        groupedItems: groupedItems,
      );
    }

    messages.add("✅ Print job for KOT #${kotNumber} completed.");

  } catch (e, st) {
    messages.add("❌ CRITICAL: _triggerKOTPrint failed. Error: $e");
    debugPrint("❌ CRITICAL: _triggerKOTPrint failed. Error: $e\n$st");
  }
}

  DateTime _ts(String? iso) {
    try {
      if (iso == null || iso.isEmpty) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
      return DateTime.parse(iso);
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  
  // Broadcast bill settled to both and messages bus
  void broadcastBillSettled(Map<String, dynamic> billData) {
    final billLine = '${jsonEncode({"type": "billSettled", "data": billData})}\n';

    for (final c in List<Socket>.from(_captainClients)) {
      try {
        c.write(billLine);
        c.flush();
      } catch (e) {
        String r = 'unknown';
        try {
          r = c.remoteAddress.address;
        } catch (_) {}
        messages.add("⚠ Removing dead captain client ($r): $e");
        _captainClients.remove(c);
        try {
          c.destroy();
        } catch (_) {}
      }
    }

    for (final c in List<Socket>.from(_clients)) {
      try {
        c.write(billLine);
        c.flush();
      } catch (e) {
        String r = 'unknown';
        try {
          r = c.remoteAddress.address;
        } catch (_) {}
        messages.add("⚠ Removing dead KDS client ($r): $e");
        _clients.remove(c);
        try {
          c.destroy();
        } catch (_) {}
      }
    }

    // Also notify in-app listeners (KOTController)
    messages.add(jsonEncode({"type": "billSettled", "data": billData}));

    messages.add(
      "📤 Broadcasted Bill Settled ➜ Bill #${billData['orderNumber']} to Captains & KDS",
    );
  }


}