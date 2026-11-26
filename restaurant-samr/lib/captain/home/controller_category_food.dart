// // controller_category_food.dart
// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:splash_screen_03/captain/serverList/controller_server_selection.dart';
// import 'package:splash_screen_03/model/entity_bill.dart';
// import 'package:splash_screen_03/model/entity_cateogry_tax.dart';
// import 'package:splash_screen_03/model/entity_food.dart';
// import 'package:splash_screen_03/model/entity_kot.dart';
// import 'package:splash_screen_03/model/entity_table.dart';
// import 'package:splash_screen_03/model/entity_user.dart';
// import 'package:splash_screen_03/screens/home/fragments/receipt/controller_receipt.dart';
// import 'package:splash_screen_03/screens/home/fragments/receipt/fragments/kot_reports/controller_kot_repoert.dart';
// import 'package:splash_screen_03/screens/home/fragments/setting/controller_setting.dart';
// import 'package:splash_screen_03/screens/home/fragments/table_type/controller_table.dart';
// import 'package:splash_screen_03/services/controller_server.dart';

// import '../../objectbox.g.dart';

// class ExtraItem {
//   String id;
//   String name;
//   double price;
//   int qty;

//   ExtraItem({
//     required this.id,
//     required this.name,
//     required this.price,
//     required this.qty,
//   });
// }

// class ControllerCategoryFood extends GetxController {
//   static const String ALL_ITEMS_UUID = "ALL";
//   static const String ALL_ITEMS_NAME = "All Categories";

//   Box<EntityCategoryTax> boxEntityCategory = Get.find();
//   Box<EntityFood> boxEntityFood = Get.find();
//   var tableBillMap = <int, int>{};
//   var rxMasterCategoryList = <EntityCategoryTax>[].obs;
//   var rxDisplayCategoryList = <EntityCategoryTax>[].obs;
//   var rxMasterFoodList = <EntityFood>[].obs;
//   var rxDisplayedFoodItems = <EntityFood>[].obs;
//   Box<EntityOrder> boxEntityOrder = Get.find();
//   Box<EntityKot> boxEntityKot = Get.find();
//   Box<EntityUser> boxEntityUser = Get.find();

//   var selectedCategoryUuid = RxnString(ALL_ITEMS_UUID);
//   late final ControllerSetting controllerSetting;

//   // Order related fields
//   var rxOrderItems = <EntityFood, int>{}.obs;

//   final RxBool rxBillSettled = false.obs;

//   final RxList<ExtraItem> rxExtraItems = <ExtraItem>[].obs;

//   @override
//   void onInit() {
//     super.onInit();
//     controllerSetting = Get.isRegistered<ControllerSetting>()
//         ? Get.find<ControllerSetting>()
//         : Get.put(ControllerSetting());
//     _fetchCategoriesAndPrepareDisplayList();
//     _fetchAllFoodItems();
//     filterFoodItemsForSelectedCategory();
//   }

//   void _fetchCategoriesAndPrepareDisplayList() {
//     rxMasterCategoryList.value = boxEntityCategory.getAll();

//     final allCategory = EntityCategoryTax(categoryName: ALL_ITEMS_NAME);
//     // keep the sentinel uuid in name to avoid accidental collisions
//     allCategory.categoryName = ALL_ITEMS_UUID;

//     rxDisplayCategoryList.value = [allCategory, ...rxMasterCategoryList];
//   }
//   void refreshFoodList() {
//     _fetchAllFoodItems();
//     filterFoodItemsForSelectedCategory();
//   }

//   String getCategoryNameByUuid(String? categoryUuid) {
//     if (categoryUuid == null ||
//         categoryUuid.isEmpty ||
//         categoryUuid == ALL_ITEMS_UUID) {
//       return "Others";
//     }
//     final category = rxMasterCategoryList.firstWhereOrNull(
//       (cat) => cat.categoryName == categoryUuid,
//     );
//     return category?.categoryName?.toUpperCase() ?? "OTHERS";
//   }

//   Map<String, List<MapEntry<dynamic, int>>> getGroupedOrderItemsForKot() {
//     final groupedItems = <String, List<MapEntry<dynamic, int>>>{};
//     if (rxOrderItems.isEmpty && rxExtraItems.isEmpty) return groupedItems;

