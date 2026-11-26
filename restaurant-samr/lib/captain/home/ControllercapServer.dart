// import 'dart:io';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart' hide Condition;
// import 'package:get_storage/get_storage.dart';
// import 'package:objectbox/objectbox.dart' hide Condition;
// import 'package:splash_screen_03/model/entity_cateogry_tax.dart';
// import 'package:splash_screen_03/model/entity_food.dart';
// import 'package:splash_screen_03/model/entity_room_type.dart';
// import 'package:splash_screen_03/model/entity_table.dart';
// import 'package:splash_screen_03/model/entity_user.dart';
// import 'package:splash_screen_03/utils/app_routes.dart';

// import '../../objectbox.g.dart';


// class ControllercapServer extends GetxController {
//   ServerSocket? _server;
//   RawDatagramSocket? _udp;
//   final RxBool isRunning = false.obs;
//   final RxList<String> messages = <String>[].obs;

//   final List<Socket> _clients = [];
//   final List<Socket> _captainClients = [];

//   List<Socket> get clients => _clients;
//   List<Socket> get captainClients => _captainClients;

//   late Box<EntityUser> userBox;
//   late Box<EntityRoomType> roomTypeBox;
//   late Box<EntityTable> tableBox;
//   late Box<EntityCategoryTax> categoryTaxBox;
//   late Box<EntityFood> foodBox;

//   final List<Socket> _kdsClients = []; // ✅ New list


//   List<Socket> get kdsClients => _kdsClients;
//   @override
//   void onInit() {
//     super.onInit();
//     userBox = Get.find<Box<EntityUser>>();
//     roomTypeBox = Get.find<Box<EntityRoomType>>();
//     tableBox = Get.find<Box<EntityTable>>();
//     categoryTaxBox = Get.find<Box<EntityCategoryTax>>();
//     foodBox = Get.find<Box<EntityFood>>();
//   }

//   Future<void> startServer({int tcpPort = 4040, int udpPort = 4444}) async {
//     try {
//       _server = await ServerSocket.bind(InternetAddress.anyIPv4, tcpPort);
//       isRunning.value = true;
//       messages.add("✅ TCP Server started on ${_server!.address.address}:$tcpPort");

//       _server!.listen(_handleClient);

//       _udp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, udpPort);
//       _udp!.broadcastEnabled = true;

//       final serverIp = await _getLocalIp();
//       final serverIpPort = "$serverIp:$tcpPort";
//       messages.add("📡 Broadcasting server: $serverIpPort on UDP $udpPort");

//       // UDP broadcast loop
//       Future.doWhile(() async {
//         if (_udp == null) return false;
//         _udp!.send(serverIpPort.codeUnits, InternetAddress("255.255.255.255"), udpPort);
//         await Future.delayed(const Duration(seconds: 5));
//         return true;
//       });
//     } catch (e) {
//       messages.add("❌ Error starting server: $e");
//     }
//   }

//   void _handleClient(Socket client) {
//     _clients.add(client);
//     messages.add("🔗 Client connected: ${client.remoteAddress.address}");

//     client.listen((data) async {
//       final msg = utf8.decode(data).trim();
//       if (msg.isEmpty) return;

//       messages.add("📩 Client: $msg");
//       try {
//         final parsed = jsonDecode(msg);

//         // ✅ Login handling
//         if (parsed['type'] == 'login') {
//           final userType = (parsed['userType'] ?? "").toString().toLowerCase();
//           if (userType == "captain") {
//             _captainClients.add(client);
//             messages.add("👨‍🍳 Captain logged in");
//           } else if (userType == "kds") {
//             _kdsClients.add(client);
//             messages.add("📺 KDS logged in");
//           }
//         }

//         // ✅ Handle KOT messages
//         if (parsed['type'] == 'kot') {
//           final kotData = parsed['data'];
//           if (kotData != null) {
//             messages.add("📩 Received KOT #: ${kotData['kotNumber']} for table: ${kotData['tableName']}");
//             broadcastKot(kotData); // <-- ✅ send to both captain + KDS
//           }
//         }

//         // other request handlers...
//         final response = await _processRequest(parsed);
//         client.write("${jsonEncode(response)}\n");
//         await client.flush();
//       } catch (e) {
//         messages.add("⚠ Error parsing client message: $e");
//       }
//     }, onDone: () {
//       messages.add("👋 Client disconnected: ${client.remoteAddress.address}");
//       _clients.remove(client);
//       _captainClients.remove(client);
//       _kdsClients.remove(client);
//     }, onError: (error) {
//       messages.add("⚠ Client error: $error");
//       _clients.remove(client);
//       _captainClients.remove(client);
//       _kdsClients.remove(client);
//       client.destroy();
//     });
//   }

// void broadcastKot(Map<String, dynamic> kotData) {
//   final kotJson = "${jsonEncode({"type": "kot", "data": kotData})}\n";

//   // Send to all captains
//   for (var c in _captainClients) {
//     try {
//       c.write(kotJson);
//       c.flush();
//     } catch (e) {
//       messages.add("⚠ Could not send KOT to captain: $e");
//     }
//   }

//   // Send to all KDS clients
//   for (var k in _kdsClients) {
//     try {
//       k.write(kotJson);
//       k.flush();
//     } catch (e) {
//       messages.add("⚠ Could not send KOT to KDS: $e");
//     }
//   }

