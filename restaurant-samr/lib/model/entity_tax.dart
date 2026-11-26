import 'package:objectbox/objectbox.dart';
import 'package:uuid/uuid.dart';

@Entity()
class EntityTax {
  @Id()
  int id = 0;

  String? taxProductName; // VAT, GST, food, drinks
  double? taxPercentage;
  bool? isSgstCgst;
  bool? isActive;
  bool? isHideTaxDetail;
  bool? isIncludeInRate;   // Exclusive or Inclusive
  bool? isPrintOnBill;

  @Unique()
  String? taxUuid;

  String? mongoId; // ✅ MongoDB document ID
  bool isSync = false; // ✅ Whether this tax is synced with MongoDB

  EntityTax({
    this.id = 0,
    this.isIncludeInRate = false,  // if false = exclusive
    this.isPrintOnBill = false,
    String? taxUuid, // optional UID
    required this.taxProductName,
    required this.taxPercentage,
    this.isSgstCgst = false,
    this.isActive = true,
    this.isHideTaxDetail = false,
    this.mongoId,     // optional MongoDB ID
    this.isSync = false, // default false
  }) : taxUuid = taxUuid ?? const Uuid().v4(); // auto-generate if not supplied

  // Optional: convert to JSON
  Map<String, dynamic> toJson() => {
        "id": id,
        "taxUuid": taxUuid,
        "taxProductName": taxProductName,
        "taxPercentage": taxPercentage,
        "isSgstCgst": isSgstCgst,
        "isActive": isActive,
        "isHideTaxDetail": isHideTaxDetail,
        "isIncludeInRate": isIncludeInRate,
        "isPrintOnBill": isPrintOnBill,
        "mongoId": mongoId,
        "isSync": isSync,
      };

  // Optional: decode from JSON
  factory EntityTax.fromJson(Map<String, dynamic> json) {
    return EntityTax(
      id: json['id'] ?? 0,
      taxProductName: json['taxProductName'],
      taxPercentage: json['taxPercentage'],
      isSgstCgst: json['isSgstCgst'] ?? false,
      isActive: json['isActive'] ?? true,
      isHideTaxDetail: json['isHideTaxDetail'] ?? false,
      isIncludeInRate: json['isIncludeInRate'] ?? false,
      isPrintOnBill: json['isPrintOnBill'] ?? false,
      taxUuid: json['taxUuid'],
      mongoId: json['mongoId'],
      isSync: json['isSync'] ?? false,
    );
  }
}
