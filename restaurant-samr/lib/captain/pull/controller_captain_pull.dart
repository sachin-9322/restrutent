// controller_captain_pull.dart
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import 'package:splash_screen_03/captain/home/controller_category_food.dart';
import 'package:splash_screen_03/model/entity_price.dart';
import 'package:splash_screen_03/screens/home/fragments/food_type/controller_food.dart';
import 'package:splash_screen_03/screens/home/fragments/order/controller_order.dart';
import 'package:splash_screen_03/screens/home/fragments/room_type/controller_room.dart';
import 'package:splash_screen_03/screens/home/fragments/table_type/controller_table.dart';

import '../../model/entity_cateogry_tax.dart';
import '../../model/entity_food.dart';
import '../../model/entity_room_type.dart';
import '../../model/entity_table.dart';
import '../../objectbox.g.dart';

class ControllerCaptainPull extends GetxController {
  final String serverIp;
  final int serverPort;
  final RxBool isLoading = false.obs;

  late final Box<EntityRoomType> boxRoomType;
  late final Box<EntityTable> boxTable;
  late final Box<EntityCategoryTax> boxCategoryTax;
  late final Box<EntityFood> boxFood;

  ControllerCaptainPull({required this.serverIp, required this.serverPort});
  Socket? _liveSocket;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void onInit() {
    super.onInit();
    boxRoomType = Get.find<Box<EntityRoomType>>();
    boxTable = Get.find<Box<EntityTable>>();
    boxCategoryTax = Get.find<Box<EntityCategoryTax>>();
    boxFood = Get.find<Box<EntityFood>>();

    // Kick off pull after build
    Future.delayed(Duration.zero, () => _pullAllData());

    _startLiveListener();
  }

  void handleBillSettled(Map<String, dynamic> billData) {
    final billNo = billData['orderNumber'];
    final table = billData['tableName'];

    // Get.snackbar(
    //   "Bill Settled",
    //   "💰 Bill #$billNo (Table: $table) has been settled.",
    //   backgroundColor: Colors.green.shade700,
    //   colorText: Colors.white,
    //   snackPosition: SnackPosition.BOTTOM,
    //   duration: const Duration(seconds: 3),
    // );

    try {
      if (Get.isRegistered<ControllerTable>()) {
        Get.find<ControllerTable>().fetchTableDetails();
      }
    } catch (_) {}
  }

  // ----------------- Helpers -----------------
  Future<String> _sendRequestAndReadOneLine(Map<String, dynamic> payload) async {
    final socket = await Socket.connect(
      serverIp,
      serverPort,
      timeout: const Duration(seconds: 5),
    );
    socket.write("${jsonEncode(payload)}\n");
    await socket.flush();
    final response = await socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .first;
    socket.destroy();
    return response;
  }

  Future<void> _startLiveListener() async {
    try {
      _liveSocket = await Socket.connect(serverIp, serverPort);
      debugPrint("🟢 Captain live socket connected to $serverIp:$serverPort");

      _liveSocket!.listen(
        (data) {
          final text = utf8.decode(data).trim();
          for (final line in LineSplitter().convert(text)) {
            _handleIncomingMessage(line);
          }
        },
        onError: (e) {
          debugPrint("❌ Captain live socket error: $e");
          _reconnectLiveSocket();
        },
        onDone: () {
          debugPrint("⚠️ Captain live socket closed, reconnecting...");
          _reconnectLiveSocket();
        },
      );
    } catch (e) {
      debugPrint("❌ Captain failed to connect live socket: $e");
      _reconnectLiveSocket();
    }
  }
// ... inside class ControllerCaptainPull ...

