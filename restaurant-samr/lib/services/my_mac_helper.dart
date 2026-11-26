import 'dart:io';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

/// ⚡ Persistent key for our custom device ID
const _storageKey = 'persistent_device_id';
final _box = GetStorage();

/// ✅ Function to get MAC-like info (safe for all platforms)
Future<Map<String, dynamic>> getMacLikeIdentifier() async {
  final result = <String, dynamic>{
    'wifiBssid': null,
    'deviceId': null,
    'notes': <String>[],
  };

  // 1️⃣ Try to get Wi-Fi BSSID (router MAC)
  try {
    if (Platform.isAndroid) {
      // Android requires location permission
      var status = await Permission.location.status;
      if (!status.isGranted) {
        status = await Permission.location.request();
      }
      if (!status.isGranted) {
        result['notes'].add('⚠️ Location permission not granted.');
      }
    }

    final info = NetworkInfo();
    final bssid = await info.getWifiBSSID();
    result['wifiBssid'] = bssid ?? 'N/A';
  } catch (e) {
    result['notes'].add('❌ Error reading Wi-Fi BSSID: $e');
  }

  // 2️⃣ Generate or read a persistent device ID
  try {
    String? saved = _box.read(_storageKey);
    if (saved == null) {
      final newId = const Uuid().v4();
      await _box.write(_storageKey, newId);
      saved = newId;
      result['notes'].add('🆕 New persistent ID created.');
    } else {
      result['notes'].add('✅ Persistent ID loaded from storage.');
    }
    result['deviceId'] = saved;
  } catch (e) {
    result['notes'].add('❌ Error saving/reading device ID: $e');
  }

  return result;
}

/// Widget example to print and display values

class MacAddressWidget extends StatefulWidget {
  const MacAddressWidget({super.key});

  @override
  State<MacAddressWidget> createState() => _MacAddressWidgetState();
}

class _MacAddressWidgetState extends State<MacAddressWidget> {
  String output = 'Fetching info...';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await getMacLikeIdentifier();
    setState(() {
      output = '''
📡 Wi-Fi BSSID (router MAC): ${info['wifiBssid']}
🆔 Device ID: ${info['deviceId']}
📝 Notes: ${(info['notes'] as List).join('\n')}
''';
    });
    print(output); // 👈 also print to console
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Text(output, style: const TextStyle(fontSize: 14)),
    );
  }
}
