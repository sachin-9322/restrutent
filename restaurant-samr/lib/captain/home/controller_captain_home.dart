import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/model/entity_bill_food.dart';
import '../../model/entity_cateogry_tax.dart';
import '../../model/entity_food.dart';
import '../../model/entity_kot.dart';
import '../../model/entity_room_type.dart';
import '../../model/entity_table.dart';
import '../../objectbox.g.dart';

class ControllerCaptainHome extends GetxController {
  final String serverIp;
  final int serverPort;

  ControllerCaptainHome({required this.serverIp, required this.serverPort});

  late final Box<EntityRoomType> boxRoomType;
  late final Box<EntityTable> boxTable;
  late final Box<EntityCategoryTax> boxCategoryTax;
  late final Box<EntityFood> boxFood;
  late final Box<EntityOrderFood> boxKot;

  final RxList<EntityRoomType> roomTypes = <EntityRoomType>[].obs;
  final RxList<EntityTable> tables = <EntityTable>[].obs;
  final RxList<EntityCategoryTax> categoryTaxes = <EntityCategoryTax>[].obs;
  final RxList<EntityFood> foods = <EntityFood>[].obs;
  final RxList<EntityOrderFood> sentKots = <EntityOrderFood>[].obs;

  final RxBool isLoading = false.obs;
  var selectedIndex = 0.obs;

  void changeScreen(int index) => selectedIndex.value = index;

  @override
  void onInit() {
    super.onInit();

    boxRoomType = Get.find<Box<EntityRoomType>>();
    boxTable = Get.find<Box<EntityTable>>();
    boxCategoryTax = Get.find<Box<EntityCategoryTax>>();
    boxFood = Get.find<Box<EntityFood>>();
    boxKot = Get.find<Box<EntityOrderFood>>();

    // Load local data initially
    roomTypes.assignAll(boxRoomType.getAll());
    tables.assignAll(boxTable.getAll());
    categoryTaxes.assignAll(boxCategoryTax.getAll());
    foods.assignAll(boxFood.getAll());
    sentKots.assignAll(boxKot.getAll());
  }

