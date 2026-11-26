import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// This controller handles the discovery of servers on the local network
/// by persistently listening for UDP broadcast packets.
class ServerDiscoveryController extends GetxController {
  // A reactive list of discovered server addresses (e.g., "192.168.1.10:4040").
  final servers = <String>[].obs;
  
  // The currently selected server in the dropdown.
  final selectedServer = ''.obs;
  
  // A flag to show a loading indicator during the initial scan.
  final isDiscovering = false.obs;

  // The UDP socket used for listening.
  RawDatagramSocket? _udpSocket;
  
  // Storage key for remembering the last-used server.
  static const _storageKey = 'lastSelectedServer';

  @override
  void onInit() {
    super.onInit();
    // When the controller is created, immediately start discovery
    // and load any previously selected server.
    discover(); 
    _loadLastSelectedServer();
  }

  @override
  void onClose() {
    // IMPORTANT: Clean up the socket when the controller is no longer needed
    // to prevent memory leaks and orphaned listeners.
    _udpSocket?.close();
    _udpSocket = null;
    debugPrint("ℹ️ ServerDiscoveryController closed and cleaned up socket.");
    super.onClose();
  }
  
  /// Loads the last selected server from persistent storage.
  void _loadLastSelectedServer() {
    final storedServer = GetStorage().read<String>(_storageKey);
    if (storedServer != null && storedServer.isNotEmpty) {
      selectedServer.value = storedServer;
      // Add the stored server to the list so it's always an option,
      // even if not immediately discovered on the network.
      if (!servers.contains(storedServer)) {
        servers.add(storedServer);
      }
    }
  }

  /// Called when a user selects a server from the dropdown.
  /// It updates the state and persists the choice.
  void manualSelect(String serverAddress) {
    if (serverAddress.isEmpty) return;
    
    selectedServer.value = serverAddress;
    // Persist the selection so it's remembered the next time the app opens.
    try {
      GetStorage().write(_storageKey, serverAddress);
    } catch(e) {
      debugPrint("❌ Failed to save last selected server: $e");
    }
  }

  /// Scans the network for servers. This method can be called to refresh the list.
  Future<void> discover() async {
    // Prevent multiple discovery scans from running at the same time.
    if (isDiscovering.value) return;

    isDiscovering.value = true;
    
    // Temporarily clear the list, but keep the previously selected one.
    final lastServer = selectedServer.value;
    servers.clear();
    if (lastServer.isNotEmpty) {
      servers.add(lastServer);
    }

    // Close any existing socket to ensure a clean start.
    _udpSocket?.close();

    try {
      // Bind a new UDP socket to listen for broadcasts on port 4444.
      // 'InternetAddress.anyIPv4' listens on all available network interfaces.
      _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 4444);
      
      debugPrint("✅ UDP Discovery: Listening for servers on port 4444...");

      // Start listening to the socket stream. This listener is persistent.
      _udpSocket!.listen(
        (event) {
          if (event == RawSocketEvent.read) {
            final dg = _udpSocket!.receive();
            if (dg != null) {
              final serverAddress = String.fromCharCodes(dg.data).trim();
              
              // Validate the address and add it to the list if it's new.
              if (serverAddress.isNotEmpty && serverAddress.contains(':') && !servers.contains(serverAddress)) {
                debugPrint("📡 UDP Discovery: Found server at $serverAddress");
                servers.add(serverAddress);
                
                // If this is the first server found and none is selected, auto-select it.
                if (selectedServer.value.isEmpty) {
                  manualSelect(serverAddress);
                }
              }
            }
          }
        },
        onError: (e) {
          debugPrint("❌ UDP Discovery: Socket error: $e");
          isDiscovering.value = false; // Stop loading on error
        },
        onDone: () {
          // This will be called if the socket is manually closed.
          debugPrint("ℹ️ UDP Discovery: Socket listener is done.");
        },
      );

      // Show the loading spinner for a few seconds to give user feedback,
      // but the socket continues to listen in the background.
      await Future.delayed(const Duration(seconds: 4));

    } catch (e) {
      Get.snackbar('Discovery Error', 'Failed to start network discovery: $e');
      debugPrint('❌ UDP Discovery: Failed to bind socket: $e');
    } finally {
      // The initial "discovery" phase is over, hide the spinner.
      isDiscovering.value = false;
    }
  }
}