import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/model/entity_tax.dart';
import 'package:splash_screen_03/utils/app_routes.dart';

import 'controller_tax_product.dart';

class FragmentTaxProduct extends StatelessWidget {
  const FragmentTaxProduct({super.key});

  // A common breakpoint for switching between mobile and tablet/desktop layouts.
  static const double _wideScreenBreakpoint = 600.0;

  @override
  Widget build(BuildContext context) {
    // Using Get.lazyPut is often better in StatelessWidget to avoid recreating the controller.
    // Use Get.put if you need it immediately and want to ensure it's the first time.
    final ControllerProductTax controller = Get.put(ControllerProductTax());
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Tax Group"),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "Tax Groups",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                if (controller.rxTaxList.isEmpty) {
                  return _buildEmptyState(theme);
                }
                // Use LayoutBuilder to create a responsive UI
                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > _wideScreenBreakpoint) {
                      // WIDE SCREEN: Show the DataTable
                      return _buildWideLayout(controller, theme);
                    } else {
                      // NARROW SCREEN: Show a mobile-friendly ListView
                      return _buildNarrowLayout(controller, theme, context);
                    }
                  },
                );
              }),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.toNamed(AppRoutes.taxTypeForm);
        },
        tooltip: 'Add New Tax',
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Widget for the empty state (no tax groups)
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: theme.disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            "No Tax Configurations Found",
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Click the '+' button to add a new tax configuration.",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.disabledColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // WIDE LAYOUT for tablets/desktop using DataTable
  Widget _buildWideLayout(ControllerProductTax controller, ThemeData theme) {
    return Container(

      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12.0),
      ),
      clipBehavior: Clip.antiAlias, // Ensures content respects the border radius
      child: SingleChildScrollView(
        // We only need vertical scroll here
        child: DataTable(
          headingRowColor: WidgetStateColor.resolveWith(
            (states) => theme.colorScheme.secondaryContainer.withOpacity(0.3),
          ),
          showCheckboxColumn: false, // Hide the default checkbox column
          columnSpacing: 20.0,
          columns: const [
            DataColumn(label: Text('Tax Group Name')),
            DataColumn(label: Text('Percentage (%)')),
            DataColumn(label: Text('SGST/CGST')),
            DataColumn(label: Text('Active')),
            DataColumn(label: Text('Included Rate')),
            DataColumn(label: Text('Hide Detail')),
            DataColumn(label: Text('Actions')),
          ],
          rows: controller.rxTaxList.map((tax) {
            return DataRow(
              cells: [
                DataCell(Text(tax.taxProductName ?? 'N/A')),
                DataCell(
                    Text(tax.taxPercentage?.toStringAsFixed(2) ?? 'N/A')),
                DataCell(_buildStatusIcon(tax.isSgstCgst ?? false)),
                DataCell(_buildStatusIcon(tax.isActive ?? false)),
                DataCell(_buildStatusIcon(tax.isIncludeInRate ?? false)),
                DataCell(_buildVisibilityIcon(tax.isHideTaxDetail ?? false)),
                DataCell(_buildActionButtons(Get.context!, controller, tax, theme)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // NARROW LAYOUT for mobile phones using ListView and Cards
  Widget _buildNarrowLayout(ControllerProductTax controller, ThemeData theme, BuildContext context) {
    return ListView.builder(
      itemCount: controller.rxTaxList.length,
      itemBuilder: (context, index) {
        final tax = controller.rxTaxList[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with Title and Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        tax.taxProductName ?? 'N/A',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildActionButtons(context, controller, tax, theme, useSmallIcons: true),
                  ],
                ),
                const Divider(height: 20),
                // Details
                _buildDetailRow(
                  'Percentage:',
                  '${tax.taxPercentage?.toStringAsFixed(2) ?? 'N/A'}%',
                  theme,
                ),
                _buildDetailRow('Active:', _buildStatusIcon(tax.isActive ?? false), theme),
                _buildDetailRow('SGST/CGST:', _buildStatusIcon(tax.isSgstCgst ?? false), theme),
                _buildDetailRow('Included in Rate:', _buildStatusIcon(tax.isIncludeInRate ?? false), theme),
                _buildDetailRow('Hide Tax Detail:', _buildVisibilityIcon(tax.isHideTaxDetail ?? false), theme),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper to build a detail row for the narrow layout
  Widget _buildDetailRow(String label, dynamic value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          if (value is String)
            Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))
          else if (value is Widget)
            value,
        ],
      ),
    );
  }

  // Helper widget for boolean status icons (Check/Cancel)
  Widget _buildStatusIcon(bool isActive) {
    return Icon(
      isActive ? Icons.check_circle : Icons.cancel,
      color: isActive ? Colors.green : Colors.red,
      size: 20,
    );
  }

  // Helper widget for visibility icon
  Widget _buildVisibilityIcon(bool isHidden) {
    return Icon(
      isHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      color: isHidden ? Colors.grey : Colors.blue,
      size: 20,
    );
  }
  
  // Helper for action buttons, reusable for both layouts
  Widget _buildActionButtons(
      BuildContext context, ControllerProductTax controller, EntityTax tax, ThemeData theme, {bool useSmallIcons = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.edit_outlined, color: theme.colorScheme.primary),
          iconSize: useSmallIcons ? 22 : 20,
          padding: useSmallIcons ? EdgeInsets.zero : const EdgeInsets.all(8.0),
          constraints: useSmallIcons ? const BoxConstraints() : null,
          tooltip: 'Edit Tax',
          onPressed: () {
            Get.toNamed(AppRoutes.taxTypeForm, arguments: tax);
          },
        ),
        if (useSmallIcons) const SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
          iconSize: useSmallIcons ? 22 : 20,
          padding: useSmallIcons ? EdgeInsets.zero : const EdgeInsets.all(8.0),
          constraints: useSmallIcons ? const BoxConstraints() : null,
          tooltip: 'Delete Tax',
          onPressed: () {
            _showDeleteConfirmationDialog(context, controller, tax, theme);
          },
        ),
      ],
    );
  }

  // The confirmation dialog remains the same
  void _showDeleteConfirmationDialog(
    BuildContext context,
    ControllerProductTax controller,
    EntityTax tax,
    ThemeData theme,
  ) {
    Get.defaultDialog(
      title: "Confirm Delete",
      titleStyle: TextStyle(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      middleText:
          "Are you sure you want to delete '${tax.taxProductName ?? 'this tax'}'?.",
      middleTextStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      backgroundColor: theme.colorScheme.surface,
      radius: 12.0,
      actions: [
        TextButton(
          child: Text(
            "Cancel",
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          onPressed: () => Get.back(),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: const Text("Delete"),
          onPressed: () {
            controller.removeTaxType(controller.rxTaxList.indexOf(tax));
            Get.back(); // Close the dialog first
            Get.snackbar(
              "Success",
              "'${tax.taxProductName ?? 'Tax'}' deleted successfully.",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
              margin: const EdgeInsets.all(10),
            );
          },
        ),
      ],
    );
  }
}