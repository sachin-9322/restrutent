// entity_cateogry_tax.dart

import 'package:objectbox/objectbox.dart';
import 'entity_name.dart';

@Entity()
class EntityCategoryTax {
  @Id()
  int id = 0;
  String? categoryName;
  
  // ========================= FIX START =========================
  // Add the categoryUuid field to store the unique ID from the server.
  String? categoryUuid;
  // ========================== FIX END ==========================
  String? restUuid;

  ToOne<EntityName> name = ToOne();

  // ========================= FIX START =========================
  // Update the constructor to include the new field.
  EntityCategoryTax({
    this.id = 0,
    this.categoryName,
    this.categoryUuid,
    this.restUuid
  });
  // ========================== FIX END ==========================
}