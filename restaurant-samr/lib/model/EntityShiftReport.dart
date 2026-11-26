import 'package:objectbox/objectbox.dart';

@Entity()
class EntityShiftReport {
  int id;

  int dayId; // FK → EntityDayReport.id

  @Property(type: PropertyType.date)
  DateTime startedAt;

  @Property(type: PropertyType.date)
  DateTime? endedAt;

  String username;
  String? comments;

  double openingCash;
  double? closingCash;

  bool isShiftOpen;

  EntityShiftReport({
    this.id = 0,
    required this.dayId,
    required this.username,
    required this.startedAt,
    required this.openingCash,
    this.comments,
    this.endedAt,
    this.closingCash,
    this.isShiftOpen = true,
  });
}
