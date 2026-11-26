// ignore_for_file: constant_identifier_names, prefer_null_aware_operators, curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:splash_screen_03/captain/home/activity_captain_home.dart';
import 'package:splash_screen_03/captain/pull/controller_captain_pull.dart';
import 'package:splash_screen_03/kds/fragment/controller_kds.dart';
import 'package:splash_screen_03/kds/fragment/fragment_home.dart';
import 'package:splash_screen_03/screens/home/activity_home.dart';
import 'package:splash_screen_03/screens/home/fragments/order/controller_order.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/controller_setting.dart';
import 'package:splash_screen_03/services/disovred_server.dart';

import '../../objectbox.g.dart';
import '../../model/entity_room_type.dart';

class ControllerServerSelection extends GetxController {
  final String username;
  final String password;

  ControllerServerSelection({required this.username, required this.password});

  final RxList<String> serverList = <String>[].obs;
  final RxBool isLoading = false.obs;

  Box<EntityRoomType> boxRoomType = Get.find();

  Socket? _socket;
  bool _isSocketConnected = false; // Defensive flag
  Socket? get socket => _socket;

  // 🔧 MODIFIED: The list now holds DiscoveredServer objects.
  final RxList<DiscoveredServer> serverListt = <DiscoveredServer>[].obs;
  final Map<String, Completer<Map<String, dynamic>>> _pendingRequests = {};
  int _reqCounter = 0;

  String _incompleteBuffer = '';
  Timer? _reconnectTimer;
  String? _lastIp;
  int? _lastPort;

  @override
  void onInit() {
    super.onInit();
    // Register KOTController if not yet
    if (!Get.isRegistered<KOTController>()) {
      Get.put(KOTController());
    }
    _discoverServers();
  }

