import 'package:objectbox/objectbox.dart';

@Entity()
class EntityKitchenOutletMenu {
  @Id()
  int id = 0;

  String name;

  EntityKitchenOutletMenu({required this.name, this.id = 0});
}
