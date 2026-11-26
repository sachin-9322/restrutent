import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/model/entity_bill.dart';
import 'package:splash_screen_03/model/payment_method.dart';
// TODO: adjust this import to where your ControllerOrder is defined.
import 'package:splash_screen_03/screens/home/fragments/order/controller_order.dart';
import 'package:splash_screen_03/screens/home/fragments/table_order/widget/glass_card.dart';

// DTO for returning result to the caller (kept same)
class PaymentResult {
  final bool settled; // always true for now (dialog is for settle)
  final bool print; // whether user chose Print & Settle
  final List<PaymentEntry> payments;
  final double tipAmount;
  final String tipPaymentMode; // Cash, Card, UPI...
  final String? referenceNo; // overall reference (optional)
  final double dueAmount; // > 0 means partial/due

  PaymentResult({
    required this.settled,
    required this.print,
    required this.payments,
    required this.tipAmount,
    required this.tipPaymentMode,
    required this.referenceNo,
    required this.dueAmount,
  });
}

class PaymentEntry {
  String mode; // Cash, Card, UPI, ...
  double amount; // amount paid
  String? reference; // optional UTR/ref

  PaymentEntry({required this.mode, required this.amount, this.reference});
}

class PaymentDialog extends StatefulWidget {
  final EntityOrder bill;

  const PaymentDialog({super.key, required this.bill});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  // Controller to settle bill
  final ControllerOrder _order = Get.find<ControllerOrder>();
  final RxBool _returnToCustomer = false.obs;

  // UI/state
  final RxString _selectedPayment = 'Cash'.obs;
  final RxBool _splitPayment = false.obs;
  final RxBool _addAsDue = false.obs;
  bool _saving = false;

  // Fields
  final TextEditingController _referenceNoCtrl = TextEditingController();
  final TextEditingController _tipCtrl = TextEditingController();
  final RxString _tipPaymentMode = 'Cash'.obs;

  // Single-payment partial (only visible when Add as Due is ON and Split is OFF)
  final TextEditingController _singlePaidNowCtrl = TextEditingController();

  // Split rows
  final RxList<PaymentEntry> _splits = <PaymentEntry>[].obs;

  // Controllers per split row (so typing doesn’t reset on rebuild)
  final List<TextEditingController> _splitAmtCtrls = [];
  final List<TextEditingController> _splitRefCtrls = [];

  // Payment mode options
  List<String> get paymentModes =>
      PaymentMethod.values.map((e) => e.label).toList();

  double get billTotal => (widget.bill.totalAmount ?? 0).toDouble();

  double get tip {
    final t = double.tryParse(_tipCtrl.text.trim());
    return (t == null || t.isNaN) ? 0.0 : t;
    // Alternatively: return double.tryParse(_tipCtrl.text.trim()) ?? 0.0;
  }

  double get netPayable => billTotal + tip;

  double get paidNow {
    if (_splitPayment.value) {
      final sum = _splits.fold<double>(0.0, (acc, e) => acc + e.amount);
      return sum;
    } else {
      if (_addAsDue.value) {
        final p = double.tryParse(_singlePaidNowCtrl.text.trim());
        return (p == null || p.isNaN) ? 0.0 : p;
      } else {
        // Paying everything in a single mode
        return netPayable;
      }
    }
  }

  double get dueAmount {
    final d = netPayable - paidNow;
    return d > 0 ? d : 0.0;
  }

  double get changeToReturn {
    final ch = paidNow - netPayable;
    return ch > 0 ? ch : 0.0;
  }

  @override
  void initState() {
    super.initState();
    // Default to last saved payment mode if any, else Cash
    try {
      if (widget.bill.payments.isNotEmpty) {
        _selectedPayment.value = widget.bill.payments.last.mode;
      } else {
        _selectedPayment.value = 'Cash';
      }
    } catch (_) {
      _selectedPayment.value = 'Cash';
    }
    _tipPaymentMode.value = 'Cash';
  }

  @override
  void dispose() {
    _referenceNoCtrl.dispose();
    _tipCtrl.dispose();
    _singlePaidNowCtrl.dispose();
    for (final c in _splitAmtCtrls) c.dispose();
    for (final c in _splitRefCtrls) c.dispose();
    super.dispose();
  }

  void _addSplitRow() {
    _splits.add(PaymentEntry(mode: 'Cash', amount: 0.0));
    _splitAmtCtrls.add(TextEditingController());
    _splitRefCtrls.add(TextEditingController());
  }

  void _removeSplitRow(int index) {
    if (index >= 0 && index < _splits.length) {
      _splits.removeAt(index);
      final amt = _splitAmtCtrls.removeAt(index);
      final ref = _splitRefCtrls.removeAt(index);
      amt.dispose();
      ref.dispose();
    }
  }