//     // Normal items grouped by category
//     for (var entry in rxOrderItems.entries) {
//       final food = entry.key;
//       final quantity = entry.value;
//       final categoryName = getCategoryNameByUuid(food.categoryName);
//       groupedItems
//           .putIfAbsent(categoryName, () => [])
//           .add(MapEntry<dynamic, int>(food, quantity));
//     }

//     // Append extras under a separate "Extras" category (if any)
//     if (rxExtraItems.isNotEmpty) {
//       const extrasCategory = "Extras";
//       final list = groupedItems.putIfAbsent(extrasCategory, () => []);
//       for (final ex in rxExtraItems) {
//         final Map<String, dynamic> pseudoFood = {
//           'foodName': ex.name,
//           'price': ex.price,
//           'isExtra': true,
//         };
//         list.add(MapEntry<dynamic, int>(pseudoFood, ex.qty));
//       }
//     }

//     return groupedItems;
//   }

//   void _fetchAllFoodItems() {
//     rxMasterFoodList.value = boxEntityFood.getAll();
//   }

// RxList<EntityCategoryTax> get rxCategories => rxDisplayCategoryList;

// // Compute total items count
// RxInt get totalItemsCount {
//   int total = 0;
//   rxOrderItems.forEach((_, qty) => total += qty);
//   for (final ex in rxExtraItems) {
//     total += ex.qty;
//   }
//   return total.obs;
// }
// void selectCategory(String? newSelectedUuid) {
//   // If nothing passed, default to "ALL"
//   selectedCategoryUuid.value = newSelectedUuid ?? ALL_ITEMS_UUID;

//   // Refresh list of items for the chosen category
//   filterFoodItemsForSelectedCategory();
// }

// // ✅ This is the actual filter logic
// void filterFoodItemsForSelectedCategory() {
//   final currentUuid = selectedCategoryUuid.value;

//   if (currentUuid == ALL_ITEMS_UUID) {
//     // Show all items if "ALL" selected
//     rxDisplayedFoodItems.value = List.from(rxMasterFoodList);
//   } else {
//     // Show only matching category items
//     rxDisplayedFoodItems.value = rxMasterFoodList
//         .where((food) => food.categoryName == currentUuid)
//         .toList();
//   }

//   // 🔹 Optional: add a debug log to confirm filtering
//   debugPrint("📌 Filter applied for category: $currentUuid, "
//       "items found: ${rxDisplayedFoodItems.length}");
// }

//   String getFoodPriceDisplay(EntityFood food) {
//     if (food.price.isNotEmpty) {
//       final firstPrice = food.price.first;
//       String display =
//           "${firstPrice.price?.toStringAsFixed(2) ?? 'N/A'} ${firstPrice.currency ?? ''}";
//       if (firstPrice.roomType != null && firstPrice.roomType!.isNotEmpty) {
//         display += " (${firstPrice.roomType})";
//       }
//       return display;
//     }
//     return "Price not set";
//   }

//   void addToOrder(EntityFood food) {
//     rxBillSettled.value = false;

//     if (rxOrderItems.containsKey(food)) {
//       rxOrderItems[food] = rxOrderItems[food]! + 1;
//     } else {
//       rxOrderItems[food] = 1;
//     }
//   }

//   void increaseQuantity(EntityFood food) {
//     if (rxOrderItems.containsKey(food)) {
//       rxOrderItems[food] = rxOrderItems[food]! + 1;
//     }
//   }

//   void decreaseQuantity(EntityFood food) {
//     if (rxOrderItems.containsKey(food) && rxOrderItems[food]! > 1) {
//       rxOrderItems[food] = rxOrderItems[food]! - 1;
//     } else {
//       rxOrderItems.remove(food);
//     }
//   }

//   // ---------------------------
//   // Extra item helpers
//   // ---------------------------
//   /// Add an extra ad-hoc item. `price` should be pre-parsed to double.
//   void addExtraItem({
//     required String name,
//     required double price,
//     required int qty,
//   }) {
//     rxBillSettled.value = false;
//     final id = DateTime.now().millisecondsSinceEpoch.toString();
//     final extra = ExtraItem(id: id, name: name.trim(), price: price, qty: qty);
//     rxExtraItems.add(extra);
//     // showSnackBar(
//     //   "Extra added",
//     //   "$name x$qty added at ₹${price.toStringAsFixed(2)}",
//     // );
//   }