  void _handleIncomingMessage(String message) async {
    debugPrint("📥 Captain received: $message");
    try {
      final data = jsonDecode(message);

      if (data['type'] == 'kotStatusUpdate') {
        final kotNumber = data['kotNumber'];
        final status = data['status'];
        updateKotStatus(kotNumber, status);
        Get.snackbar(
          "KOT Update",
          "KOT #$kotNumber ➜ $status",
          backgroundColor: Colors.blueGrey.shade800,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else if (data['type'] == 'billSettled') {
        final bill = data['data'];
        final billNo = bill['orderNumber'];
        final table = bill['tableName'];
        // Get.snackbar(
        //   "Bill Settled",
        //   "💰 Bill #$billNo (Table: $table) has been settled.",
        //   backgroundColor: Colors.green.shade700,
        //   colorText: Colors.white,
        //   snackPosition: SnackPosition.BOTTOM,
        //   duration: const Duration(seconds: 3),
        // );
        // Also refresh tables, as one just became free
        _getTables();

      } else if (data['type'] == 'audio') {
        final base64Data = data['data']?.toString() ?? '';
        final filename = data['filename']?.toString() ?? 'audio.aac';

        final bytes = base64Decode(base64Data);
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/$filename';
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        try {
          await _audioPlayer.play(DeviceFileSource(filePath));
          debugPrint("▶️ Playing audio from server: $filename");
        } catch (e) {
          debugPrint("⚠️ Failed to play audio: $e");
        }
      }
      // =================================================================
      // <<< NEW LOGIC TO HANDLE REAL-TIME DATA REFRESH NOTIFICATIONS >>>
      // =================================================================
      else if (data['type'] == 'dataRefresh') {
          debugPrint("⚡ Received dataRefresh notification from server!");
          Get.snackbar(
            "Syncing...",
            "Data is being updated in the background.",
             snackPosition: SnackPosition.BOTTOM,
             duration: const Duration(seconds: 2),
          );
          // You can get specific and check data['entity']
          // For example: if (data['entity'] == 'food') { await _getFood(); }
          // But calling the full refresh is simpler and safer.
          await manualRefresh();
      }

    } catch (e) {
      debugPrint("⚠️ Captain parse error: $e on message: $message");
    }
  }

// ... rest of the file is the same

  void _reconnectLiveSocket() {
    Future.delayed(const Duration(seconds: 3), () => _startLiveListener());
  }

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase().trim();
      return s == 'true' || s == '1' || s == 'yes';
    }
    return false;
  }

  String _toString(dynamic v) => v?.toString() ?? '';

  final RxString currentKotStatus = "".obs;
  final RxList<String> kotStatusList = <String>[].obs;

  void updateKotStatus(int kotNumber, String status) {
    final entry = "KOT #$kotNumber ➜ $status";
    kotStatusList.add(entry);
    debugPrint("🟢 Updated captain status list: $entry");
  }

  // ----------------- Pull methods -----------------
  Future<void> _getRoomTypes() async {
    try {
      final response = await _sendRequestAndReadOneLine({
        "userType": "Captain",
        "method": "GET",
        "entity": "room_type",
      });
      debugPrint("RoomTypes raw response: $response");

      final data = jsonDecode(response);
      if (data is Map && data['status'] == 'ok') {
        final List<dynamic> list = data['data'] ?? [];

        // Replace existing room types (server is source of truth here)
        boxRoomType.removeAll();

        final freshList = list.map((dynamic js) {
          final json = js as Map<String, dynamic>;
          return EntityRoomType(
            id: 0,
            name: _toString(json['name']),
            isActive: _toBool(json['isActive']),
            roomUuid: _toString(json['roomUuid']),
          );
        }).toList();

        if (freshList.isNotEmpty) boxRoomType.putMany(freshList);
        debugPrint("✅ Room types updated: ${freshList.length}");

        if (Get.isRegistered<ControllerRoom>()) {
          Get.find<ControllerRoom>().fetchRoomType();
        }
        if (Get.isRegistered<ControllerTable>()) {
          Get.find<ControllerTable>().fetchRoomDetails();
        }
      } else {
        debugPrint("Server Error (RoomTypes): ${data['message'] ?? data}");
      }
    } catch (e, st) {
      debugPrint("Error pulling RoomTypes: $e\n$st");
      rethrow;
    }
  }

