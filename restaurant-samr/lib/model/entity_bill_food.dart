import 'package:objectbox/objectbox.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

@Entity()
class EntityOrderFood {
  @Id()
  int billFoodId = 0;

  int? orderId;

  String? mongoId;
  bool? isSync;
  String? restUuid;

  int kotId = 0;
  String uuid = const Uuid().v4();
  int? kotNumber;
  String? origin;
  String? createdOn;
  String? tableName;
  String? status;
  String? orderType;
  String? metaJson;

  int? foodId;
  String? name;
  String? category;
  int? taxPercentage; // consider double if you need decimals (e.g., 7.5)
  int? quantity;
  double? price; // unit price

  // Pizza options
  String? size; // quarter, half, full, small, medium, large
  String? addOn1; // e.g., cheese, peri peri

  // Persistable representation of add-on list
  String? addOnsJson;

  // Runtime-only list for convenience (ObjectBox can't persist List<String> directly)
  @Transient()
  List<String>? addOn2;

  String? itemsJson;

  EntityOrderFood({
    this.mongoId,
    this.isSync = false,
    this.orderId,
    required this.foodId,
    required this.name,
    required this.category,
    required this.taxPercentage,
    this.quantity = 1,
    this.price = 0.0,
    // KOT fields
    this.kotId = 0,
    String? uuid,
    this.kotNumber,
    this.origin,
    this.createdOn,
    this.tableName,
    this.itemsJson,
    this.metaJson,
    this.status,
    this.orderType,
    // New fields
    this.size,
    this.addOn1,
    this.addOnsJson,
    this.addOn2,
    this.restUuid,
  }) : uuid = uuid ?? const Uuid().v4() {
    // keep JSON in sync if list was provided
    if (addOn2 != null && (addOnsJson == null || addOnsJson!.isEmpty)) {
      addOnsJson = jsonEncode(addOn2);
    }
  }

  // Convenient getter that always returns a list of add-ons
  List<String> get addOns {
    if (addOn2 != null) return addOn2!;
    if (addOnsJson == null || addOnsJson!.isEmpty) return <String>[];
    try {
      final v = jsonDecode(addOnsJson!);
      if (v is List) return v.map((e) => e.toString()).toList();
    } catch (_) {}
    return <String>[];
  }

  // Setter to keep both transient list and JSON in sync
  void setAddOns(List<String> v) {
    addOn2 = v;
    addOnsJson = jsonEncode(v);
  }

  // Pricing helpers
  double get unitPrice => price ?? 0.0;
  double get subTotal => unitPrice * (quantity ?? 0);
  double get taxRate => (taxPercentage ?? 0) / 100.0;
  double get taxAmount => subTotal * taxRate;
  double get total => subTotal + taxAmount;

  // Recalculate unit price from base + options
  void recalcUnitPrice({
    required double basePrice,
    Map<String, double> sizeDeltas =
        const {}, // e.g., {'medium': 40, 'large': 90}
    Map<String, double> sizeMultipliers =
        const {}, // e.g., {'medium': 1.2, 'large': 1.5}
    Map<String, double> addOnPrices =
        const {}, // e.g., {'cheese': 30, 'peri peri': 20}
    bool useSizeMultipliers = false,
  }) {
    double p = basePrice;

    if (size != null && size!.isNotEmpty) {
      if (useSizeMultipliers && sizeMultipliers.isNotEmpty) {
        p *= (sizeMultipliers[size!] ?? 1.0);
      } else {
        p += (sizeDeltas[size!] ?? 0.0);
      }
    }

    if (addOn1 != null && addOn1!.isNotEmpty) {
      p += (addOnPrices[addOn1!] ?? 0.0);
    }
    for (final a in addOns) {
      p += (addOnPrices[a] ?? 0.0);
    }

    price = p;
  }

  factory EntityOrderFood.fromJson(Map<String, dynamic> json) {
    // handle addOn2 arriving as list or JSON string
    List<String>? addOn2List;
    final a2 = json['addOn2'];
    if (a2 is List) {
      addOn2List = a2.map((e) => e.toString()).toList();
    } else if (a2 is String && a2.isNotEmpty) {
      try {
        final decoded = jsonDecode(a2);
        if (decoded is List) {
          addOn2List = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    final addOnsJsonStr =
        json['addOnsJson'] ??
        (addOn2List != null ? jsonEncode(addOn2List) : null);

    return EntityOrderFood(
      mongoId: json["_id"],
      isSync: json["isSync"] ?? false,
      orderId: json["orderId"],
      foodId: json["foodId"],
      name: json["name"],
      category: json["category"],
      taxPercentage: json["taxPercentage"],
      quantity: json["quantity"] ?? 1,
      price: _asDouble(json["price"]),
      kotId: json["kotId"] ?? 0,
      uuid: json["uuid"],
      kotNumber: json["kotNumber"],
      origin: json["origin"],
      createdOn: json["createdOn"],
      tableName: json["tableName"],
      itemsJson: json["itemsJson"],
      metaJson: json["metaJson"],
      status: json["status"],
      orderType: json["orderType"],
      size: json['size'],
      addOn1: json['addOn1'],
      restUuid: json['restUuid'],

      addOn2: addOn2List,
      addOnsJson: addOnsJsonStr,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': mongoId,
      'billFoodId': billFoodId,
      'orderId': orderId,
      'isSync': isSync ?? false,

      'kotId': kotId,
      'uuid': uuid,
      'kotNumber': kotNumber,
      'origin': origin,
      'createdOn': createdOn,
      'tableName': tableName,
      'metaJson': metaJson,
      'status': status,
      'orderType': orderType,

      'foodId': foodId,
      'name': name,
      'category': category,
      'taxPercentage': taxPercentage,
      'quantity': quantity,
      'price': price,

      // options
      'size': size,
      'addOn1': addOn1,
      'addOnsJson': addOnsJson ?? (addOn2 != null ? jsonEncode(addOn2) : null),
      // For compatibility with clients expecting array
      'addOn2': addOns,

      // KOT compatibility
      'itemsJson': itemsJson,
      "restUuid": restUuid ?? "",
      // Optional: expose computed values for APIs/UI (remove if you don't want these serialized)
      'subTotal': subTotal,
      'taxAmount': taxAmount,
      'total': total,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  // helpers for printed flag inside metaJson
  bool get isPrinted {
    try {
      if (metaJson == null || metaJson!.isEmpty) return false;
      final m = jsonDecode(metaJson!) as Map<String, dynamic>;
      return m['printed'] == true;
    } catch (_) {
      return false;
    }
  }

  void setPrinted(bool val) {
    Map<String, dynamic> m = {};
    try {
      if (metaJson != null && metaJson!.isNotEmpty) {
        final dec = jsonDecode(metaJson!);
        if (dec is Map<String, dynamic>) m = Map<String, dynamic>.from(dec);
      }
    } catch (_) {}
    m['printed'] = val;
    m['printedOn'] = DateTime.now().toIso8601String();
    metaJson = jsonEncode(m);
  }

  static double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}