//   void increaseExtraQty(String extraId) {
//     final idx = rxExtraItems.indexWhere((e) => e.id == extraId);
//     if (idx >= 0) {
//       rxExtraItems[idx].qty += 1;
//       rxExtraItems.refresh();
//     }
//   }

//   void decreaseExtraQty(String extraId) {
//     final idx = rxExtraItems.indexWhere((e) => e.id == extraId);
//     if (idx >= 0) {
//       if (rxExtraItems[idx].qty > 1) {
//         rxExtraItems[idx].qty -= 1;
//       } else {
//         rxExtraItems.removeAt(idx);
//       }
//       rxExtraItems.refresh();
//     }
//   }

//   void removeExtra(String extraId) {
//     rxExtraItems.removeWhere((e) => e.id == extraId);
//   }

//   double getTotalPrice() {
//     double total = 0.0;
//     rxOrderItems.forEach((food, qty) {
//       if (food.price.isNotEmpty) {
//         total += (food.price.first.price ?? 0.0) * qty;
//       }
//     });

//     // Add extras
//     for (final ex in rxExtraItems) {
//       total += (ex.price * ex.qty);
//     }
//     return total;
//   }

//   var rxOrderType = "Dine-In".obs;

//   final List<String> orderTypes = [
//     "Quick Bill",
//     "Dine-In",
//     "PickUp",
//     "Delivery",
//   ];

//   void selectOrderType(String type) {
//     if (orderTypes.contains(type)) {
//       rxOrderType.value = type;
//       rxBillSettled.value = false;
//     }
//   }

//   void markBillSettledAndClear() {
//     rxBillSettled.value = true;
//     rxOrderItems.clear();
//     rxExtraItems.clear();
//   }

//   // -----------------------
//   // New user helper methods
//   // -----------------------

//   /// Try to find a user by mobile. Returns null if not found.
//   EntityUser? getUserByMobile(String mobile) {
//     if (mobile.trim().isEmpty) return null;
//     final query = boxEntityUser
//         .query(EntityUser_.mobile.equals(mobile))
//         .build();
//     final result = query.findFirst();
//     query.close();
//     return result;
//   }

//   EntityUser createUserFromDetails({
//     required String mobile,
//     String? first,
//     String? last,
//     String? userType,
//     String? countryCode,
//     String? address,
//   }) {
//     final newUser = EntityUser(
//       userName: first ?? mobile,
//       userPassword: "n/a",
//       userType: userType ?? "Customer",
//       first: first ?? "",
//       last: last ?? "",
//       countryCode: countryCode ?? "",
//       mobile: mobile,
//       dob: "",
//       gender: "",
//       idProofKey: null,
//       idProofValue: null,
//       address: address ?? "",
//       userUuid: null,
//     );

//     final id = boxEntityUser.put(newUser);
//     final saved = boxEntityUser.get(id)!;
//     return saved;
//   }

//   /// IMPORTANT: when creating a Bill for a KOT fallback, prefer the KOT.tableName if present.
//   Future<EntityOrder> getOrCreateBillForKot(EntityKot kot) async {
//     EntityOrder? bill;
//     final int? orderIdLocal = kot.orderId;
//     if (orderIdLocal != null) {
//       bill = boxEntityOrder.get(orderIdLocal);
//       if (bill != null) {
//         return bill;
//       }
//     }

//     final currentorderNumber = await controllerSetting.acquireNextorderNumber();
//     final now = DateTime.now().toIso8601String();

//     // Prefer using kot.tableName if already saved (it will be set by saveOrder)
//     final effectiveTableName =
//         (kot.tableName != null && kot.tableName!.trim().isNotEmpty)
//         ? kot.tableName!
//         : "Unknown";

