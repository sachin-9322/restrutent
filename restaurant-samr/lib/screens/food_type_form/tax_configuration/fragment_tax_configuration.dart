import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/model/entity_cateogry_tax.dart';
import 'package:splash_screen_03/model/entity_food.dart';
import 'package:splash_screen_03/model/entity_tax.dart';
import './controller_tax_configuration.dart';

class FragmentTaxConfiguration extends StatelessWidget {
  const FragmentTaxConfiguration({super.key});

  void _showTaxConfigurationBottomSheet(
    BuildContext context,
    ControllerTaxConfiguration controller,
  ) {
    final ThemeData theme = Theme.of(context);

    if (controller.currentFoodForTaxConfig == null) {
      Get.snackbar("Error", "No food item selected for tax configuration.");
      return;
    }
    // Prepare for the specific food item.
    controller.prepareForTaxConfiguration(controller.currentFoodForTaxConfig!);

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 30,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Configure Tax for: ${controller.currentFoodForTaxConfig?.foodName ?? "Food Item"}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Obx(
                () => DropdownButtonFormField<String?>(
                  decoration: InputDecoration(
                    labelText: "Select Tax",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.receipt_long_outlined),
                  ),
                  hint: const Text("Choose a tax configuration"),
                  value: controller.selectedTaxUuidInBottomSheet.value,
                  items: controller.rxAvailableTaxes.map((EntityTax tax) {
                    return DropdownMenuItem<String?>(
                      value: tax.taxUuid,
                      child: Text(
                        "${tax.taxProductName ?? 'Unnamed Tax'} (${tax.taxPercentage?.toStringAsFixed(1) ?? 'N/A'}%)",
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    controller.selectedTaxUuidInBottomSheet.value = newValue;
                  },
                ),
              ),
              const SizedBox(height: 16),
              Obx(
                () => TextFormField(
                  initialValue: controller.bottomSheetTaxGroupDisplay.value,
                  key: Key(controller.bottomSheetTaxGroupDisplay.value),
                  decoration: InputDecoration(
                    labelText: "Tax Product Group",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.group_work_outlined),
                  ),
                  readOnly: true,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => TextFormField(
                        initialValue:
                            controller.bottomSheetTaxTypeDisplay.value,
                        key: Key(controller.bottomSheetTaxTypeDisplay.value),
                        decoration: InputDecoration(
                          labelText: "Tax Type",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.merge_type_outlined),
                        ),
                        readOnly: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(
                      () => TextFormField(
                        initialValue:
                            controller.bottomSheetTaxPercentageDisplay.value,
                        key: Key(
                          controller.bottomSheetTaxPercentageDisplay.value,
                        ),
                        decoration: InputDecoration(
                          labelText: "Tax Percentage",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.percent_outlined),
                        ),
                        readOnly: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                child: const Text("Apply Tax"), // Changed from "Done"
                onPressed: () {
                  controller.applyTaxSelectionToFood(); // Apply the change
                  Get.back(); // Close the bottom sheet
                },
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      enableDrag: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ControllerTaxConfiguration controller = Get.put(
      ControllerTaxConfiguration(),
    );
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Food Tax Configuration (All Items)",
        ), // Clarified title
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCategoryFilterDropdown(controller, theme),
            const SizedBox(height: 20),
            Expanded(
              child: Obx(() {
                if (!controller.initialized) {
                  // Check if controller is initialized
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.rxDisplayFoodList.isEmpty) {
                  return _buildEmptyFoodListPlaceholder(theme, controller);
                }
                return _buildFoodItemsDataTable(controller, theme, context);
              }),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.refreshAllData();
        },
        tooltip: 'Refresh Data',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildCategoryFilterDropdown(
    ControllerTaxConfiguration controller,
    ThemeData theme,
  ) {
    return Obx(() {
      if (!controller.initialized && controller.rxDisplayCategoryList.isEmpty) {
        return const Center(child: Text("Initializing categories..."));
      }
      return DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: "Filter by Category",
          hintText: "Select a category to filter",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          prefixIcon: Icon(
            Icons.filter_list_alt,
            color: theme.colorScheme.primary,
          ),
        ),
        value: controller.selectedCategoryId.value,
        items: controller.rxDisplayCategoryList.map((
          EntityCategoryTax category,
        ) {
          String valueToUse =
              category.categoryName ==
                  ControllerTaxConfiguration.ALL_CATEGORIES_NAME
              ? ControllerTaxConfiguration.ALL_CATEGORIES_ID
              : category.categoryName ?? "";
          return DropdownMenuItem<String>(
            value: valueToUse,
            child: Text(category.categoryName ?? "Unnamed Category"),
          );
        }).toList(),
        onChanged: (String? newValue) {
          controller.selectCategory(newValue);
        },
        isExpanded: true,
      );
    });
  }

  Widget _buildEmptyFoodListPlaceholder(
    ThemeData theme,
    ControllerTaxConfiguration controller,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fastfood_outlined, size: 60, color: theme.disabledColor),
          const SizedBox(height: 12),
          Text(
            controller.rxMasterCategoryList.isEmpty
                ? "No categories or food items available."
                : "No food items found for the selected category.",
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.disabledColor,
            ),
            textAlign: TextAlign.center,
          ),
          if (controller.rxMasterCategoryList.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "Please add categories and food items first via their respective management screens.",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.disabledColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFoodItemsDataTable(
    ControllerTaxConfiguration controller,
    ThemeData theme,
    BuildContext context,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateColor.resolveWith(
            (states) => theme.colorScheme.secondaryContainer.withAlpha(
              75,
            ), // Adjusted opacity
          ),
          columnSpacing: 18.0,
          columns: const [
            DataColumn(label: Text('Food Name')),
            DataColumn(label: Text('Category')),
            DataColumn(label: Text('Current Tax Group')),
            DataColumn(label: Text('Tax %')),
            DataColumn(label: Text('Included in Rate')),
            // DataColumn(label: Text('Taxable')), // This seems redundant if we show tax details
            // DataColumn(label: Text('Final Rate')), // Calculation might be complex here
            DataColumn(label: Text('Actions')),
          ],
          rows: controller.rxDisplayFoodList.map((EntityFood food) {
            final assignedTax = food.tax.target;
            String taxGroupName = assignedTax?.taxProductName ?? "N/A";
            String taxPercentage =
                assignedTax?.taxPercentage?.toStringAsFixed(1) ?? "N/A";
            String taxIncluded = (assignedTax?.isIncludeInRate ?? false)
                ? "Yes"
                : "No";

            return DataRow(
              cells: [
                DataCell(Text(food.foodName ?? 'N/A')),
                DataCell(Text(food.categoryName ?? 'N/A')),
                DataCell(Text(taxGroupName)),
                DataCell(Text(taxPercentage)),
                DataCell(Text(taxIncluded)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        tooltip: 'Configure Tax',
                        onPressed: () {
                          controller.currentFoodForTaxConfig =
                              food; // Set the food item to be configured
                          _showTaxConfigurationBottomSheet(context, controller);
                        },
                      ),
                      if (assignedTax != null)
                        IconButton(
                          icon: Icon(
                            Icons.clear_outlined,
                            color: theme.colorScheme.error,
                            size: 20,
                          ),
                          tooltip: 'Clear Tax',
                          onPressed: () {
                            controller.clearTaxForFood(food);
                          },
                        ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
