// lib/screens/home/fragments/table_type/controller_table.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:collection/collection.dart';
import 'package:objectbox/objectbox.dart';
import 'package:splash_screen_03/constant/api_constant.dart';

import 'package:splash_screen_03/model/entity_bill.dart';
import 'package:splash_screen_03/model/enum_bill_status.dart';
import 'package:splash_screen_03/model/entity_room_type.dart';
import 'package:splash_screen_03/model/entity_table.dart';
import 'package:splash_screen_03/objectbox.g.dart';
import 'package:splash_screen_03/repository/Base64.dart';
import 'package:splash_screen_03/screens/home/fragments/room_type/controller_room.dart';
import 'package:splash_screen_03/services/api_client.dart';

class ControllerTable extends GetxController {
  final Box<EntityTable> boxEntityTable = Get.find();
  final Box<EntityRoomType> boxEntityRoom = Get.find();
  final Box<EntityOrder> boxEntityOrder = Get.find();

  // --- ADDED FOR SEARCH ---
  var searchQuery = ''.obs;
  // --- END ---

  // --- ADDED FOR FILTERING ---
  final acFilter = 'All'.obs;
  final modelFilter = 'All'.obs;
  final bookingStatusFilter = 'All'.obs;
  // ---------------------------
  // Add this next to other filters
  final roomFilter = 'All'.obs;
  void fetchRoomDetails() {
    rxRoomList.value = boxEntityRoom.getAll();
  }

  String getRestaurantId() {
    final storage = StorageRepository();
    final raw = storage.restaurant;
    if (raw.isEmpty) return "";

    final map = jsonDecode(raw);

    return map["_id"]?.toString() ?? map["id"]?.toString() ?? "";
  }

  // Rooms dropdown items: All + DB rooms
  List<String> get roomNames => [
    'All',
    ...rxRoomList.map((r) => (r.name ?? 'Unnamed').trim()).toSet(),
  ];

  bool _isAcTable(EntityTable t) {
    final raw = (t.roomType ?? '').toLowerCase();

    // Normalize
    final cleaned = raw.replaceAll(RegExp(r'[^a-z]'), '');

    // Explicit non-AC cases
    if (cleaned.contains("nonac") || cleaned.contains("nonair")) return false;

    // Any AC / AirCondition / ACRoom
    if (cleaned.contains("ac") || cleaned.contains("aircondition")) return true;

    return false; // default
  }

  bool matchesAc(EntityTable t, String acFilter) {
    if (acFilter == 'All') return true;

    final isAc = _isAcTable(t);

    if (acFilter == 'AC') return isAc;
    if (acFilter == 'Non-AC') return !isAc;

    return true;
  }

  bool matchesRoom(EntityTable t, String room) {
    if (room == 'All') return true;

    final tableRoom = (t.roomType ?? '').trim().toLowerCase();
    final filterRoom = room.trim().toLowerCase();

    // Allow partial match → handles “AC Hall”, “AC”, “AC ROOM”, “Room: AC”
    return tableRoom.contains(filterRoom);
  }

  /// Bill settled status
  var rxBillSettled = false.obs;

  /// Current active table for orders (reactive)
  var rxCurrentTable = Rxn<String>();

  /// Orders per table (key: tableName, value: TableOrderData)
  final Map<String, TableOrderData> _tableOrders = {};

  /// Booking status map (key: normalized tableName, value: isBooked)
  var rxTableStatus = <String, bool>{}.obs;

  /// Reactive lists
  var rxRoomList = <EntityRoomType>[].obs;
  var rxTableList = <EntityTable>[].obs;

  /// Selected room/table
  var selectedRoomTypeName = "".obs; // Kept in case it's used elsewhere
  var selectedTable = Rxn<EntityTable>();

  /// Temp orders
  var selectedTempTable = Rxn<TempOrderTable>(); // current selected temp
  var rxTempTables =
      <TempOrderTable>[].obs; // ALL active temps (persist UI until settle)

  // --- GETTER FOR MODEL FILTER DROPDOWN ---
  List<String> get uniqueModels => [
    'All',
    ...rxTableList.map((t) => t.tableName ?? 'N/A').toSet(),
  ];
  // --- END ---

  // ADDED: Getter for available AC/Non-AC types based on current table list
  List<String> get uniqueAcTypes {
    final hasAc = rxTableList.any((t) => _isAcTable(t));
    final hasNonAc = rxTableList.any((t) => !_isAcTable(t));

    final types = <String>[];
    if (hasAc) types.add('AC');
    if (hasNonAc) types.add('Non-AC');

    return types;
  }

