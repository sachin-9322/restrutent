class Receipt {
  final int billNo;
  final String tableName;
  final String type;
  final String status;
  final String customer;
  final String phone;
  final String deliveryBoy;
  final String payment;
  final double amount;
  final String billUuid;
  final String? dateFormatted;
  final String? waiter;
  final double dueAmount; // ✅ new field for due amount
  final bool hasHistory; // ✅ To show history icon for paid due bills

  Receipt({
    required this.billNo,
    required this.tableName,
    required this.type,
    required this.status,
    required this.customer,
    required this.phone,
    required this.deliveryBoy,
    required this.payment,
    required this.amount,
    required this.billUuid,
    this.dateFormatted,
    this.waiter,
    this.dueAmount = 0.0,
    this.hasHistory = false, // ✅ default to false
  });
}