//     final newBill = EntityOrder(
//       orderNumber: currentorderNumber,
//       status: kot.orderNumber != null ? "booked" : "booked",
//       startTime: now,
//       endTime: null,
//       tableName: effectiveTableName,
//       tableSeat: 0,
//       orderType: rxOrderType.value,
//       userName: "System",
//       createdOn: now,
//     );

//     newBill.orderId = boxEntityOrder.put(newBill);

//     if (Get.isRegistered<ReceiptController>()) {
//       Get.find<ReceiptController>().fetchFromBills(page: 1);
//     }

//     // Link back
//     kot.orderId = newBill.orderId;
//     boxEntityKot.put(kot);

//     newBill.listKot.add(kot);
//     boxEntityOrder.put(newBill);

//     debugPrint(
//       "🔧 Created fallback Bill ID: ${newBill.orderId} orderNumber:${newBill.orderNumber} and linked to KOT ${kot.kotId} (table:${newBill.tableName})",
//     );

//     return newBill;


//   }

// Future<void> saveOrder(String tableName, int tableSeat, String booked) async {
//   rxBillSettled.value = false;

//   if (rxOrderItems.isEmpty && rxExtraItems.isEmpty) {
//     debugPrint("⚠️ Empty order, nothing to save.");
//     return;
//   }

//   final now = DateTime.now().toUtc().toIso8601String();
//   final tableIdKey = tableName.hashCode;
//   final existingorderId = tableBillMap[tableIdKey];

//   EntityOrder bill;

//   if (existingorderId != null) {
//     // Existing bill for table
//     bill = boxEntityOrder.get(existingorderId)!;
//     debugPrint(
//       "ℹ Existing Bill found for table $tableName (id=${bill.orderId}, orderNumber=${bill.orderNumber})",
//     );
//   } else {
//     // New Bill
//     final currentorderNumber = await controllerSetting.acquireNextorderNumber();
//     bill = EntityOrder(
//       orderNumber: currentorderNumber,
//       status: booked,
//       startTime: now,
//       endTime: null,
//       tableName: tableName, // <- use exact selected table
//       tableSeat: tableSeat,
//       orderType: "Dine-In",
//       userName: "Pathan",
//       createdOn: now,
//     );
//     bill.orderId = boxEntityOrder.put(bill);
//     debugPrint(
//       "✅ New Bill created with ID: ${bill.orderId} (orderNumber:${bill.orderNumber}) table:$tableName",
//     );
//     tableBillMap[tableIdKey] = bill.orderId;
//   }

//   // KOT
//   final kotNumber = controllerSetting.acquireNextKotNumber();
//   final kot = EntityKot(
//     kotNumber: await kotNumber,
//     orderId: bill.orderId,
//     orderNumber: bill.orderNumber,
//     createdOn: now,
//     tableName: tableName, 
//   );

//   // Build KOT items JSON
//   try {
//     final List<Map<String, dynamic>> kotItems = [];

//     rxOrderItems.forEach((food, qty) {
//       kotItems.add({
//         'id': food.foodId ?? 0,
//         'name': food.foodName ?? '',
//         'qty': qty,
//         'price': (food.price.isNotEmpty ? (food.price.first.price ?? 0.0) : 0.0),
//         'amount': ((food.price.isNotEmpty ? (food.price.first.price ?? 0.0) : 0.0) * qty),
//       });
//     });

//     for (final ex in rxExtraItems) {
//       kotItems.add({
//         'id': 0,
//         'name': ex.name,
//         'qty': ex.qty,
//         'price': ex.price,
//         'amount': ex.price * ex.qty,
//         'extra': true,
//       });
//     }

//     kot.itemsJson = jsonEncode({'items': kotItems});
//   } catch (e, st) {
//     debugPrint('⚠ Failed to build KOT itemsJson: $e\n$st');
//   }

//   // Persist KOT
//   kot.kotId = boxEntityKot.put(kot);
//   bill.listKot.add(kot);
//   boxEntityOrder.put(bill);

//   debugPrint(
//     "✅ New KOT created with ID: ${kot.kotId} kotNumber:${kot.kotNumber} (Table: ${kot.tableName})",
//   );

//   // Notify ControllerKotReports if exists
//   try {
//     if (Get.isRegistered<ControllerKotReports>()) {
//       Get.find<ControllerKotReports>().refresh();
//     }
//   } catch (_) {}