  String _key(String? name) => (name ?? '').trim().toLowerCase();
  // In ControllerTable

  // Types for the current (or given) room
  List<String> acTypesForRoom(String room) {
    final list = rxTableList.where((t) => matchesRoom(t, room)).toList();
    final hasAc = list.any(_isAcTable);
    final hasNonAc = list.any((t) => !_isAcTable(t));

    final types = <String>[];
    if (hasAc) types.add('AC');
    if (hasNonAc) types.add('Non-AC');
    return types;
  }

  // Optional: counts per type if you want to show them on tabs later
  int acCountForRoom(String type, {String? room}) {
    final r = (room ?? roomFilter.value);
    return rxTableList
        .where(
          (t) =>
              matchesRoom(t, r) &&
              (type == 'AC' ? _isAcTable(t) : !_isAcTable(t)),
        )
        .length;
  }

  // Keep acFilter sane when room changes or tables reload
  void normalizeAcFilterForRoom() {
    final types = acTypesForRoom(roomFilter.value);

    if (types.length < 2) {
      // No choice to make -> treat as "All" (grid will just show what's there)
      if (acFilter.value != 'All') acFilter.value = 'All';
    } else if (!types.contains(acFilter.value)) {
      // Two choices, but current filter isn't valid -> pick first available
      acFilter.value = types.first;
    }
  }

  @override
  void onInit() {
    super.onInit();

    // Ensure ControllerRoom exists
    if (!Get.isRegistered<ControllerRoom>()) {
      Get.put(ControllerRoom(), permanent: true);
    }

    // Reset filters
    bookingStatusFilter.value = 'All';
    roomFilter.value = 'All';
    acFilter.value = 'All';
    searchQuery.value = '';

    fetchRoomDetails();

    // ---------------------------------------------------------
    // FIX START: Load tables from database immediately on restart
    // ---------------------------------------------------------
    loadTablesFromLocal();

    // Fallback: If no tables found locally, try fetching from API
    if (rxTableList.isEmpty) {
      fetchTableDetails();
    }
    // ---------------------------------------------------------
    // FIX END

    refreshBookedFromBills();
  }

  void loadTablesAfterLogin() {
    fetchRoomDetails();
    loadTablesFromLocal();
    refreshBookedFromBills();
  }

  bool matchesBooking(EntityTable t, String bookingFilter) {
    if (bookingFilter == 'All') return true;

    final booked = isTableBooked(t.tableName);

    if (bookingFilter == 'Booked') return booked;
    if (bookingFilter == 'Available') return !booked;

    return true;
  }

  bool matchesSearch(EntityTable t, String query) {
    if (query.trim().isEmpty) return true;

    final q = query.toLowerCase();
    return (t.tableName ?? '').toLowerCase().contains(q) ||
        (t.roomType ?? '').toLowerCase().contains(q) ||
        t.seats.toString().contains(q);
  }

  Future<void> fetchTableDetails() async {
    final restaurantId = getRestaurantId();

    if (restaurantId.isEmpty) {
      print("⚠️ No restaurant found → loading local tables");
      
      loadTablesFromLocal();
      return;
    }

    print("📡 Loading tables from API → restaurantId: $restaurantId");

    final api = ApiClient();
    final apiResponse = await api.getRequestWithToken(
      ApiConstant.getTables(restaurantId),
    );

    if (apiResponse.statusCode == 200 &&
        apiResponse.body != null &&
        apiResponse.body["success"] == true) {
      final List<dynamic> data = apiResponse.body["data"] ?? [];

      saveApiTablesToLocal(data);
      loadTablesFromLocal();

      print("✅ Tables loaded from API");
      return;
    }

    print("⚠️ API failed → using local tables");
    loadTablesFromLocal();
  }

  void saveApiTablesToLocal(List<dynamic> list) {
    if (list.isEmpty) return;

    final roomController = Get.find<ControllerRoom>();

    boxEntityTable.removeAll();

    for (var item in list) {
      final roomName = item["tableSectionName"]?["en"] ?? "Unknown";

      // NEW → Sync room type into local storage
      roomController.syncRoomTypeFromTableApi(roomName);

      final table = EntityTable(
        tableName: item["label"] ?? "Unnamed",
        roomType: roomName,
        roomUuid: item["tableSectionId"],
        seats: item["capacity"] ?? 0,
        isActive: item["isAvailable"] ?? true,
        mongoId: item["_id"],
        isSync: true,
      );

      boxEntityTable.put(table);
    }

    roomController.fetchRoomType(); // refresh room list
  }

