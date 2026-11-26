import 'dart:convert';
class StaticMethods {

  //how to use? StaticMethods.encodeString(originalString: 'Hello, Dart! 🌍')
  // 'Hello, Dart! 🌍' => SGVsbG8sIERhcnQhIPCfjI0=
  static Future<String> encodeString({required String originalString}) async {
    final stringToBase64Codec = utf8.fuse(base64);
    final encodedString = stringToBase64Codec.encode(originalString);
    return encodedString;
  }

  // how to use? StaticMethods.decodeString(encodedString: 'SGVsbG8sIERhcnQhIPCfjI0=')
  // SGVsbG8sIERhcnQhIPCfjI0= => 'Hello, Dart! 🌍'
  static Future<String> decodeString({required String encodedString}) async {
    final stringToBase64Codec = utf8.fuse(base64);
    final originalString = stringToBase64Codec.decode(encodedString);
    return originalString;
  }
}