  // Discover servers via UDP broadcast (listening for beacons)
  void _discoverServers() async {
    isLoading.value = true;
    try {
      final udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        4444,
      );
      udpSocket.broadcastEnabled = true;

      udpSocket.listen((event) {
        if (event == RawSocketEvent.read) {
          final dg = udpSocket.receive();
          if (dg != null) {
            final server = String.fromCharCodes(dg.data).trim();
            if (server.isNotEmpty && !serverList.contains(server)) {
              serverList.add(server);
            }
          }
        }
      });

      await Future.delayed(const Duration(seconds: 5));
      udpSocket.close();
    } catch (e) {
      Get.snackbar('Error', 'Server discovery failed: $e');
      debugPrint('❌ Server discovery error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  final RxString lastErrorMessage = ''.obs;

  Future<bool> loginToServer(String serverIpPort) async {
    isLoading.value = true;
    lastErrorMessage.value = '';
    try {
      final parts = serverIpPort.split(':');
      if (parts.length != 2) throw Exception('Invalid server address');

      final ip = parts[0];
      final port = int.tryParse(parts[1]);
      if (port == null) throw Exception('Invalid server port');

      _lastIp = ip;
      _lastPort = port;
      _reconnectTimer?.cancel();

      _socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(seconds: 5),
      );
      _isSocketConnected = true;
      _setupSocketListener(ip, port);

      final loginResponse = await sendRequest({
        "type": "login",
        "username": username,
        "password": password,
      });

      final status =
          loginResponse['status']?.toString().toLowerCase() ?? 'fail';
      if (status != 'success') {
        final msg = (loginResponse['message']?.toString() ?? '').trim();
        lastErrorMessage.value = msg.isNotEmpty
            ? msg
            : 'Incorrect username or password';
        _safeCloseSocket();
        return false;
      }

      return true; // success → listener navigates
    } catch (e) {
      lastErrorMessage.value =
          'Cannot connect to server. Please check network or server status.';
      _safeCloseSocket();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void _setupSocketListener(String ip, int port) {
    _incompleteBuffer = '';

    try {
      if (_socket == null) return;

      _socket!.listen(
        (data) async {
          try {
            if (!_isSocketConnected) return;

            _incompleteBuffer += String.fromCharCodes(data);
            final parts = _incompleteBuffer.split('\n');

            for (int i = 0; i < parts.length - 1; i++) {
              final jsonStr = parts[i].trim();
              if (jsonStr.isEmpty) continue;

              try {
                final response = jsonDecode(jsonStr);
                debugPrint('📥 Server Response: $response');

                // Incoming KOT (broadcast)
                if (response['type'] == 'kot') {
                  _handleIncomingKot(response);
                  continue;
                }

                if (response['type'] == 'kotStatusUpdate') {
                  final kotNumber = response['kotNumber'];
                  final status = response['status'];
                  debugPrint("📥 Captain received KOT #$kotNumber ➜ $status");

                  if (Get.isRegistered<ControllerCaptainPull>()) {
                    Get.find<ControllerCaptainPull>().updateKotStatus(
                      kotNumber,
                      status,
                    );
                  }

                  Get.snackbar(
                    "KOT Status Update",
                    "📥 KOT #$kotNumber ➜ $status",
                    backgroundColor: Colors.blueGrey.shade800,
                    colorText: Colors.white,
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 3),
                    icon: const Icon(Icons.receipt_long, color: Colors.white),
                  );
                  continue;
                }

                if (response['type'] == 'billSettled') {
                  final billData = response['data'];
                  debugPrint("📥 Bill Settled Notification: $billData");

                  // Captain side (optional)
                  if (Get.isRegistered<ControllerCaptainPull>()) {
                    Get.find<ControllerCaptainPull>().handleBillSettled(
                      billData,
                    );
                  }

                  // KDS side ➜ Notify KOTController so it shows a snackbar and clears tiles
                  try {
                    if (Get.isRegistered<KOTController>()) {
                      Get.find<KOTController>().processSingleMessage(
                        jsonEncode(response),
                      );
                    }

                    // Keep your captain side logic
                    if (Get.isRegistered<ControllerCaptainPull>()) {
                      Get.find<ControllerCaptainPull>().handleBillSettled(
                        billData,
                      );
                    }
                    continue;
                  } catch (e) {
                    debugPrint("⚠️ Forward to KOTController failed: $e");
                  }

                  continue;
                }

                // Handle login response
                final status =
                    response['status']?.toString().toLowerCase() ?? '';
                if (status == 'success') {
                  final userType =
                      response['userType']?.toString() ?? 'Unknown';
                  final currentUser = username;

                  debugPrint('✅ Logged in user: $currentUser ($userType)');
                  Get.snackbar('Success', 'Welcome $currentUser ($userType)');
                  await _navigateToScreen(userType, ip, port);
                } else if (status.isNotEmpty) {
                  final msg =
                      response['message']?.toString() ?? 'Unknown error';
                  debugPrint('ℹ️ Login response: $msg');
                }

                // Complete pending request if reqId matches
                final reqId = response['reqId']?.toString();
                if (reqId != null && _pendingRequests.containsKey(reqId)) {
                  try {
                    _pendingRequests.remove(reqId)?.complete(response);
                  } catch (e) {
                    debugPrint('⚠ Could not complete pending req $reqId: $e');
                  }
                }
              } catch (e) {
                debugPrint('⚠️ JSON parse error: $e | raw: $jsonStr');
              }
            }

            _incompleteBuffer = parts.last;
          } catch (e) {
            debugPrint('⚠ Error handling incoming data: $e');
          }
        },
        onDone: () {
          debugPrint("⚠️ Server connection closed (onDone)");
          _handleDisconnection();
        },
        onError: (e) {
          debugPrint("⚠️ Server connection error: $e");
          _handleDisconnection();
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('⚠ Failed to setup socket listener: $e');
      _handleDisconnection();
    }
  }

  void _handleIncomingKot(Map<String, dynamic> response) {
    try {
      if (Get.isRegistered<KOTController>()) {
        Get.find<KOTController>().processSingleMessage(jsonEncode(response));
      }

      final data = (response['data'] as Map?) ?? response;
      final tableName = data['tableName']?.toString() ?? '';
      final orderId = (data['orderId'] is int)
          ? data['orderId'] as int
          : int.tryParse(data['orderId']?.toString() ?? '');
      final billUuid = data['billUuid']?.toString();

      // 🔑 Bump local floors to at least server’s current+1
      try {
        if (Get.isRegistered<ControllerSetting>()) {
          final cs = Get.find<ControllerSetting>();
          final oNo = int.tryParse("${data['orderNumber'] ?? ''}") ?? 0;
          final kNo = int.tryParse("${data['kotNumber'] ?? ''}") ?? 0;
          cs.bumpCountersToAtLeast(
            nextOrderNumber: (oNo > 0) ? oNo + 1 : null,
            nextKotNumber: (kNo > 0) ? kNo + 1 : null,
          );
        }
      } catch (_) {}

      if (Get.isRegistered<ControllerOrder>()) {
        final co = Get.find<ControllerOrder>();
        if (tableName.isNotEmpty) {
          if (orderId != null) co.refreshKotItemsForTable(tableName, orderId);
          co.rebuildUnifiedKotList(tableName: tableName);
        } else if (billUuid != null) {
          co.refreshKotUnifiedItems(billUuid);
        }
        co.update();
      }
    } catch (e, st) {
      debugPrint("⚠ _handleIncomingKot failed: $e\n$st");
    }
  }

  void _handleDisconnection() {
    _isSocketConnected = false;
    try {
      _socket?.destroy();
    } catch (e) {
      debugPrint('⚠ Error destroying socket: $e');
    }
    _socket = null;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), _attemptReconnect);
  }

  void _safeCloseSocket() {
    _isSocketConnected = false;
    try {
      socket?.destroy();
    } catch (e) {
      // ignore
    }
    _socket = null;
  }

  void _attemptReconnect() async {
    if (_lastIp == null || _lastPort == null) {
      debugPrint("⚠️ No previous server info, cannot reconnect.");
      return;
    }

    if (_socket != null || _isSocketConnected) {
      debugPrint("⚠️ Socket already connected, skipping reconnect.");
      return;
    }

    // debugPrint("🔁 Attempting to reconnect to $_lastIp:$_lastPort...");
    try {
      _socket = await Socket.connect(
        _lastIp!,
        _lastPort!,
        timeout: const Duration(seconds: 5),
      );

      _isSocketConnected = true;
      debugPrint("✅ Reconnected to server!");
      _setupSocketListener(_lastIp!, _lastPort!);

      await sendRequest({
        "type": "login",
        "username": username,
        "password": password,
      });
    } catch (e) {
      debugPrint("❌ Reconnect failed: $e");
      _safeCloseSocket();
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 5), _attemptReconnect);
    }
  }