  void loadTablesFromLocal() {
    rxTableList.value = boxEntityTable.getAll();

    // rebuild booking map
    for (var table in rxTableList) {
      final key = _key(table.tableName);
      if (key.isNotEmpty && !rxTableStatus.containsKey(key)) {
        rxTableStatus[key] = false;
      }
    }

    refreshBookedFromBills();
  }

  /// --- NEW METHOD TO DELETE A TABLE ---
  void deleteTable(EntityTable table) {
    boxEntityTable.remove(table.tableId);
    // Refresh the list in the UI after deletion
    fetchTableDetails();
    // Optional: You might want to refresh booking status as well
    refreshBookedFromBills();
    Get.snackbar(
      "Success",
      "Table '${table.tableName}' deleted successfully.",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // --- END ---

  /// Add multiple tables automatically
  void addMultipleTables({
    required String baseName,
    required int quantity,
    required String roomType,
    required int seats,
  }) {
    if (baseName.trim().isEmpty || quantity <= 0) return;

    final List<EntityTable> tablesToAdd = [];
    for (int i = 1; i <= quantity; i++) {
      final table = EntityTable(
        tableName: "$baseName $i",
        roomType: roomType,
        seats: seats,
        isActive: true,
      );
      tablesToAdd.add(table);
    }

    boxEntityTable.putMany(tablesToAdd);
    fetchTableDetails();
    refreshBookedFromBills();
  }

  /// Called when a bill is settled (temp or normal table)
  void markBillSettledAndClear() {
    rxBillSettled.value = true;

    // If a temp order is selected, remove it from the list and clear selection
    if (selectedTempTable.value != null) {
      final id = selectedTempTable.value!.id;
      rxTempTables.removeWhere((t) => t.id == id);
      selectedTempTable.value = null;
      update();
      return;
    }

    // Otherwise, settle physical table
    if (rxCurrentTable.value != null &&
        _tableOrders.containsKey(rxCurrentTable.value)) {
      _tableOrders[rxCurrentTable.value!] = TableOrderData();
    }

    clearBooked(rxCurrentTable.value);
    update();
  }

  /// Mark table as booked
  void markTableBooked(String tableName) {
    if (tableName.trim().isEmpty) return;
    final key = _key(tableName);
    rxTableStatus[key] = true;
    debugPrint("✅ markTableBooked: $tableName");
  }

  void handleOrderSettled(String settledTableName) {
    final key = _key(settledTableName);

    // Clear booking status for physical tables
    if (rxTableStatus.containsKey(key)) {
      rxTableStatus[key] = false;
      debugPrint("🟡 Cleared booking for physical table: $settledTableName");
    }

    // Remove the specific temporary order from the UI list
    int removedCount = rxTempTables.length;
    rxTempTables.removeWhere((temp) => _key(temp.name) == key);
    if (rxTempTables.length < removedCount) {
      debugPrint("🟡 Removed temporary order from UI: $settledTableName");
    }

    // Clear selection if it was the one being settled
    if (_key(selectedTable.value?.tableName) == key) {
      selectedTable.value = null;
    }
    if (_key(selectedTempTable.value?.name) == key) {
      selectedTempTable.value = null;
    }

    update();
  }

  /// Mark table as booked/sent and make temp tables visible.
  void markTableSent(String tableName) {
    final key = _key(tableName);
    if (key.isNotEmpty) {
      // For physical tables, this marks them as booked (red)
      rxTableStatus[key] = true;

      // For temporary tables, this makes them visible on the dashboard.
      final temp = rxTempTables.firstWhereOrNull((t) => _key(t.name) == key);
      if (temp != null && !temp.showAfterKot) {
        temp.showAfterKot = true;
        // We need to trigger a list update for Obx in the UI to pick up the change.
        rxTempTables.refresh();
        debugPrint("✅ Made temporary table visible: ${temp.name}");
      }
    }
  }

  /// Clear booking status
  void clearBooked(String? tableName) {
    if (tableName == null) return;
    final key = _key(tableName);
    if (key.isNotEmpty) {
      rxTableStatus[key] = false;
      debugPrint("🟡 clearBooked: $tableName");
    }
  }

  /// Check booking status
  bool isTableBooked(String? tableName) {
    final key = _key(tableName);
    final booked = rxTableStatus[key] ?? false;
    return booked;
  }

  /// Rebuilds rxTableStatus from DB: any bill with status=booked keeps the table red
  void refreshBookedFromBills() {
    // Reset all visible tables to false first
    for (final t in rxTableList) {
      final k = _key(t.tableName);
      if (k.isNotEmpty) rxTableStatus[k] = false;
    }

    try {
      final q = boxEntityOrder
          .query(EntityOrder_.status.equals(BillStatus.booked.value))
          .build();
      final activeBills = q.find();
      q.close();

      for (final bill in activeBills) {
        // Fix: Ignore bills that have no items (ghost bills)
        if (bill.listFood.isEmpty) continue;

        final k = _key(bill.tableName);
        if (k.isNotEmpty) rxTableStatus[k] = true;
      }

      debugPrint(
        "🔄 refreshBookedFromBills -> booked: ${rxTableStatus.entries.where((e) => e.value).map((e) => e.key).toList()}",
      );
    } catch (e, st) {
      debugPrint('⚠ refreshBookedFromBills failed: $e\n$st');
    }

    update();
  }

  /// Handle KOT received from server
  void handleKotReceived(Map<String, dynamic> kotData) {
    final tableName = kotData['tableName'];
    if (tableName == null || (tableName as String).trim().isEmpty) return;

    final table = rxTableList.firstWhereOrNull(
      (t) => _key(t.tableName) == _key(tableName),
    );

    if (table != null) {
      markTableBooked(table.tableName!);
      debugPrint("📌 KOT received -> Booked table: ${table.tableName}");
    } else {
      markTableBooked(tableName);
      debugPrint(
        "❗ KOT received -> Table not found locally: $tableName (marked booked anyway)",
      );
    }
  }

  /// Manual table selection
  void selectTable(EntityTable table) {
    selectedTempTable.value = null;
    selectedTable.value = table;
    debugPrint("🟡 User selected table: ${table.tableName}");
  }

  /// Manual temp table selection
  void selectTempTable(TempOrderTable temp) {
    selectedTable.value = null; // Deselect physical table
    selectedTempTable.value = temp; // Select temp table
    debugPrint("🟡 User selected temp table: ${temp.name}");
  }

  /// Create or get temp table (one per type), and select it
  void createAndSelectTempTable(String type) {
    final temp = TempOrderTable.generate(type: type);
    rxTempTables.add(temp);
    selectedTempTable.value = temp;
    selectedTable.value = null; // focus is on the new temp order
    update();
  }

  /// Clear selection (does NOT remove temps)
  void clearSelected() {
    selectedTable.value = null;
    selectedTempTable.value = null;
    debugPrint("🟡 Table selection cleared");
  }

  /// Toggle active/inactive
  void isActiveOrDeactive(EntityTable table) {
    table.isActive = !(table.isActive ?? true);
    boxEntityTable.put(table);
    fetchTableDetails();
    refreshBookedFromBills();
  }

  /// Get room type name safely
  String getRoomTypeName(String name) {
    try {
      return rxRoomList.firstWhere((r) => r.name == name).name!;
    } catch (e) {
      return 'Unknown';
    }
  }
}

class TempOrderTable {
  final String id;
  final String name;
  final int seats;
  final String type;

  bool showAfterKot;

  // 🔥 NEW: store orderType MongoDB ID
  String? mongoId; // <--- ADD THIS
  String? tableMongoId;
  TempOrderTable({
    required this.id,
    required this.name,
    required this.seats,
    required this.type,
    this.showAfterKot = false,
    this.mongoId, // <--- ADD THIS
    this.tableMongoId,
  });

  factory TempOrderTable.generate({required String type}) {
    final now = DateTime.now();
    final ts =
        "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-"
        "${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}";

    return TempOrderTable(
      id: ts,
      name: "$type - $ts",
      seats: type == "Quick Bill" ? 1 : 0,
      type: type,
      showAfterKot: false,
      mongoId: null, // <--- optional default
    );
  }
}

class TableOrderData {
  RxMap<dynamic, int> orderItems = <dynamic, int>{}.obs;
  RxList<dynamic> extraItems = <dynamic>[].obs;
  RxList<dynamic> kotItems = <dynamic>[].obs;
}
