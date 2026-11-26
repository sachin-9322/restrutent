import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:objectbox/objectbox.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:splash_screen_03/model/entity_expnaess.dart';

class ExpenseController extends GetxController {
  // Assuming Get.find can locate these boxes after they are initialized.
  final Box<ExpenseEntity> boxExpense = Get.find<Box<ExpenseEntity>>();
  final Box<VendorEntity> boxVendor = Get.find<Box<VendorEntity>>();
  final Box<CategoryEntity> boxCategory = Get.find<Box<CategoryEntity>>();

  var expenses = <ExpenseEntity>[].obs;
  var vendors = <VendorEntity>[].obs;
  var categories = <CategoryEntity>[].obs;

  @override
  void onInit() {
    super.onInit();
    boxExpense.query().watch(triggerImmediately: true).listen((_) => loadAll());
    boxVendor.query().watch(triggerImmediately: true).listen((_) => loadAll());
    boxCategory.query().watch(triggerImmediately: true).listen((_) => loadAll());
  }

  void loadAll() {
    expenses.value = boxExpense.getAll()..sort((a, b) => b.dateMillis.compareTo(a.dateMillis));
    vendors.value = boxVendor.getAll();
    categories.value = boxCategory.getAll();
  }
  Future<int> updateExpense(ExpenseEntity expense) async {
    return boxExpense.put(expense);
  }
  List<double> getDailyExpensesForLastNDays(int n) {
    final now = DateTime.now();
    final dailyTotals = List<double>.filled(n, 0.0);
    final startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: n - 1));

    for (final expense in expenses) {
      if (!expense.date.isBefore(startDate)) {
        final index = expense.date.difference(startDate).inDays;
        if (index >= 0 && index < n) {
          dailyTotals[index] += expense.amount;
        }
      }
    }
    return dailyTotals;
  }

  double get todayExpenses {
    final now = DateTime.now();
    return expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month && e.date.day == now.day)
        .fold(0.0, (s, e) => s + e.amount);
  }

  double get thisMonthExpenses {
    final now = DateTime.now();
    return expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (s, e) => s + e.amount);
  }

  double get totalExpenses => expenses.fold(0.0, (s, e) => s + e.amount);

  Future<int> addExpense(ExpenseEntity e) => Future.value(boxExpense.put(e));

  Future<int> addVendor(VendorEntity v, {String? categoryName}) async {
    final id = boxVendor.put(v);
    if (categoryName != null && categoryName.isNotEmpty) {
      await addCategory(CategoryEntity(name: categoryName, vendorUuid: v.uuid));
    }
    return id;
  }

  Future<int> addCategory(CategoryEntity c) => Future.value(boxCategory.put(c));

  Future<void> deleteExpenseById(int id) async => boxExpense.remove(id);

  @override
  Future<void> refresh() async => loadAll();
}

//================================================================================
// DIALOGS
//================================================================================

class _ExpenseFormRow {
  final TextEditingController amountC = TextEditingController();
  final TextEditingController descriptionC = TextEditingController();
  VendorEntity? selectedVendor;
  CategoryEntity? selectedCategory;
  String paymentMode = 'Cash';
  DateTime selectedDate = DateTime.now();
  bool nonRefundable = false;

  void dispose() {
    amountC.dispose();
    descriptionC.dispose();
  }
}

