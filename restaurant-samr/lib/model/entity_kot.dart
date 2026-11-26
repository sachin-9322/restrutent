import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'package:splash_screen_03/model/entity_food.dart';
import 'entity_bill_food.dart';
import 'dart:convert';

import 'package:uuid/uuid.dart';
// @Entity()
// class EntityKot {
//   @Id()
//   int kotId = 0;
  
//   String? mongoId;
//   String uuid = const Uuid().v4();
//   int? kotNumber;
//   String? origin;
//   String? createdOn;
//   String? tableName;
//   String? itemsJson;
//   String? metaJson;
//   String? status;
//   String? orderType;
//   bool? isSync;

//   ToMany<EntityOrderFood> listFood = ToMany();




//   EntityKot({
//     this.mongoId,
//     this.kotNumber,
//     this.orderId,
//     this.orderNumber,
//     this.createdOn,
//     this.tableName,
//     this.itemsJson,
//     this.metaJson,
//     this.origin,
//     this.status,
//     this.orderType,
//     this.isSync = false,
//     String? uuid, // ✅ Optional for restoring existing records
//   }) : uuid = uuid ?? const Uuid().v4(); // Auto-generate if null

//   /// ✅ Parse JSON (preserves UUID and Mongo ID)
//   factory EntityKot.fromJson(Map<String, dynamic> json) {
//     debugPrint("KOT JSON: $json");

//     final kot = EntityKot(
//       mongoId: json["_id"], // ✅ preserve MongoDB _id if exists
//       kotNumber: json["kotNumber"],
//       orderId: json["orderId"],
//       orderNumber: json["orderNumber"],
//       createdOn: json["createdOn"],
//       tableName: json["tableName"],
//       itemsJson: json["itemsJson"],
//       metaJson: json["metaJson"],
//       origin: json["origin"],
//       status: json["status"],
//       orderType: json["orderType"],
//       isSync: json["isSync"] ?? false,
//       uuid: json["uuid"],
//     );

//     // Parse listFood
//     if (json["listFood"] != null) {
//       kot.listFood.addAll(
//         (json["listFood"] as List<dynamic>)
//             .map((e) => EntityOrderFood.fromJson(e))
//             .toList(),
//       );
//     }

//     return kot;
//   }

//   /// ✅ Convert to JSON for broadcast / sync
//   Map<String, dynamic> toJson() {
//     return {
//       '_id': mongoId, // ✅ MongoDB ID
//       'kotId': kotId,
//       'uuid': uuid,
//       'kotNumber': kotNumber,
//       'orderId': orderId,
//       'orderNumber': orderNumber,
//       'createdOn': createdOn,
//       'tableName': tableName,
//       'itemsJson': itemsJson,
//       'metaJson': metaJson,
//       'origin': origin,
//       'status': status,
//       'orderType': orderType,
//       'isSync': isSync ?? false,
//       'listFood': listFood.map((f) => f.toJson()).toList(),
//     };
//   }

//   /// Convert to JSON string
//   String toJsonString() => jsonEncode(toJson());
// }
class ExtraItem {
  String id;
  String name;
  double price;
  int qty;
  double? prepTime;

  ExtraItem({
    required this.id,
    required this.name,
    required this.price,
    required this.qty,
    this.prepTime,
  });

  factory ExtraItem.fromFood(EntityFood food) {
    return ExtraItem(
      id: food.foodUuid,
      name: food.foodName ?? '',
      price: food.discountPrice ?? 0.0,
      qty: food.qty,
      prepTime: food.prepTime,
    );
  }

  // ✅ Add copyWith
  ExtraItem copyWith({
    String? id,
    String? name,
    double? price,
    int? qty,
    double? prepTime,
  }) {
    return ExtraItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      qty: qty ?? this.qty,
      prepTime: prepTime ?? this.prepTime,
    );
  }
}


class KotReceipt {
  final int kotNumber;
  final int? orderNumber;
  final String tableName;
  final DateTime createdOn;
  final int kotId;

  final int totalQty;
  final double avgPrice;
  final double totalAmount;

  KotReceipt({
    required this.kotNumber,
    this.orderNumber,
    required this.tableName,
    required this.createdOn,
    required this.kotId,
    required this.totalQty,
    required this.avgPrice,
    required this.totalAmount,
  });
}