//   messages.add("📤 Broadcasted KOT #: ${kotData['kotNumber']} to Captains & KDS");
// }




//   Future<dynamic> _processRequest(Map<String, dynamic> req) async {
//     if (req["type"] == "login") {
//       final username = req["username"];
//       final password = req["password"];
//       final user = userBox
//           .query((EntityUser_.userName.equals(username) & EntityUser_.userPassword.equals(password)) as Condition<EntityUser>?)
//           .build()
//           .findFirst();
//       if (user != null) {
//         messages.add("✅ Login success: $username");
//         return {
//           "status": "success",
//           "message": "Login successful",
//           "userType": user.userType,
//           "userUuid": user.userUuid,
//         };
//       } else {
//         messages.add("❌ Invalid login: $username");
//         return {"status": "error", "message": "Invalid credentials"};
//       }
//     }
//     // captain's request handler
//     if (req["method"] == "GET" && req["entity"] == "room_type") {
//       final list = roomTypeBox.getAll()
//           .where((e) => e.isActive == true) // only active
//           .map((e) => {
//         "id": e.id,
//         "roomUuid": e.roomUuid,
//         "name": e.name,
//         "isActive": e.isActive,
//       }).toList();
//       messages.add("✅ Sent ${list.length} active room types");
//       debugPrint(list.toString());
//       return {"status": "ok", "data": list};
//     }

//     if (req["method"] == "GET" && req["entity"] == "table_type") {
//       // Filter only active tables whose parent room is active
//       final list = tableBox.getAll().where((table) {
//         // Find parent room safely using firstWhereOrNull
//         final room = roomTypeBox.getAll().firstWhereOrNull(
//               (r) => r.roomUuid == table.roomUuid,
//         );
//         print("Table: ${table.tableName}, table.isActive: ${table.isActive}");
//         print("Parent Room: ${room?.name}, room?.isActive: ${room?.isActive}");
//         return table.isActive == true && room != null && room.isActive == true;
//       }).map((e) => {
//         "tableId": e.tableId,
//         "tableUid": e.tableUid,
//         "tableName": e.tableName,
//         "roomType": e.roomType,
//         "roomUuid": e.roomUuid,
//         "seats": e.seats,
//         "orderNumber": e.orderNumber,
//         "isActive": e.isActive,
//       }).toList();

//       messages.add("✅ Sent ${list.length} active tables with active rooms");
//       debugPrint(list.toString());
//       return {"status": "ok", "data": list};
//     }

//     if (req["method"] == "GET" && req["entity"] == "category_tax") {
//       final list = categoryTaxBox.getAll().map((e) => {
//         "id": e.id,
//         "categoryName": e.categoryName ?? "",
//       }).toList();

//       messages.add("✅ Sent ${list.length} category taxes");
//       debugPrint(list.toString());
//       return {"status": "ok", "data": list};
//     }

//     if (req["method"] == "GET" && req["entity"] == "food") {
//       final list = foodBox.getAll()
//           .where((e) => e.isActive == true) // only active
//           .map((e) => e.toJsonSimple()) // you already wrote toJsonSimple
//           .toList();
//       messages.add("✅ Sent ${list.length} active food items");
//       debugPrint(list.toString());
//       return {"status": "ok", "data": list};
//     }

//     //return {"status": "error", "message": "Unknown request type"};
//   }

//   /// Broadcast KOT to all connected Captain clients
//   void broadcastKotToCaptains(Map<String, dynamic> kotData) {
//     final kotJson = "${jsonEncode({"type": "kot", "data": kotData})}\n";
//     for (var c in _captainClients) {
//       try {
//         c.write(kotJson);
//         c.flush();
//       } catch (e) {
//         messages.add("⚠ Could not send KOT to captain: $e");
//       }
//     }
//     messages.add("📤 Broadcasted KOT #: ${kotData['kotNumber']} to captains");
//     //debugPrint(kotJson);
//   }

//   void stopServer({bool userRequested = false}) {
//   for (var c in _clients) c.destroy();
//   _clients.clear();
//   _captainClients.clear();
//   _kdsClients.clear();
//   _server?.close();
//   _udp?.close();
//   isRunning.value = false;
//   messages.add("🛑 Server stopped");

//   // ⚠️ Only logout if user explicitly did so
//   if (userRequested) {
//     final box = GetStorage();
//     box.write('isLoggedIn', false);
//     Get.offAllNamed(AppRoutes.login);
//   } else {
//     // Just notify; do not logout
//     Get.snackbar(
//       "Server Disconnected",
//       "Server has stopped. You remain logged in. Restart when ready.",
//       snackPosition: SnackPosition.BOTTOM,
//       duration: const Duration(seconds: 4),
//     );
//   }
// }


//   Future<String> _getLocalIp() async {
//     final interfaces = await NetworkInterface.list(includeLoopback: false, type: InternetAddressType.IPv4);
//     return interfaces.first.addresses.first.address;
//   }

//   /// Optional: Receive KOT from Flutter directly (if needed)
//   void handleIncomingKotFromFlutter(Map<String, dynamic> kotData) {
//     broadcastKotToCaptains(kotData);
//   }
// }