//   // Automatically send KOT and mark table booked
//   await sendKotAndMarkTable(kot);
// }
// Future<void> sendKotAndMarkTable(EntityKot kot) async {
//   // 1️⃣ Send KOT via socket
//   await sendKotViaSocket(kot, boxEntityKot);

//   // 2️⃣ Mark the table as sent/booked
//   if (kot.tableName != null && kot.tableName!.isNotEmpty) {
//     try {
//       final tableController = Get.find<ControllerTable>();
//       tableController.markTableSent(kot.tableName!); // ✅ use existing method
//       debugPrint("✅ Table ${kot.tableName} marked as booked/sent.");
//     } catch (e) {
//       debugPrint("⚠️ Could not mark table booked: $e");
//     }
//   } else {
//     debugPrint("⚠️ KOT tableName is null or empty, cannot mark table sent.");
//   }
// }

// Future<Map<String, dynamic>?> sendKotViaSocket(EntityKot kot, Box<EntityKot> kotBox) async {
//   final controller = Get.find<ControllerServerSelection>();

//   // Add origin = 'captain'
//   final kotJsonData = kot.toJson();
//   kotJsonData['origin'] = 'captain'; // ✅ mark origin

//   try {
//     final response = await controller.sendRequest({
//       "type": "kot",
//       "data": kotJsonData,
//     });

//     debugPrint("✅ Server Response: $response");
//     kotBox.put(kot);
//     return response;
//   } catch (e) {
//     kotBox.put(kot);
//     debugPrint("⚠️ Error sending KOT: $e");
//     return {"status": "error", "message": e.toString()};
//   }
// }

//  Future<void> eBill(
//     EntityTable? table,
//     String paymentMode, {
//     String? customerName,
//     String? customerMobile,
//     String? customerAddress,
//   }) async {
//     final effectiveTableName =
//         table?.tableName ??
//         (rxOrderType.value == "Dine-In" ? "Quick Bill" : rxOrderType.value);

//     if (effectiveTableName.isEmpty) {
//       debugPrint("❌ No effective table name found.");
//       return;
//     }

//     final tableIdKey = effectiveTableName.hashCode;
//     var orderId = tableBillMap[tableIdKey];
//     EntityOrder? bill;

//     bool isTempOrderType(String t) {
//       final Set<String> tempOrderTypes = {"Quick Bill", "Delivery", "PickUp"};
//       return tempOrderTypes.contains(t);
//     }

//     if (orderId == null) {
//       if (rxOrderItems.isEmpty && rxExtraItems.isEmpty) {
//         return;
//       }

//       if (isTempOrderType(effectiveTableName)) {
//         final currentorderNumber = await controllerSetting
//             .acquireNextorderNumber();
//         final now = DateTime.now();
//         final nowIso = now.toUtc().toIso8601String();
//         final double totalAmount = getTotalPrice();

//         final newBill = EntityOrder(
//           orderNumber: currentorderNumber,
//           startTime: nowIso,
//           endTime: nowIso,
//           tableName: effectiveTableName,
//           tableSeat: 0,
//           orderType: rxOrderType.value,
//           userName: customerName ?? "",
//           createdOn: nowIso,
//           status: "settled",
//           totalAmount: totalAmount,
//           paymentMode: paymentMode,
//         );

//         try {
//           (newBill as dynamic).billDate = nowIso;
//           (newBill as dynamic).createdAt =
//               (newBill as dynamic).createdAt ?? nowIso;
//         } catch (_) {}

//         // Build items
//         final List<Map<String, dynamic>> itemsForBill = [];
//         rxOrderItems.forEach((food, qty) {
//           itemsForBill.add({
//             'id': food.foodId ?? 0,
//             'name': food.foodName ?? '',
//             'qty': qty,
//             'price': (food.price.isNotEmpty
//                 ? (food.price.first.price ?? 0.0)
//                 : 0.0),
//             'amount':
//                 ((food.price.isNotEmpty
//                     ? (food.price.first.price ?? 0.0)
//                     : 0.0) *
//                 qty),
//           });
//         });

