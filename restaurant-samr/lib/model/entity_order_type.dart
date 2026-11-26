import 'package:objectbox/objectbox.dart';
import 'package:uuid/uuid.dart';

@Entity()
class EntityOrderType {
  @Id()
  int id = 0;

  String? name; // Zomato, Pasta, etc.

  @Unique()
  late String orderTypeUid;

  String? mongoId; // ✅ MongoDB document ID
  bool isSync = false; // ✅ Whether this order type is synced with MongoDB

  EntityOrderType({
    required this.name,
    String? orderTypeUid,
    this.id = 0,
    this.mongoId, // optional MongoDB ID
    this.isSync = false, // default false
  }) : orderTypeUid = orderTypeUid ?? const Uuid().v4(); // ✅ auto-generate UID
}
