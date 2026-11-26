import 'package:objectbox/objectbox.dart';

@Entity()
class EntityName {
  @Id()
  int id = 0;

  String? hi;
  String? en;
  EntityName({required this.hi, required this.en});
}