//         for (final ex in rxExtraItems) {
//           itemsForBill.add({
//             'id': 0,
//             'name': ex.name,
//             'qty': ex.qty,
//             'price': ex.price,
//             'amount': ex.price * ex.qty,
//             'extra': true,
//           });
//         }

//         // Save customer info
//         newBill.customerName = customerName ?? "";
//         newBill.customerMobile = customerMobile ?? "";
//         newBill.customerAddress = customerAddress ?? "";

//         try {
//           final wrapper = {
//             'meta': {
//               'customerName': newBill.customerName,
//               'customerMobile': newBill.customerMobile,
//               'customerAddress': newBill.customerAddress,
//             },
//             'items': itemsForBill,
//           };
//           (newBill as dynamic).itemsJson = jsonEncode(wrapper);
//         } catch (_) {}

//         // Save to DB
//         newBill.orderId = boxEntityOrder.put(newBill);

//         // Clear state
//         rxOrderItems.clear();
//         rxExtraItems.clear();
//         if (Get.isRegistered<ControllerTable>()) {
//           Get.find<ControllerTable>().clearSelected();
//         }
//         markBillSettledAndClear();

//         // Refresh receipt UI
//         if (Get.isRegistered<ReceiptController>()) {
//           Get.find<ReceiptController>().fetchFromBills(page: 1);
//         }

//         debugPrint(
//           "✅ $effectiveTableName created id=${newBill.orderId} orderNumber=${newBill.orderNumber} total: ₹${totalAmount.toStringAsFixed(2)}",
//         );
//         return;
//       }

//       return;
//     }

//     bill = boxEntityOrder.get(orderId);
//     if (bill == null) {
//       return;
//     }

//     if (!isTempOrderType(effectiveTableName) && bill.listKot.isEmpty) {
//       return;
//     }

//     final double totalAmount = getTotalPrice();
//     final now = DateTime.now();
//     final nowIso = now.toUtc().toIso8601String();

//     // ✅ Mark bill settled
//     bill.status = "settled";
//     bill.endTime = nowIso;
//     bill.totalAmount = totalAmount;
//     bill.paymentMode = paymentMode;

//     // ✅ Ensure bill has a billDate/createdAt
//     try {
//       (bill as dynamic).billDate = nowIso;
//       (bill as dynamic).createdAt = (bill as dynamic).createdAt ?? nowIso;
//     } catch (_) {}

//     // Build items
//     final List<Map<String, dynamic>> itemsForBill = [];
//     rxOrderItems.forEach((food, qty) {
//       itemsForBill.add({
//         'id': food.foodId ?? 0,
//         'name': food.foodName ?? '',
//         'qty': qty,
//         'price': (food.price.isNotEmpty
//             ? (food.price.first.price ?? 0.0)
//             : 0.0),
//         'amount':
//             ((food.price.isNotEmpty ? (food.price.first.price ?? 0.0) : 0.0) *
//             qty),
//       });
//     });
//     for (final ex in rxExtraItems) {
//       itemsForBill.add({
//         'id': 0,
//         'name': ex.name,
//         'qty': ex.qty,
//         'price': ex.price,
//         'amount': ex.price * ex.qty,
//         'extra': true,
//       });
//     }

//     // Save customer fields
//     bill.customerName = customerName ?? (bill.customerName ?? "");
//     bill.customerMobile = customerMobile ?? (bill.customerMobile ?? "");
//     bill.customerAddress = customerAddress ?? (bill.customerAddress ?? "");

//     try {
//       final wrapper = {
//         'meta': {
//           'customerName': bill.customerName,
//           'customerMobile': bill.customerMobile,
//           'customerAddress': bill.customerAddress,
//         },
//         'items': itemsForBill,
//       };
//       (bill as dynamic).itemsJson = jsonEncode(wrapper);
//     } catch (_) {}

//     try {
//       (bill as dynamic).orderItems = itemsForBill;
//       (bill as dynamic).totalQty = itemsForBill.fold<int>(
//         0,
//         (p, e) => p + (e['qty'] as int),
//       );
//     } catch (_) {}

//     // Save final bill
//     boxEntityOrder.put(bill);

