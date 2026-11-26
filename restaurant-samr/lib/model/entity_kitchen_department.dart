import 'package:objectbox/objectbox.dart';

@Entity()
class EntityKitchenDepartment {
  @Id()
  int id = 0;
  String? name;

  EntityKitchenDepartment({required this.name, this.id = 0});
}
