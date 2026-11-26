import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';

class ClientController extends GetxController {
  Socket? _socket;

  /// Connects to server and sends login JSON
  /// Returns Map<String,dynamic> response
  Future<Map<String, dynamic>> login({
    required String serverIp,
    required int serverPort,
    required String username,
    required String password,
  }) async {
    try {
      // Connect to server TCP
      _socket = await Socket.connect(serverIp, serverPort, timeout: const Duration(seconds: 5));

      // Send login JSON
      final loginJson = jsonEncode({
        "type": "login",
        "username": username,
        "password": password,
      });

      _socket!.write(loginJson);

      // Wait for server response
      final completer = Completer<Map<String, dynamic>>();
      _socket!.listen(
            (data) {
          final response = jsonDecode(utf8.decode(data));
          completer.complete(response);
        },
        onError: (e) {
          completer.completeError("Socket error: $e");
        },
        onDone: () {
          _socket?.destroy();
        },
      );

      return completer.future;
    } catch (e) {
      _socket?.destroy();
      return {"status": "error", "message": "Could not connect to server: $e"};
    }
  }

  @override
  void onClose() {
    _socket?.destroy();
    super.onClose();
  }
}