  Future<void> _navigateToScreen(String userType, String ip, int port) async {
    final box = GetStorage();
    final normalizedType = userType.toLowerCase();

    // Save persistent login info
    box.write('isLoggedIn', true);
    box.write('userType', normalizedType);
    box.write('username', username);
    box.write('password', password);
    box.write('serverIpPort', "$ip:$port");

    switch (normalizedType) {
      case 'brand_admin':
      case 'server':
      case 'pos':
        Get.offAll(() => ActivityHome());
        break;

      case 'captain':
        Get.offAll(() => ActivityCaptainHome(serverIp: ip, serverPort: port));
        break;
      case 'kds':
        Get.offAll(() => ActivityKDSHome(serverIp: ip, serverPort: port));
        break;
      default:
        Get.snackbar('Error', 'Unknown user type: $userType');
    }
  }

  // Send request and wait for async response
  Future<Map<String, dynamic>> sendRequest(Map<String, dynamic> payload) async {
    final reqId = (++_reqCounter).toString();
    payload['reqId'] = reqId;
    payload['senderType'] = 'captain';

    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[reqId] = completer;

    if (_isSocketConnected && _socket != null) {
      final jsonStr = jsonEncode(payload);
      _safeWrite("$jsonStr\n");
      debugPrint("➡️ [CLIENT ➜ SERVER] Sent payload: $jsonStr");
    } else {
      _pendingRequests.remove(reqId);
      return Future.value({
        "status": "error",
        "message": "Not connected to server",
      });
    }

    try {
      final resp = await completer.future.timeout(const Duration(seconds: 5));
      return resp;
    } on TimeoutException catch (_) {
      _pendingRequests.remove(reqId);
      return {"status": "error", "message": "Timeout waiting for server"};
    } catch (e) {
      _pendingRequests.remove(reqId);
      return {"status": "error", "message": e.toString()};
    }
  }

  // Safe write wrapper
  void _safeWrite(String data) {
    try {
      if (_socket != null && _isSocketConnected) {
        _socket!.write(data);
      } else {
        debugPrint('⚠️ Attempted write when socket not connected');
      }
    } catch (e) {
      debugPrint('⚠️ _safeWrite failed: $e');
      _handleDisconnection();
    }
  }

  // Fire-and-forget send
  void sendToServer(String payload) {
    if (_isSocketConnected && _socket != null) {
      _safeWrite("$payload\n");
      debugPrint("➡️ [CLIENT ➜ SERVER] Sent (fire & forget): $payload");
    } else {
      // Get.snackbar('Error', 'Server not connected!');
      debugPrint('⚠️ [CLIENT] Server not connected!');
    }
  }

  @override
  void onClose() {
    _reconnectTimer?.cancel();
    _safeCloseSocket();

    // Complete any pending requests with error to avoid hanging futures
    for (final k in _pendingRequests.keys.toList()) {
      try {
        _pendingRequests.remove(k)?.complete({
          'status': 'error',
          'message': 'Client closed',
        });
      } catch (_) {}
    }
    super.onClose();
  }
}