void showAddMultipleExpensesDialog(BuildContext context, ExpenseController controller) {
  final List<_ExpenseFormRow> formRows = [_ExpenseFormRow()];

  showDialog(
    context: context,
    builder: (_) => WillPopScope(
      onWillPop: () async {
        for (var row in formRows) {
          row.dispose();
        }
        return true;
      },
      child: StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Add Expenses", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                      IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: Colors.deepPurple.shade100),
                        icon: const Icon(Icons.add, color: Colors.deepPurple),
                        tooltip: "Add another expense item",
                        onPressed: () => setState(() => formRows.add(_ExpenseFormRow())),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: formRows.length,
                      itemBuilder: (context, index) {
                        return _buildExpenseRowWidget(
                          context: context,
                          controller: controller,
                          formRow: formRows[index],
                          setState: setState,
                          showDelete: formRows.length > 1,
                          onDelete: () {
                            setState(() {
                              formRows[index].dispose();
                              formRows.removeAt(index);
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          // ✅ MODIFICATION: Validation logic updated
                          for (final row in formRows) {
                            final amount = double.tryParse(row.amountC.text.trim());
                            if (row.selectedVendor == null || amount == null || amount <= 0) {
                              Get.snackbar("Invalid Expense", "Please select a vendor and enter a valid amount.", backgroundColor: Colors.red, colorText: Colors.white);
                              return; // Stop the submission
                            }
                            await controller.addExpense(
                              // ✅ MODIFICATION: categoryUuid is now omitted
                              ExpenseEntity(
                                amount: amount,
                                date: row.selectedDate,
                                paymentMode: row.paymentMode,
                                description: row.descriptionC.text.trim(),
                                vendorUuid: row.selectedVendor?.uuid,
                                nonRefundable: row.nonRefundable,
                              ),
                            );
                          }
                          Navigator.pop(context);
                          Get.snackbar("Success", "${formRows.length} expense(s) added!", backgroundColor: Colors.green, colorText: Colors.white);
                        },
                        child: Text("Save ${formRows.length} Expense(s)"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

// ⭐️⭐️⭐️ FULLY REDESIGNED ROW WIDGET WITH ALL FIELDS ⭐️⭐️⭐️
Widget _buildExpenseRowWidget({
  required BuildContext context,
  required ExpenseController controller,
  required _ExpenseFormRow formRow,
  required void Function(void Function()) setState,
  required bool showDelete,
  required VoidCallback onDelete,
}) {
  return Card(
    elevation: 2,
    margin: const EdgeInsets.symmetric(vertical: 8.0),
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // --- ROW 1: VENDOR, AMOUNT, DELETE ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                // ✅ MODIFICATION: Removed Obx as per your code
                child: DropdownButtonFormField<VendorEntity>(
                  value: formRow.selectedVendor,
                  decoration: InputDecoration(labelText: "Vendor", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true),
                  items: controller.vendors.map((v) => DropdownMenuItem(value: v, child: Text(v.name))).toList(),
                  onChanged: (val) => setState(() => formRow.selectedVendor = val),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: formRow.amountC,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: "Amount", prefixIcon: const Icon(Icons.attach_money, size: 18), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true),
                ),
              ),
              if (showDelete)
                IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: onDelete, tooltip: "Remove this item"),
            ],
          ),
          const SizedBox(height: 12),
          // --- ROW 2: DESCRIPTION, PAYMENT MODE ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: formRow.descriptionC,
                  decoration: InputDecoration(labelText: "Description", prefixIcon: const Icon(Icons.description, size: 18), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: formRow.paymentMode,
                  decoration: InputDecoration(labelText: "Payment", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true),
                  items: ['Cash', 'Card', 'UPI', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => formRow.paymentMode = val!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // --- ROW 3: DATE, NON-REFUNDABLE ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: formRow.selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                    if (picked != null) {
                      setState(() => formRow.selectedDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 8),
                        Text(DateFormat.yMMMd().format(formRow.selectedDate)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text("Non-Refundable"),
              Switch(
                value: formRow.nonRefundable,
                onChanged: (val) => setState(() => formRow.nonRefundable = val),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}


void showAddVendorDialog(BuildContext context, ExpenseController controller) {
  // ... (This function is unchanged)
  final nameC = TextEditingController();
  final phoneC = TextEditingController();
  final descC = TextEditingController();
  final categoryC = TextEditingController();

  showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Add Vendor", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                  const SizedBox(height: 16),
                  TextField(controller: nameC, decoration: InputDecoration(labelText: "Vendor Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixIcon: const Icon(Icons.person))),
                  const SizedBox(height: 12),
                  TextField(controller: categoryC, decoration: InputDecoration(labelText: "Category Name (Optional)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixIcon: const Icon(Icons.category))),
                  const SizedBox(height: 12),
                  TextField(controller: phoneC, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: "Phone", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixIcon: const Icon(Icons.phone))),
                  const SizedBox(height: 12),
                  TextField(controller: descC, decoration: InputDecoration(labelText: "Company Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixIcon: const Icon(Icons.business))),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          final name = nameC.text.trim();
                          final phone = phoneC.text.trim();
                          if (name.isEmpty || phone.isEmpty) {
                            Get.snackbar("Error", "Name and phone required", backgroundColor: Colors.red, colorText: Colors.white);
                            return;
                          }
                          await controller.addVendor(
                            VendorEntity(name: name, phone: phone, description: descC.text.trim().isEmpty ? null : descC.text.trim()),
                            categoryName: categoryC.text.trim(),
                          );
                          nameC.clear();
                          phoneC.clear();
                          descC.clear();
                          categoryC.clear();
                          setState(() {});
                        },
                        child: const Text("Add & Continue"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
