// repository/Base64.dart
import 'dart:convert';
import 'package:get_storage/get_storage.dart';

class StorageRepository {
  final GetStorage _storage = GetStorage();

  bool readBool(String key, {bool defaultValue = false}) {
    return _storage.read(key) ?? defaultValue;
  }

  void writeBool(String key, bool value) {
    _storage.write(key, value);
  }

  // -------------------------- Generic helpers --------------------------

  /// Encodes and stores a string value safely.
  void _writeEncoded(String key, String value) {
    String encoded = base64Encode(utf8.encode(value));
    _storage.write(key, encoded);
  }

  /// Reads and decodes a Base64 string value.
  String _readDecoded(String key) {
    String? encoded = _storage.read(key);
    if (encoded == null || encoded.isEmpty) return '';
    try {
      return utf8.decode(base64Decode(encoded));
    } catch (_) {
      return encoded; // fallback in case it's not encoded
    }
  }

  /// Deletes a specific key.
  void deleteKey(String key) => _storage.remove(key);

  /// Clears all stored data.
  void clearAll() => _storage.erase();

  // -------------------------- Auth Info --------------------------

  set username(String value) => _writeEncoded('username', value);
  String get username => _readDecoded('username');

  set password(String value) => _writeEncoded('password', value);
  String get password => _readDecoded('password');

  set accessToken(String value) => _writeEncoded('accessToken', value);
  String get accessToken => _readDecoded('accessToken');

  set refreshToken(String value) => _writeEncoded('refreshToken', value);
  String get refreshToken => _readDecoded('refreshToken');

  set sessionId(String value) => _storage.write('sessionId', value);
  String get sessionId => _storage.read('sessionId') ?? '';

  // -------------------------- User / Role Info --------------------------

  set userType(String value) => _writeEncoded('userType', value);
  String get userType => _readDecoded('userType');

  set userId(String value) => _writeEncoded('userId', value);
  String get userId => _readDecoded('userId');

  // -------------------------- Restaurant Info --------------------------
  set brandId(String value) => _storage.write('brandId', value);
  String get brandId => _storage.read('brandId') ?? '';

  // Store restaurant JSON normally (no Base64!)
  set restaurant(String jsonValue) => _storage.write('restaurant', jsonValue);
  String get restaurant => _storage.read('restaurant') ?? '';

  // -------------------------- Server Info --------------------------

  set serverIpPort(String value) => _writeEncoded('serverIpPort', value);
  String get serverIpPort => _readDecoded('serverIpPort');

  // -------------------------- Utility --------------------------

  /// Returns true if credentials exist.
  bool get hasCredentials =>
      username.isNotEmpty && password.isNotEmpty && accessToken.isNotEmpty;

  // -------------------------- Sync feature flag --------------------------
  // ADD BOTH setter and getter so you can write/read easily.
  //set isSyncFeature(bool value) => _storage.write('isSyncFeature', value);
  set isSyncFeature(bool value) => _storage.write('isSyncFeature', value);
  bool get isSyncFeature => _storage.read('isSyncFeature') ?? false;
  // -------------------------- Restaurant ID Getter --------------------------
  String get restaurantId {
    try {
      if (restaurant.isEmpty) return '';
      final data = jsonDecode(restaurant);

      // Backend sends `_id`, not `id`
      return data['_id']?.toString() ?? data['id']?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  // -------------------------- Tax Product Groups --------------------------
  set taxProductGroups(String jsonValue) =>
      _storage.write('taxProductGroups', jsonValue);
  String get taxProductGroups => _storage.read('taxProductGroups') ?? '';
}
