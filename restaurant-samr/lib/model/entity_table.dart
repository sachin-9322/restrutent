import 'dart:convert';
import 'package:objectbox/objectbox.dart';
import 'package:uuid/uuid.dart';

@Entity()
class EntityTable {
  @Id()
  int tableId = 0;

  String? roomType; // Dropdown from EntityRoomType table
  String? roomUuid;
  String? tableName;
  int? seats;

  int? orderNumber;
  bool? isActive;
  String? tableStatus;

  @Unique()
  late String tableUid;

  String? mongoId; // ✅ MongoDB document ID
  bool isSync = false; // ✅ Whether this table is synced with MongoDB

  EntityTable({
    required this.roomType,
    required this.tableName,
    required this.seats,
    this.roomUuid,
    this.orderNumber,
    this.isActive = true,
    this.tableStatus = "Available", // ✅ default status
    this.tableId = 0,
    String? tableUid, // optional UID
    this.mongoId, // optional MongoDB ID
    this.isSync = false, // default false
  }) : tableUid =
           tableUid ?? const Uuid().v4(); // ✅ use passed one or generate new

  // ✅ Convert to JSON
  Map<String, dynamic> toJson() => {
    "tableId": tableId,
    "tableUid": tableUid,
    "tableName": tableName,
    "roomType": roomType,
    "roomUuid": roomUuid,
    "seats": seats,
    "orderNumber": orderNumber,
    "isActive": isActive ?? true,
    "tableStatus": tableStatus,
    "mongoId": mongoId,
    "isSync": isSync,
  };
  factory EntityTable.fromJson(Map<String, dynamic> json) {
    return EntityTable(
      tableId: 0,
      tableName: json['label'], // FIXED
      roomType: json['tableSectionName']?['en'], // FIXED
      roomUuid: json['tableSectionId'], // FIXED
      seats: json['capacity'], // FIXED
      orderNumber: null,
      isActive: json['isAvailable'], // FIXED
      tableStatus: "Available",
      tableUid: json['tableUid'],
      mongoId: json['_id'], // FIXED
      isSync: true,
    );
  }
}