  Future<void> _getTables() async {
    try {
      final response = await _sendRequestAndReadOneLine({
        "userType": "Captain",
        "method": "GET",
        "entity": "table_type",
      });
      debugPrint("Tables raw response: $response");

      final data = jsonDecode(response);

      // Replace tables (server is source of truth here)
      boxTable.removeAll();

      List<dynamic> list = [];
      if (data is Map && data['status'] == 'ok') {
        list = data['data'] ?? [];
      } else if (data is List) {
        list = data;
      } else {
        debugPrint("Server Error (Tables): $data");
        return;
      }

      final freshList = list.map((dynamic js) {
        final json = js as Map<String, dynamic>;
        final seats = _toInt(json['seats']) ?? 0;
        final isActive = _toBool(json['isActive']);
        final orderNumberInt = _toInt(json['orderNumber']);
        return EntityTable(
          tableId: 0,
          tableName: _toString(json['tableName']),
          roomType: _toString(json['roomType']),
          seats: seats,
          isActive: isActive,
          orderNumber: orderNumberInt,
          roomUuid: _toString(json['roomUuid']),
          tableUid: _toString(json['tableUid']),
        );
      }).toList();

      if (freshList.isNotEmpty) boxTable.putMany(freshList);
      debugPrint("✅ Tables updated: ${freshList.length}");

      if (Get.isRegistered<ControllerTable>()) {
        Get.find<ControllerTable>().fetchTableDetails();
      }
    } catch (e, st) {
      debugPrint("Error pulling Tables: $e\n$st");
      rethrow;
    }
  }

