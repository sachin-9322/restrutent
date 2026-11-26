import 'package:objectbox/objectbox.dart';

@Entity()
class Payment {
  @Id()
  int id = 0; // auto-increment ID

  double price; // amount paid
  String mode; // e.g., "Cash", "UPI", "Card"
  String? utr; // optional transaction reference
  DateTime? date; // payment timestamp

  Payment({required this.price, required this.mode, this.utr, this.date});
}