  /// Pull all data sequentially
  Future<void> pullAllData() async {
    isLoading.value = true;
    try {
      await fetchRoomTypesFromServer();
      await fetchTablesFromServer();
      await fetchCategoryTaxesFromServer();
      await fetchFoodFromServer();
      debugPrint("✅ All data pulled successfully");
    } catch (e) {
      Get.snackbar("Error", "Failed to pull data: $e");
      debugPrint("❌ PullAllData error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch Room Types
  Future<void> fetchRoomTypesFromServer() async {
    final socket = await Socket.connect(serverIp, serverPort, timeout: const Duration(seconds: 5));
    socket.write(jsonEncode({
      "userType": "Captain",
      "method": "GET",
      "entity": "room_type"
    }) + "\n");
    await socket.flush();

    final response = await socket.cast<List<int>>().transform(utf8.decoder).join();
    socket.destroy();

    final data = jsonDecode(response);
    List<dynamic> list = [];
    if (data is Map && data['status'] == 'ok') {
      list = data['data'] ?? [];
    }

    final serverUuids = <String>{};
    for (final e in list) {
      final json = e as Map<String, dynamic>;
      final roomUuid = json['roomUuid'] as String?;
      if (roomUuid == null) continue;
      serverUuids.add(roomUuid);

      final existing = boxRoomType.query(EntityRoomType_.roomUuid.equals(roomUuid)).build().findFirst();
      if (existing != null) {
        existing.name = json['name'];
        existing.isActive = json['isActive'] ?? false;
        boxRoomType.put(existing);
      } else {
        boxRoomType.put(EntityRoomType(
          id: 0, // ⚡ Must be 0 for new inserts
          name: json['name'],
          isActive: json['isActive'] ?? false,
          roomUuid: roomUuid,
        ));
      }
    }

    // Remove stale local room types
    final allLocal = boxRoomType.getAll();
    for (final local in allLocal) {
      if (!serverUuids.contains(local.roomUuid)) boxRoomType.remove(local.id);
    }

    roomTypes.assignAll(boxRoomType.getAll());
    debugPrint("📌 Room Types updated: ${roomTypes.length}");
    for (var r in roomTypes) {
      debugPrint("  👉 Room: ${r.name}, uuid=${r.roomUuid}, active=${r.isActive}");
    }
  }

  /// Fetch Tables
  Future<void> fetchTablesFromServer() async {
    final socket = await Socket.connect(serverIp, serverPort, timeout: const Duration(seconds: 5));
    socket.write(jsonEncode({
      "userType": "Captain",
      "method": "GET",
      "entity": "table_type"
    }) + "\n");
    await socket.flush();

    final response = await socket.cast<List<int>>().transform(utf8.decoder).join();
    socket.destroy();

    final data = jsonDecode(response);
    List<dynamic> list = [];
    if (data is Map && data['status'] == 'ok') {
      list = data['data'] ?? [];
    }

    final serverUuids = <String>{};
    for (final e in list) {
      final json = e as Map<String, dynamic>;
      final tableUid = json['tableUid'] as String?;
      if (tableUid == null) continue;
      serverUuids.add(tableUid);

      final existing = boxTable.query(EntityTable_.tableUid.equals(tableUid)).build().findFirst();
      if (existing != null) {
        existing.tableName = json['tableName'];
        existing.roomType = json['roomType'];
        existing.roomUuid = json['roomUuid'];
        existing.seats = json['seats'];
        existing.isActive = json['isActive'];
        existing.orderNumber = json['orderNumber'];
        boxTable.put(existing); // ✅ Update existing
      } else {
        boxTable.put(EntityTable(
          tableId: 0, // ⚡ Must be 0 for new inserts
          tableName: json['tableName'],
          roomType: json['roomType'],
          seats: json['seats'],
          isActive: json['isActive'],
          orderNumber: json['orderNumber'],
          roomUuid: json['roomUuid'],
          tableUid: tableUid,
        ));
      }
    }

    // Remove stale local tables
    final allLocal = boxTable.getAll();
    for (final local in allLocal) {
      if (!serverUuids.contains(local.tableUid)) boxTable.remove(local.tableId);
    }

    tables.assignAll(boxTable.getAll());
    debugPrint("📌 Tables updated: ${tables.length}");
    for (var t in tables) {
      debugPrint("  👉 Table: ${t.tableName}, roomType=${t.roomType}, seats=${t.seats}, active=${t.isActive}");
    }
  }

  /// Fetch Category Taxes
  Future<void> fetchCategoryTaxesFromServer() async {
    final socket = await Socket.connect(serverIp, serverPort, timeout: const Duration(seconds: 5));
    socket.write(jsonEncode({
      "userType": "Captain",
      "method": "GET",
      "entity": "category_tax"
    }) + "\n");
    await socket.flush();

    final response = await socket.cast<List<int>>().transform(utf8.decoder).join();
    socket.destroy();

    final data = jsonDecode(response);
    List<dynamic> list = [];
    if (data is Map && data['status'] == 'ok') {
      list = data['data'] ?? [];
    }

    final serverIds = <int>{};
    for (final e in list) {
      final json = e as Map<String, dynamic>;
      final id = json['id'] ?? 0;
      serverIds.add(id);

      final existing = boxCategoryTax.get(id);
      if (existing != null) {
        existing.categoryName = json['categoryName'];
        boxCategoryTax.put(existing);
      } else {
        boxCategoryTax.put(EntityCategoryTax(
          id: id,
          categoryName: json['categoryName'],
        ));
      }
    }

    // Remove stale local
    final allLocal = boxCategoryTax.getAll();
    for (final local in allLocal) {
      if (!serverIds.contains(local.id)) boxCategoryTax.remove(local.id);
    }

    categoryTaxes.assignAll(boxCategoryTax.getAll());
    debugPrint("📌 Category Taxes updated: ${categoryTaxes.length}");
  }

  /// Fetch Food
  Future<void> fetchFoodFromServer() async {
    final socket = await Socket.connect(serverIp, serverPort, timeout: const Duration(seconds: 5));
    socket.write(jsonEncode({
      "userType": "Captain",
      "method": "GET",
      "entity": "food"
    }) + "\n");
    await socket.flush();

    final response = await socket.cast<List<int>>().transform(utf8.decoder).join();
    socket.destroy();

    final data = jsonDecode(response);
    List<dynamic> list = [];
    if (data is Map && data['status'] == 'ok') {
      list = data['data'] ?? [];
    }

    final serverIds = <int>{};
    for (final e in list) {
      final json = e as Map<String, dynamic>;
      final foodId = json['foodId'] ?? 0;
      serverIds.add(foodId);

      final existing = boxFood.get(foodId);
      if (existing != null) {
        existing.foodName = json['foodName'];
        existing.categoryName = json['category'];
        existing.isVeg = json['isVeg'] ?? true;
        existing.kitchenDepartment = json['kitchenDepartment'];
        existing.opentItem = json['opentItem'];
        existing.imgPath = json['imgPath'];
        existing.isSync = json['isSync'] ?? false;
        boxFood.put(existing);
      } else {
        boxFood.put(EntityFood(
          foodId: 0, // ⚡ Must be 0 for new inserts
          foodName: json['foodName'],
          categoryName: json['category'],
          isVeg: json['isVeg'] ?? true,
          kitchenDepartment: json['kitchenDepartment'],
          opentItem: json['opentItem'],
          imgPath: json['imgPath'],
          isSync: json['isSync'] ?? false,
        ));
      }
    }

    final allLocal = boxFood.getAll();
    for (final local in allLocal) {
      if (!serverIds.contains(local.foodId)) boxFood.remove(local.foodId);
    }

    foods.assignAll(boxFood.getAll());
    debugPrint("📌 Foods updated: ${foods.length}");
  }
}