//     // Refresh receipts list
//     if (Get.isRegistered<ReceiptController>()) {
//       final rc = Get.find<ReceiptController>();
//       final pageToFetch = (rc.currentPage.value > 0) ? rc.currentPage.value : 1;
//       rc.fetchFromBills(page: pageToFetch);
//     }

//     // Clear state
//     tableBillMap.remove(tableIdKey);
//     rxOrderItems.clear();
//     rxExtraItems.clear();
//     if (isTempOrderType(effectiveTableName) &&
//         Get.isRegistered<ControllerTable>()) {
//       Get.find<ControllerTable>().clearSelected();
//     }
//     markBillSettledAndClear();

//     // Notify KOT controller (in case KOT view needs to refresh)
//     try {
//       if (Get.isRegistered<ControllerKotReports>()) {
//         Get.find<ControllerKotReports>().refresh();
//       }
//     } catch (_) {}
//     debugPrint(
//       "✅ Bill ${bill.orderId} settled for $effectiveTableName (orderNumber=${bill.orderNumber}). Total: ₹${totalAmount.toStringAsFixed(2)})",
//     );
//     // 🔔 Notify all KDS clients about this settled bill
//     try {
//       if (Get.isRegistered<ControllerServer>()) {
//         final server = Get.find<ControllerServer>();
//         final notification = jsonEncode({
//           "type": "billSettled",
//           "data": {
//             "orderNumber": bill.orderNumber,
//             "tableName": effectiveTableName,
//             "total": totalAmount,
//             "paymentMode": paymentMode,
//           },
//         });
//         if (Get.isRegistered<ControllerServer>()) {
//           final server = Get.find<ControllerServer>();
//           server.broadcastBillSettled({
//             "orderNumber": bill.orderNumber,
//             "tableName": effectiveTableName,
//             "total": totalAmount,
//             "paymentMode": paymentMode,
//           });
//         }
//         debugPrint("📤 Sent billSettled to KDS: $notification");
//       }
//     } catch (e) {
//       debugPrint("⚠️ Failed to send billSettled: $e");
//     }
//   }




//   // Helper: show a simple preview dialog for a KOT (UI-level)
//   void printKotPreview(EntityKot kot) {
//     try {
//       // Show preview if UI context available
//       if (Get.context != null) {
//         final ctx = Get.context!;
//         final itemsJson = (kot as dynamic).itemsJson;
//         List<Map<String, dynamic>> items = [];
//         try {
//           if (itemsJson != null) {
//             final dec = jsonDecode(itemsJson);
//             if (dec is Map && dec['items'] is List)
//               items = List<Map<String, dynamic>>.from(dec['items']);
//             else if (dec is List)
//               items = List<Map<String, dynamic>>.from(dec);
//           }
//         } catch (_) {}

//         showDialog(
//           context: ctx,
//           builder: (dctx) {
//             return AlertDialog(
//               title: Text('KOT ${kot.kotNumber ?? ''}'),
//               content: SizedBox(
//                 width: 400,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text('Bill: ${kot.orderNumber ?? '-'}'),
//                     const SizedBox(height: 8),
//                     if (items.isEmpty)
//                       const Text('No items.')
//                     else
//                       ListView.builder(
//                         shrinkWrap: true,
//                         itemCount: items.length,
//                         itemBuilder: (_, i) {
//                           final it = items[i];
//                           final name = it['name'] ?? it['foodName'] ?? 'Item';
//                           final qty = it['qty'] ?? it['quantity'] ?? 1;
//                           return ListTile(
//                             title: Text(name.toString()),
//                             trailing: Text('x$qty'),
//                           );
//                         },
//                       ),
//                   ],
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.of(dctx).pop(),
//                   child: const Text('Close'),
//                 ),
//                 ElevatedButton(
//                   onPressed: () async {
//                     Navigator.of(dctx).pop();
//                   },
//                   child: const Text('Print'),
//                 ),
//               ],
//             );
//           },
//         );
//       } else {
//         debugPrint('No Get.context available for printKotPreview');
//       }
//     } catch (e, st) {
//       debugPrint('printKotPreview failed: $e\n$st');
//     }
//   }

//   List<EntityKot> getAllKots() {
//     return boxEntityKot.getAll();
//   }
  
// }