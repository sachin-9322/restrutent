import 'package:objectbox/objectbox.dart';
import 'package:splash_screen_03/model/entity_bill_food.dart';
import 'package:splash_screen_03/model/entity_payment.dart';
import 'package:uuid/uuid.dart';

@Entity()
class EntityOrder {
  @Id()
  int orderId = 0;

  String uuid = const Uuid().v4();

  String? mongoId;
  bool isSync = false;
  String? restUuid;
  int? orderNumber = 0;
  String? status;
  String? startTime;
  String? endTime;
  int? printCount;
  String? tableMongoId;

  String? tableName;

  int? tableSeat;
  String? orderTypeId;
  String? userName;
  double? totalAmount;

  // NEW DISCOUNT FIELDS 👇
  double? discountAmount;  
  double? discountPercent; 

  String? customerName;
  String? customerMobile;
  String? customerAddress;
  String? createdOn;
  String? waiterName;
  int? waiterId;

  String? itemsJson;
  String? metaJson;
  String? orderItemsJson;
  int? totalQty;

  ToMany<EntityOrderFood> listFood = ToMany();
  ToMany<Payment> payments = ToMany();

  EntityOrder({
    required this.orderNumber,
    this.status,
    this.restUuid,
    this.startTime,
    this.endTime,
    this.printCount,
    required this.tableName,
     this.tableMongoId,
    required this.tableSeat,
    required this.orderTypeId,
    required this.userName,
    required this.createdOn,
    this.totalAmount,

    // NEW FIELDS DEFAULT
    this.discountAmount = 0,
    this.discountPercent = 0,

    this.customerAddress,
    this.customerMobile,
    this.customerName,
    this.itemsJson,
    this.metaJson,
    this.orderItemsJson,
    this.totalQty,
    String? uuid,
    this.mongoId,
    this.waiterName,
    this.waiterId,
    this.isSync = false,
  }) : uuid = uuid ?? const Uuid().v4();
}
