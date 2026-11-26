import 'package:objectbox/objectbox.dart';
import 'package:uuid/uuid.dart';

@Entity()
class EntityDayReport {
  @Id()
  int id;

  @Unique()
  String dayUuid;

  String username;
  String? restUuid;

  DateTime openedAt;
  DateTime? closedAt;

  String? openingComments;
  String? closingComments;

  double openingCash;
  double? closingCash;

  double? totalSales;
  double? totalRefunds;
  double? totalExpenses; // NEW for closing summary
  String? currencyCode;
  String? currencySymbol;
  String? currencyLocale;
  bool isOpen;

  String? mongoId;
  bool isSync;
int invoiceStart;
int invoiceEnd;

  final denomCounts = ToMany<EntityDenominationCount>();

  EntityDayReport({
    this.id = 0,
    String? dayUuid,
    required this.username,
    required this.openedAt,
    this.closedAt,
    this.openingComments,
    this.closingComments,
    this.openingCash = 0,
    this.closingCash,
    this.totalSales,
    this.totalRefunds,
    this.totalExpenses, // NEW
    this.isOpen = true,
    this.mongoId,
    this.currencyCode,
    this.currencySymbol,
    this.currencyLocale,
    this.restUuid,
  required this.invoiceStart,
required this.invoiceEnd,

    this.isSync = false,
  }) : dayUuid = dayUuid ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'dayUuid': dayUuid,
    'username': username,
    'openedAt': openedAt.toIso8601String(),
    'closedAt': closedAt?.toIso8601String(),
    'openingComments': openingComments,
    'closingComments': closingComments,
    'openingCash': openingCash,
    'closingCash': closingCash,
    'totalSales': totalSales,
    'totalRefunds': totalRefunds,
    'totalExpenses': totalExpenses, // NEW
    'isOpen': isOpen,
    'mongoId': mongoId,
    'isSync': isSync,
    'invoiceStart': invoiceStart,
'invoiceEnd': invoiceEnd,

    'denomCounts': denomCounts.map((e) => e.toJson()).toList(),
  };

  factory EntityDayReport.fromJson(Map<String, dynamic> json) {
    final r = EntityDayReport(
      id: json['id'] ?? 0,
      dayUuid: json['dayUuid'],
      username: json['username'],
      openedAt: DateTime.parse(json['openedAt']),
      closedAt: json['closedAt'] != null
          ? DateTime.parse(json['closedAt'])
          : null,
      openingComments: json['openingComments'],
      closingComments: json['closingComments'],
      openingCash: (json['openingCash'] ?? 0).toDouble(),
      closingCash: (json['closingCash'] as num?)?.toDouble(),
      totalSales: (json['totalSales'] as num?)?.toDouble(),
      totalRefunds: (json['totalRefunds'] as num?)?.toDouble(),
      totalExpenses: (json['totalExpenses'] as num?)?.toDouble(), // NEW
      isOpen: json['isOpen'] ?? true,
      mongoId: json['mongoId'],
      isSync: json['isSync'] ?? false,
      invoiceStart: json['invoiceStart'] ?? 0,
invoiceEnd: json['invoiceEnd'] ?? 0,

    );
    if (json['denomCounts'] is List) {
      r.denomCounts.addAll(
        (json['denomCounts'] as List).map(
          (e) => EntityDenominationCount.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        ),
      );
    }
    return r;
  }
}

@Entity()
class EntityDenominationCount {
  @Id()
  int id;

  String label;
  double unitValue;
  int count;

  EntityDenominationCount({
    this.id = 0,
    required this.label,
    required this.unitValue,
    this.count = 0,
  });

  double get amount => unitValue * count;

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'unitValue': unitValue,
    'count': count,
    'amount': amount,
  };

  factory EntityDenominationCount.fromJson(Map<String, dynamic> json) {
    return EntityDenominationCount(
      id: json['id'] ?? 0,
      label: json['label'],
      unitValue: (json['unitValue'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
    );
  }
}
