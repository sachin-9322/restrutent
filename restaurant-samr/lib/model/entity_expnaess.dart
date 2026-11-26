import 'package:objectbox/objectbox.dart';
import 'package:uuid/uuid.dart';

@Entity()
class VendorEntity {
  @Id()
  int id = 0;

  String name;
  String phone;
  String? description;
  String uuid;

  VendorEntity({
    required this.name,
    required this.phone,
    this.description,
  }) : uuid = const Uuid().v4();
}

@Entity()
class CategoryEntity {
  @Id()
  int id = 0;

  String name;
  String vendorUuid;
  String uuid;

  CategoryEntity({
    required this.name,
    required this.vendorUuid,
  }) : uuid = const Uuid().v4();
}

@Entity()
class ExpenseEntity {
  @Id()
  int id = 0;

  double amount;
  int dateMillis;
  String paymentMode;
  String? description;
  bool nonRefundable;
  String? vendorUuid;
  String? categoryUuid;
  String uuid;

  ExpenseEntity({
    required this.amount,
    required DateTime date,
    this.paymentMode = 'Cash',
    this.description,
    this.nonRefundable = false,
    this.vendorUuid,
    this.categoryUuid,
  })  : dateMillis = date.millisecondsSinceEpoch,
        uuid = const Uuid().v4();

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(dateMillis);
}
