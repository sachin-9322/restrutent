// lib/controllers/discovered_server.dart

import 'dart:convert';

/// A data class to hold information about a discovered server.
class DiscoveredServer {
  final String name;
  final String address; // e.g., "192.168.1.10:4040"

  DiscoveredServer({required this.name, required this.address});

  /// A display-friendly representation, e.g., "My-PC (192.168.1.10:4040)"
  String get displayName => '$name ($address)';

  // We need to override these for list operations like .contains() to work correctly.
  // Two servers are considered the same if they have the same address.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiscoveredServer && other.address == address;
  }

  @override
  int get hashCode => address.hashCode;

  // For saving to and loading from GetStorage
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
    };
  }

  factory DiscoveredServer.fromMap(Map<String, dynamic> map) {
    return DiscoveredServer(
      name: map['name'] ?? 'Unknown Server',
      address: map['address'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory DiscoveredServer.fromJson(String source) =>
      DiscoveredServer.fromMap(json.decode(source));
}