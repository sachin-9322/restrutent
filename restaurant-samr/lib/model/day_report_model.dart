class OpenDayRow {
  final String startDate;
  final String endDate;
  final String startedBy;
  final String closedBy;
  final double openingBal;
  final double closingBal;
  final String invoiceRange;
  final double expenses;
  final double totalSales;

  final DateTime openedAtRaw; // <-- needed for filtering

  OpenDayRow({
    required this.startDate,
    required this.endDate,
    required this.startedBy,
    required this.closedBy,
    required this.openingBal,
    required this.closingBal,
    required this.invoiceRange,
    required this.expenses,
    required this.totalSales,
    required this.openedAtRaw,
  });
}
