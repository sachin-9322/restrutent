import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'package:uuid/uuid.dart';

@Entity()
class EntityRoomType {
  @Id()
  int id = 0; // simpler

  String? name;
  bool? isActive;

  @Unique()
  late String roomUuid;

  String? mongoId; // ✅ MongoDB document ID
  bool isSync = false; // ✅ Whether this room type is synced with MongoDB

  EntityRoomType({
    required this.name,
    this.isActive = true,
    String? roomUuid,
    this.id = 0,
    this.mongoId, // optional MongoDB ID
    this.isSync = false, // default false
  }) : roomUuid = roomUuid ?? const Uuid().v4();

  // Convert to JSON for Captain app
  Map<String, dynamic> toJson() => {
        "id": id,
        "roomUuid": roomUuid,
        "name": name,
        "isActive": isActive ?? false,
        "mongoId": mongoId,
        "isSync": isSync,
      };

  // Optional: decode back from JSON
  factory EntityRoomType.fromJson(Map<String, dynamic> json) {
    debugPrint("JSON: $json");
    return EntityRoomType(
      id: json["id"] ?? 0,
      name: json["name"],
      isActive: json["isActive"] ?? true,
      roomUuid: json["roomUuid"],
      mongoId: json["mongoId"],
      isSync: json["isSync"] ?? false,
    );
  }
}
