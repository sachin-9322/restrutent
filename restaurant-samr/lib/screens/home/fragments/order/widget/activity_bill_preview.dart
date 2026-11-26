import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:splash_screen_03/model/entity_bill.dart';
import 'package:splash_screen_03/model/entity_food.dart';
import 'package:splash_screen_03/model/entity_kot.dart';
import 'package:splash_screen_03/model/model_restaurant.dart';
import 'package:splash_screen_03/repository/Base64.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/controller_setting.dart';

class BillPreviewDialog extends StatefulWidget {
  final EntityOrder bill;
  final Map<String, List<MapEntry<dynamic, int>>> groupedItems;
  final List<int> kotNumbers;

  const BillPreviewDialog({
    super.key,
    required this.bill,
    required this.groupedItems,
    required this.kotNumbers,
  });

  @override
  State<BillPreviewDialog> createState() => _BillPreviewDialogState();
}

class _BillPreviewDialogState extends State<BillPreviewDialog> {
  late int _totalQty;
  late double _totalAmount;
  late String _formattedDate;
  late String _formattedTime;

  ModelRestaurant? _restaurant;

  @override
  void initState() {
    super.initState();
    _loadRestaurant();
    _calculateBillData();
  }

  // ✅ Load restaurant info from StorageRepository
  void _loadRestaurant() {
    try {
      final storage = StorageRepository();
      final data = storage.restaurant;
      if (data.isNotEmpty) {
        final decoded = jsonDecode(data);
        // 🔥 Use fromApi because login controller saves raw API JSON
        _restaurant = ModelRestaurant.fromApi(decoded);
      }
    } catch (e) {
      print("⚠️ Failed to load restaurant info: $e");
    }
  }

  double _getPrice(dynamic item) {
    if (item is EntityFood) {
      return item.price.isNotEmpty ? (item.price.first.price ?? 0.0) : 0.0;
    }
    if (item is ExtraItem) {
      return item.price;
    }
    return 0.0;
  }

  String _getName(dynamic item) {
    if (item is EntityFood) {
      return item.foodName ?? 'Unknown Item';
    }
    if (item is ExtraItem) {
      return item.name;
    }
    return 'N/A';
  }

  void _calculateBillData() {
    _totalQty = 0;
    _totalAmount = 0.0;
    widget.groupedItems.forEach((_, items) {
      for (var entry in items) {
        _totalQty += entry.value;
        _totalAmount += _getPrice(entry.key) * entry.value;
      }
    });

    final created = widget.bill.createdOn;
    DateTime billDate = (created != null && created.isNotEmpty)
        ? DateTime.tryParse(created) ?? DateTime.now()
        : DateTime.now();

    _formattedDate = DateFormat('dd MMM yyyy').format(billDate.toLocal());
    _formattedTime = DateFormat('hh:mm a').format(billDate.toLocal());
  }

  Widget _buildBillContent() {
    final storage = StorageRepository();

    final restaurantName = _restaurant?.name ?? "Restaurant";
    final restaurantAddress = _restaurant?.address ?? "";
    final restaurantGst = _restaurant?.gstNumber ?? "";
    final restaurantContact = _restaurant?.mobileNumber ?? "";

    final loggedInUser = storage.username.isNotEmpty
        ? storage.username
        : "User";
    final waiterName = "Waiter";

    const TextStyle boldStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.black,
      fontSize: 13,
    );
    const TextStyle regularStyle = TextStyle(color: Colors.black, fontSize: 13);
    const double verticalSpacer = 4.0;

    final allItems = widget.groupedItems.entries
        .expand((e) => e.value)
        .toList();
    final currencyFormatter = NumberFormat.currency(
      symbol: "₹",
      decimalDigits: 0,
      locale: 'en_IN',
    );
    final plainNumberFormatter = NumberFormat("#,##0", "en_IN");

    return Container(
      width: 300,
      padding: const EdgeInsets.all(12.0),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 🏪 Restaurant Header
          if (restaurantName.isNotEmpty)
            Text(
              restaurantName.toUpperCase(),
              style: boldStyle.copyWith(fontSize: 20),
              textAlign: TextAlign.center,
            ),
          if (restaurantAddress.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                restaurantAddress,
                style: regularStyle.copyWith(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          if (restaurantContact.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                "Ph: $restaurantContact",
                style: regularStyle.copyWith(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          if (restaurantGst.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                "GST: $restaurantGst",
                style: regularStyle.copyWith(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),

          SizedBox(height: verticalSpacer * 2),

          // Bill Info
          Text(
            'Bill No: ${widget.bill.orderNumber ?? 0}',
            style: boldStyle.copyWith(fontSize: 14),
          ),
          if (widget.kotNumbers.isNotEmpty)
            Text(
              'KOT No(s): ${widget.kotNumbers.join(', ')}',
              style: boldStyle.copyWith(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          Text(
            'Table: ${widget.bill.tableName ?? 'N/A'}',
            style: boldStyle.copyWith(fontSize: 14),
          ),
          Text(_formattedDate, style: regularStyle.copyWith(fontSize: 12)),
          Text(_formattedTime, style: regularStyle.copyWith(fontSize: 12)),
          SizedBox(height: verticalSpacer * 2),
          SizedBox(height: verticalSpacer),

          // 🧾 User and Waiter row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'User: $loggedInUser',
                style: regularStyle.copyWith(fontSize: 12),
              ),
              Text(
                'Waiter: $waiterName',
                style: regularStyle.copyWith(fontSize: 12),
              ),
            ],
          ),
          const Divider(color: Colors.black, thickness: 1.5),

          // Column Headers
          Row(
            children: [
              Expanded(child: Text('Item', style: boldStyle)),
              SizedBox(
                width: 40,
                child: Text(
                  'Qty',
                  textAlign: TextAlign.center,
                  style: boldStyle,
                ),
              ),
              SizedBox(
                width: 55,
                child: Text(
                  'Rate',
                  textAlign: TextAlign.right,
                  style: boldStyle,
                ),
              ),
              SizedBox(
                width: 55,
                child: Text(
                  'Amt',
                  textAlign: TextAlign.right,
                  style: boldStyle,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.black, thickness: 1.5),
          SizedBox(height: verticalSpacer / 2),

          // Item Rows
          ...allItems.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(_getName(entry.key), style: regularStyle),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${entry.value}',
                      textAlign: TextAlign.center,
                      style: boldStyle,
                    ),
                  ),
                  SizedBox(
                    width: 55,
                    child: Text(
                      plainNumberFormatter.format(_getPrice(entry.key)),
                      textAlign: TextAlign.right,
                      style: regularStyle,
                    ),
                  ),
                  SizedBox(
                    width: 55,
                    child: Text(
                      plainNumberFormatter.format(
                        _getPrice(entry.key) * entry.value,
                      ),
                      textAlign: TextAlign.right,
                      style: boldStyle,
                    ),
                  ),
                ],
              ),
            );
          }),

          SizedBox(height: verticalSpacer),
          const Divider(color: Colors.black, thickness: 1.5),

          // Totals Section
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Grand Total: ', style: boldStyle.copyWith(fontSize: 16)),
              Text(
                currencyFormatter.format(_totalAmount),
                style: boldStyle.copyWith(fontSize: 16),
              ),
            ],
          ),

          SizedBox(height: verticalSpacer * 2),
          const Divider(color: Colors.black, thickness: 1.5),

          Text(
            'Thank You! Visit Again',
            style: regularStyle.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBillContent(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black87),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
