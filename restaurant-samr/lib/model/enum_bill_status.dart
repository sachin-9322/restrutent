/// Enum representing the status of a bill.
///
/// Using an enum for statuses provides type safety and avoids simple string-based errors.
enum BillStatus {
  /// The bill has been fully paid and closed.
  settled('settled'),
  due('due'),

  /// The bill has been voided or cancelled.
  cancelled('cancelled'),

  /// The bill has been marked for deletion (soft delete).
  deleted('deleted'),

  /// The bill is active and associated with a table/order.
  booked('booked'),

  /// The bill is awaiting payment or another action.
  pending('pending');

  const BillStatus(this.value);
  final String value;
}
