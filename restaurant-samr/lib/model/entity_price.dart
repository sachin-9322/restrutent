import 'package:objectbox/objectbox.dart';

@Entity()
class EntityPrice {
  @Id()
  int id = 0;

  String? roomType;
  String? currency;
  double? price;
  double? discount;

  // NEW: pricing helpers
  double? mrp; // Original price shown with strikethrough
  double? discountPercent; // e.g. 10 for 10%
  double? offerPrice; // Auto-calculated: mrp - (mrp * discount/100)

  String? mongoId; // ✅ MongoDB document ID
  bool isSync = false; // ✅ Whether this price is synced with MongoDB

  EntityPrice({
    this.discount,
    required this.roomType,
    required this.currency,
    required this.price,
    this.mrp,
    this.discountPercent,
    this.offerPrice,
    this.mongoId, // optional MongoDB ID
    this.isSync = false, // default false
  });
}