  void _updateSplitAmount(int index, String value) {
    if (index < 0 || index >= _splits.length) return;
    final v = double.tryParse(value.trim()) ?? 0.0;
    _splits[index] = PaymentEntry(
      mode: _splits[index].mode,
      amount: v < 0 ? 0.0 : v,
      reference: _splits[index].reference,
    );
  }

  void _updateSplitMode(int index, String mode) {
    if (index < 0 || index >= _splits.length) return;
    _splits[index] = PaymentEntry(
      mode: mode,
      amount: _splits[index].amount,
      reference: _splits[index].reference,
    );
  }

  void _updateSplitRef(int index, String value) {
    if (index < 0 || index >= _splits.length) return;
    _splits[index] = PaymentEntry(
      mode: _splits[index].mode,
      amount: _splits[index].amount,
      reference: value.trim().isEmpty ? null : value.trim(),
    );
  }

  bool _validate(bool forPrint) {
    // ✅ Check if customer details are present when marking as due
    if (_addAsDue.value) {
      // ✅ FIX: Check controller's reactive variables, not bill object
      // Bill object is not updated until eBill is called
      final customerName = _order.rxCustomerName.value.trim().isEmpty
          ? (widget.bill.customerName ?? '').trim()
          : _order.rxCustomerName.value.trim();
      final customerPhone = _order.rxCustomerMobile.value.trim().isEmpty
          ? (widget.bill.customerMobile ?? '').trim()
          : _order.rxCustomerMobile.value.trim();

      if (customerName.isEmpty || customerPhone.isEmpty) {
        Get.snackbar(
          'Customer Required',
          'Please add customer details before marking as due payment',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade700,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return false;
      }
    }

    if (_splitPayment.value) {
      if (_splits.isEmpty) {
        Get.snackbar(
          'Payment',
          'Add at least one split entry',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
      for (final e in _splits) {
        if (e.amount <= 0) {
          Get.snackbar(
            'Payment',
            'Split amounts must be greater than 0',
            snackPosition: SnackPosition.BOTTOM,
          );
          return false;
        }
      }
      if (_addAsDue.value) {
        if (paidNow < 0) {
          Get.snackbar(
            'Payment',
            'Invalid paid amount',
            snackPosition: SnackPosition.BOTTOM,
          );
          return false;
        }
      }
    } else {
      if (_addAsDue.value) {
        if (paidNow < 0) {
          Get.snackbar(
            'Payment',
            'Invalid partial amount',
            snackPosition: SnackPosition.BOTTOM,
          );
          return false;
        }
      } else {
        if (paidNow <= 0) {
          Get.snackbar(
            'Payment',
            'Paid amount must be greater than 0',
            snackPosition: SnackPosition.BOTTOM,
          );
          return false;
        }
      }
    }
    // ✅ Require confirmation if extra money paid
    if (changeToReturn > 0.009) {
      if (!_returnToCustomer.value) {
        Get.snackbar(
          'Return Confirmation Required',
          'You must confirm that ₹${changeToReturn.toStringAsFixed(2)} was returned to the customer before settling.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade700,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return false;
      }
    }

    return true;
  }

  PaymentResult _buildResult(bool print) {
    final String? referenceNo = _referenceNoCtrl.text.trim().isEmpty
        ? null
        : _referenceNoCtrl.text.trim();

    final List<PaymentEntry> payments = [];
    if (_splitPayment.value) {
      payments.addAll(_splits);
    } else {
      // single payment
      final double amt = _addAsDue.value ? paidNow : netPayable;
      if (amt > 0) {
        payments.add(
          PaymentEntry(
            mode: _selectedPayment.value,
            amount: amt,
            reference: referenceNo,
          ),
        );
      }
    }

    return PaymentResult(
      settled: true,
      print: print,
      payments: payments,
      tipAmount: tip,
      tipPaymentMode: _tipPaymentMode.value,
      referenceNo: referenceNo,
      dueAmount: dueAmount,
    );
  }

  String _overallPaymentMode() {
    if (_splitPayment.value) {
      final modes = _splits
          .map((e) => e.mode.trim())
          .where((m) => m.isNotEmpty)
          .toSet()
          .toList();
      if (modes.isEmpty) return 'Mixed';
      if (modes.length == 1) return modes.first;
      final joined = modes.take(3).join('+'); // e.g., Cash+UPI+Card
      return modes.length > 3 ? '$joined+...' : joined;
    }
    return _selectedPayment.value;
  }
  // In file: dialogs/payment_dialog.dart (or wherever PaymentDialog is)
  // In class: _PaymentDialogState
  // In file: dialogs/payment_dialog.dart (or wherever PaymentDialog is)
  // In class: _PaymentDialogState

  // ✅ REPLACE THE OLD _onSaveAndSettle FUNCTION WITH THIS ONE

  Future<void> _onSaveAndSettle({required bool print}) async {
    // Optional: prevent double taps
    if (_saving) return;

    if (!_validate(print)) return;

    if (mounted) setState(() => _saving = true);

    try {
      // Build payment summary from your UI
      final PaymentResult result = _buildResult(print);

      // Save & settle
      await _order.eBill(
        null, // table is resolved inside eBill
        _overallPaymentMode(), // overall payment mode
        payments: result.payments,
        tipAmount: result.tipAmount,
        tipPaymentMode: result.tipPaymentMode,
        referenceNo: result.referenceNo,
        dueAmount: result.dueAmount, // if > 0, it's a DUE
        customerName: _order.rxCustomerName.value,
        customerMobile: _order.rxCustomerMobile.value,
        customerAddress: _order.rxCustomerAddress.value,
        printAfterSettle: print,
        includeLocalCart: true,
      );

      // Feedback
      final msg = result.dueAmount > 0
          ? "Bill marked as DUE"
          : "Bill Settled Successfully";
      Get.snackbar(
        "Success",
        msg,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      // Close any open dialog/sheet to avoid context issues
      if (Get.isDialogOpen == true) {
        Get.back(); // close dialog
      }
      if (Get.isBottomSheetOpen == true) {
        Get.back(); // close bottom sheet
      }

      // Navigate to Home and clear the navigation stack
      Get.offAllNamed('/home');
    } catch (e) {
      Get.snackbar(
        'Settle Failed',
        'An error occurred: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.6,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Obx(() {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '🧾 Settle Bill',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 22),
                      tooltip: 'Close',
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(color: cs.outline.withOpacity(0.3)),
                const SizedBox(height: 12),

                // Payment mode shortcuts (single mode)
                if (!_splitPayment.value) ...[
                  _sectionHeader('Payment Mode'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ...PaymentMethod.values.map((m) => _paymentButton(m)),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Controls – Wrap so it never overflows
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      child: CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        value: _splitPayment.value,
                        onChanged: _saving
                            ? null
                            : (v) {
                                _splitPayment.value = v ?? false;
                                if (_splitPayment.value && _splits.isEmpty) {
                                  _addSplitRow();
                                }
                              },
                        title: const Text('Split Payment'),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        value: _addAsDue.value,
                        onChanged: _saving
                            ? null
                            : (v) => _addAsDue.value = v ?? false,
                        title: const Text('Add as due payment'),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                    SizedBox(
                      width: 280,
                      child: TextField(
                        controller: _referenceNoCtrl,
                        readOnly: _saving,
                        decoration: const InputDecoration(
                          labelText: 'Payment Reference No',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: TextField(
                        controller: _tipCtrl,
                        readOnly: _saving,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}$'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Tip Amount',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: DropdownButtonFormField<String>(
                        value: _tipPaymentMode.value,
                        items: paymentModes
                            .map(
                              (m) => DropdownMenuItem(value: m, child: Text(m)),
                            )
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (v) => _tipPaymentMode.value = v ?? 'Cash',
                        decoration: const InputDecoration(
                          labelText: 'Tip Payment',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Divider(color: cs.outline.withOpacity(0.3)),
                const SizedBox(height: 12),

                // Split table or single due input
                if (_splitPayment.value) ...[
                  _sectionHeader('Split Details'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: cs.outline.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _splitHeaderRow(context),
                        const SizedBox(height: 8),
                        ...List.generate(
                          _splits.length,
                          (i) => _splitRow(context, i),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _saving ? null : _addSplitRow,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Payment Line'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else if (_addAsDue.value) ...[
                  _sectionHeader('Partial Payment'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                        width: 140,
                        child: TextField(
                          controller: _singlePaidNowCtrl,
                          readOnly: _saving,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}$'),
                            ),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Paid Now (${_selectedPayment.value})',
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                          onEditingComplete: () {
                            final v = double.tryParse(_singlePaidNowCtrl.text);
                            if (v != null) {
                              _singlePaidNowCtrl.text = v.toStringAsFixed(2);
                              _singlePaidNowCtrl.selection =
                                  TextSelection.fromPosition(
                                    TextPosition(
                                      offset: _singlePaidNowCtrl.text.length,
                                    ),
                                  );
                            }
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Mode: ${_selectedPayment.value}',
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                Obx(() {
                  final extra = changeToReturn;
                  if (extra <= 0.009) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader('Return to Customer'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: cs.outline.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: _returnToCustomer.value
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.08),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Customer paid ₹${paidNow.toStringAsFixed(2)} for a bill of ₹${netPayable.toStringAsFixed(2)}.\n'
                                'Return ₹${extra.toStringAsFixed(2)} to customer.',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Colors.orange.shade900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      value: _returnToCustomer.value,
                                      onChanged: _saving
                                          ? null
                                          : (v) => _returnToCustomer.value =
                                                v ?? false,
                                    ),
                                    Text(
                                      'Returned ₹${extra.toStringAsFixed(2)}',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: Colors.orange.shade900,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }),

                // Summary block
                _sectionHeader('Summary'),
                const SizedBox(height: 8),
                _summaryTile(
                  context,
                  entries: [
                    MapEntry('Grand Total', billTotal),
                    MapEntry('Tip', tip),
                    MapEntry('Payable', netPayable),
                    MapEntry('Paid', paidNow),
                    MapEntry('Due', dueAmount),
                    MapEntry('Return to Customer', changeToReturn),
                  ],
                ),

                const Spacer(),

                // Bottom buttons – Wrap to avoid overflow
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Close'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _saving
                          ? null
                          : () => _onSaveAndSettle(print: true),
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.print, size: 18),
                      label: const Text('Print & Settle Bill'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _saving
                          ? null
                          : () => _onSaveAndSettle(print: false),
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Save & Settle Bill'),
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // UI helpers
  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _paymentButton(PaymentMethod method) {
    return Obx(() {
      final isSelected = _selectedPayment.value == method.label;
      return GestureDetector(
        onTap: _saving ? null : () => _selectedPayment.value = method.label,
        child: Container(
          width: 140,
          height: 50,
          decoration: isSelected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: method.color, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: method.color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                )
              : null,
          child: GlasssCard(
            borderRadius: 16,
            padding: EdgeInsets.zero,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    Icon(Icons.check_circle, size: 16, color: method.color),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    method.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isSelected
                          ? method.color
                          : Theme.of(Get.context!).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _splitHeaderRow(BuildContext context) {
    return Row(
      children: const [
        Expanded(flex: 3, child: Text('Payment Mode')),
        Expanded(flex: 3, child: Text('Amount')),
        Expanded(flex: 4, child: Text('Reference (optional)')),
        SizedBox(width: 40),
      ],
    );
  }

  Widget _splitRow(BuildContext context, int index) {
    final entry = _splits[index];

    // Ensure controllers exist for this row
    final amountCtrl = _splitAmtCtrls[index];
    final refCtrl = _splitRefCtrls[index];

    // Only prefill once (don’t override user typing on rebuild)
    if (amountCtrl.text.isEmpty && entry.amount > 0) {
      amountCtrl.text = entry.amount.toStringAsFixed(2);
    }
    if (refCtrl.text.isEmpty && (entry.reference ?? '').isNotEmpty) {
      refCtrl.text = entry.reference!;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Mode
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              isDense: true,
              value: entry.mode,
              items: paymentModes
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: _saving
                  ? null
                  : (v) => _updateSplitMode(index, v ?? 'Cash'),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Amount
          Expanded(
            flex: 3,
            child: TextField(
              controller: amountCtrl,
              readOnly: _saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
              ],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                prefixText: '₹ ',
              ),
              onChanged: (v) => _updateSplitAmount(index, v),
              onEditingComplete: () {
                final v = double.tryParse(amountCtrl.text);
                if (v == null) {
                  amountCtrl.clear();
                  _updateSplitAmount(index, '0');
                } else {
                  amountCtrl.text = v.toStringAsFixed(2);
                  amountCtrl.selection = TextSelection.fromPosition(
                    TextPosition(offset: amountCtrl.text.length),
                  );
                  _updateSplitAmount(index, amountCtrl.text);
                }
                setState(() {});
              },
            ),
          ),

          const SizedBox(width: 8),

          // Ref
          Expanded(
            flex: 4,
            child: TextField(
              controller: refCtrl,
              readOnly: _saving,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                hintText: 'Optional',
              ),
              onChanged: (v) => _updateSplitRef(index, v),
            ),
          ),
          const SizedBox(width: 8),

          // Delete
          SizedBox(
            width: 40,
            child: IconButton(
              tooltip: 'Remove',
              onPressed: _saving ? null : () => _removeSplitRow(index),
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(
    BuildContext context, {
    required List<MapEntry<String, double>> entries,
  }) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.primary.withOpacity(0.15)),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: entries.map((pair) {
          final label = pair.key;
          final value = pair.value;
          final isBold =
              label == 'Grand Total' || label == 'Payable' || label == 'Paid';
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$label: ',
                style: t.titleSmall?.copyWith(
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              Text(
                '₹${value.toStringAsFixed(2)}',
                style: t.titleSmall?.copyWith(
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
