import 'package:objectbox/objectbox.dart';
import 'package:uuid/uuid.dart';

@Entity()
class EntityMenu {
  @Id()
  int id = 0;

  String mongoObjId; 
  String name;

  EntityMenu({
    this.id = 0,
    required this.name,
    String? mongoObjId,
  }) : mongoObjId = mongoObjId ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "mongoObjId": mongoObjId,
      "name": name,
    };
  }
}