  Future<void> _getCategoryTaxes() async {
    try {
      final response = await _sendRequestAndReadOneLine({
        "userType": "Captain",
        "method": "GET",
        "entity": "category_tax",
      });
      debugPrint("CategoryTaxes raw response: $response");

      final data = jsonDecode(response);
      if (data is Map && data['status'] == 'ok') {
        final List<dynamic> list = data['data'] ?? [];

        // MERGE: keep existing local categories, upsert server ones by name
        final existing = {for (final c in boxCategoryTax.getAll()) (c.categoryName ?? '').trim().toLowerCase(): c};

        for (final js in list) {
          final json = js as Map<String, dynamic>;
          // ========================= FIX START =========================
          // Parse the name and the UUID from the server response.
          final name = _toString(json['categoryName']).trim();
          final uuid = _toString(json['categoryUuid']).trim();
          // ========================== FIX END ==========================
          final key = name.toLowerCase();

          EntityCategoryTax? cat = existing[key];
          if (cat == null) {
            // ========================= FIX START =========================
            // Create a new category and ensure the UUID is stored.
            cat = EntityCategoryTax(id: 0, categoryName: name, categoryUuid: uuid);
            // ========================== FIX END ==========================
          } else {
            // ========================= FIX START =========================
            // Update the existing category and its UUID.
            cat.categoryName = name;
            if (uuid.isNotEmpty) cat.categoryUuid = uuid;
            // ========================== FIX END ==========================
          }
          boxCategoryTax.put(cat);
        }

        debugPrint("✅ Categories merged (server + local): ${boxCategoryTax.count()}");
      } else {
        debugPrint("Server Error (CategoryTaxes): ${data['message'] ?? data}");
      }
    } catch (e, st) {
      debugPrint("Error pulling CategoryTaxes: $e\n$st");
      rethrow;
    }
  }
Future<void> _getFood() async {
  try {
    final response = await _sendRequestAndReadOneLine({
      "userType": "Captain",
      "method": "GET",
      "entity": "food",
    });
    debugPrint("Food raw response: $response");

    final data = jsonDecode(response);
    if (data is Map && data['status'] == 'ok') {
      final List<dynamic> list = data['data'] ?? [];

      // If server has no foods, keep local and just refresh UI
      if (list.isEmpty) {
        final localCount = boxFood.count();
        debugPrint("ℹ️ Server returned 0 foods. Keeping local=$localCount; no changes.");
        if (Get.isRegistered<ControllerOrder>()) {
          try {
            Get.find<ControllerOrder>().refreshFoodList();
          } catch (_) {}
        }
        if (Get.isRegistered<ControllerFood>()) {
          try {
            Get.find<ControllerFood>().refreshFoodData();
          } catch (_) {}
        }
        return;
      }

      // MERGE instead of removeAll: preserve locally created items
      final existingFoods = boxFood.getAll();
      final byUuid = <String, EntityFood>{};
      final byName = <String, EntityFood>{};

      for (final f in existingFoods) {
        if ((f.foodUuid).toString().isNotEmpty) {
          byUuid[f.foodUuid] = f;
        }
        final nameKey = (f.foodName ?? '').trim().toLowerCase();
        if (nameKey.isNotEmpty && !byName.containsKey(nameKey)) {
          byName[nameKey] = f;
        }
      }

      for (final js in list) {
        final json = js as Map<String, dynamic>;

        // Build prices
        final prices = (json['price'] as List<dynamic>? ?? []).map((p) {
          return EntityPrice(
            roomType: p['roomType']?.toString(),
            currency: p['currency']?.toString(),
            price: _toDouble(p['price']),
            discount: _toDouble(p['discount']),
            mrp: _toDouble(p['mrp']),
            discountPercent: _toDouble(p['discountPercent']),
            offerPrice: _toDouble(p['offerPrice']),
          );
        }).toList();

        final serverUuid = _toString(json['foodUuid']).trim();
        final serverName = _toString(json['foodName']).trim();
        final nameKey = serverName.toLowerCase();

        // Find existing by uuid, else by name
        EntityFood? food = (serverUuid.isNotEmpty ? byUuid[serverUuid] : null) ?? byName[nameKey];

        if (food == null) {
          food = EntityFood(
            foodId: 0,
            foodName: serverName,
            categoryName: _toString(json['category']),
            isVeg: _toBool(json['isVeg']),
            kitchenDepartment: _toString(json['kitchenDepartment']),
            opentItem: _toString(json['opentItem']),
            imgPath: _toString(json['imgPath']),
            isSync: _toBool(json['isSync']),
            shortCode: _toString(json['shortCode']),
            menu: _toString(json['menu']),
            stock: _toDouble(json['stock']),
          );
          // Keep server uuid for stable identity
          if (serverUuid.isNotEmpty) {
            food.foodUuid = serverUuid;
          }
        } else {
          // Update existing
          food
            ..foodName = serverName
            ..categoryName = _toString(json['category'])
            ..isVeg = _toBool(json['isVeg'])
            ..kitchenDepartment = _toString(json['kitchenDepartment'])
            ..opentItem = _toString(json['opentItem'])
            ..imgPath = _toString(json['imgPath'])
            ..isSync = _toBool(json['isSync'])
            ..shortCode = _toString(json['shortCode'])
            ..menu = _toString(json['menu'])
            ..stock = _toDouble(json['stock']);

          if (serverUuid.isNotEmpty) {
            food.foodUuid = serverUuid;
          }
        }

        // Images (support both images[] and imgPath)
        final imagesList = (json['images'] is List)
            ? (json['images'] as List).map((e) => _toString(e)).where((s) => s.isNotEmpty).toList()
            : <String>[];
        if (imagesList.isNotEmpty) {
          food.images = imagesList;
          if ((food.imgPath ?? '').isEmpty) {
            food.imgPath = imagesList.first;
          }
        }

        // Replace prices
        food.price.clear();
        food.price.addAll(prices);

        boxFood.put(food);

        // Update caches
        byUuid[food.foodUuid] = food;
        if (nameKey.isNotEmpty) byName[nameKey] = food;
      }

      debugPrint("✅ Food merged: local=${boxFood.count()} (server merged ${list.length})");

      // Refresh controllers
      if (Get.isRegistered<ControllerOrder>()) {
        try {
          Get.find<ControllerOrder>().refreshFoodList();
        } catch (_) {}
      }
      if (Get.isRegistered<ControllerFood>()) {
        try {
          Get.find<ControllerFood>().refreshFoodData();
        } catch (_) {}
      }
    } else {
      debugPrint("Server Error (Food): ${data['message'] ?? data}");
    }
  } catch (e, st) {
    debugPrint("Error pulling Food: $e\n$st");
    rethrow;
  }
}

  // ----------------- Public -----------------
  Future<void> manualRefresh() async {
    isLoading.value = true;
    try {
      await _pullAllData();
    } catch (e) {
      // Get.snackbar("Error", "Failed to pull data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _pullAllData() async {
    isLoading.value = true;
    try {
      await _getRoomTypes();
      await _getTables();
      await _getCategoryTaxes();
      await _getFood();
      // Get.snackbar("Success", "Data pulled successfully ✅");
    } catch (e, st) {
      // Get.snackbar('Error', 'Failed to pull data: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
}