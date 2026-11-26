// activity_food_form.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
// import 'package:path/path.dart'; // <<< THIS LINE IS REMOVED
import 'package:splash_screen_03/model/entity_food.dart';
import 'package:splash_screen_03/model/entity_price.dart';
import 'package:splash_screen_03/model/entity_tax.dart';
import 'package:splash_screen_03/screens/food_type_form/controller_food_form.dart';
import 'package:splash_screen_03/screens/food_type_form/tax_configuration/controller_tax_configuration.dart';
import 'package:splash_screen_03/screens/home/fragments/menu/controller_menu.dart';

class ActivityFoodForm extends StatelessWidget {
  const ActivityFoodForm({super.key});

  final List<String> meatType = const [
    "Chicken",
    "Beef (Cow/Bull meat)",
    "Mutton (Goat meat)",
    "Camel Meat",
    "Pork (Pig meat)",
    "Lamb (Sheep meat)",
    "Fish",
    "Duck",
    "Crab",
    "Turkey",
  ];

  Widget _buildTaxDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required ThemeData theme,
    String? label,
    Widget? prefix,
    String? hint,
    bool dense = true,
    EdgeInsetsGeometry? contentPadding,
  }) {
    final baseRadius = BorderRadius.circular(12);
    final enabledBorder = OutlineInputBorder(
      borderRadius: baseRadius,
      borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.18), width: 1.2),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: baseRadius,
      borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.8),
    );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefix,
      isDense: dense,
      filled: true,
      fillColor: theme.cardColor,
      contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      hintStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
      enabledBorder: enabledBorder,
      disabledBorder: enabledBorder,
      focusedBorder: focusedBorder,
      errorBorder: OutlineInputBorder(
        borderRadius: baseRadius,
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1.6),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: baseRadius,
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1.8),
      ),
      // --- FIX: Prevents layout shift on validation error ---
      // This reserves space for the error message, so the field doesn't change height.
      helperText: ' ',
      helperStyle: const TextStyle(height: 0.5, fontSize: 0, color: Colors.transparent),
      errorStyle: TextStyle(height: 0.9, color: theme.colorScheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Never recreate controllers on rebuild
    final ControllerFoodForm foodFormController =
        Get.isRegistered<ControllerFoodForm>() ? Get.find<ControllerFoodForm>() : Get.put(ControllerFoodForm());
    final ControllerTaxConfiguration taxConfigController =
        Get.isRegistered<ControllerTaxConfiguration>() ? Get.find<ControllerTaxConfiguration>() : Get.put(ControllerTaxConfiguration());
    final ControllerMenu menuController =
        Get.isRegistered<ControllerMenu>() ? Get.find<ControllerMenu>() : Get.put(ControllerMenu());

    final theme = Theme.of(context);
    final isNew = foodFormController.editingFood == null;

    // Responsive widths
    final maxWidth = MediaQuery.of(context).size.width;
    final leftFlex = (maxWidth > 1200) ? 0.62 : (maxWidth > 900 ? 0.66 : 1.0);
    final rightFlex = 1 - leftFlex;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          isNew ? 'Create food item'.tr : 'Edit food item'.tr,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Form(
          key: foodFormController.formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final saveBtn = ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.teal,
                ),
                icon: Icon(isNew ? Icons.save_outlined : Icons.check_circle_outline),
                label: Text(isNew ? 'SAVE'.tr : 'Update food item'.tr, style: TextStyle(color: Colors.white),),
                onPressed: (){
                  foodFormController.saveFoodDetails(context);
                }
              );

              if (isWide) {
                // WIDE LAYOUT: Two scrollable columns, with the save button pinned to the bottom of the right column.
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Pane (Scrollable Form Fields)
                    Expanded(
                      flex: (leftFlex * 1000).toInt(),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: _foodInfoCard(theme, foodFormController, menuController, context),
                      ),
                    ),
                    const SizedBox(width: 18),
                    // Right Pane (Tax, Pricing, and Save Button)
                    Expanded(
                      flex: (rightFlex * 1000).toInt(),
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildCurrentFoodTaxInfoCard(context, foodFormController, taxConfigController),
                                  const SizedBox(height: 18),
                                  _pricingCard(theme, foodFormController),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Pinned Save Button at the bottom of the right pane
                          SizedBox(
                            width: double.infinity,
                            child: saveBtn,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              // NARROW LAYOUT: All cards in a single scrollable column with the save button at the end.
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _foodInfoCard(theme, foodFormController, menuController, context),
                    const SizedBox(height: 12),
                    _buildCurrentFoodTaxInfoCard(context, foodFormController, taxConfigController),
                    const SizedBox(height: 12),
                    _pricingCard(theme, foodFormController),
                    const SizedBox(height: 18),
                    saveBtn,
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _foodInfoCard(ThemeData theme, ControllerFoodForm controller, ControllerMenu menuController, BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('food information'.tr, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 18),

            // Food name + Short code
            Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Align to top to prevent vertical shift
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller.textEditingControllerFoodName,
                    decoration: _inputDecoration(
                      theme: theme,
                      label: '${'food name'.tr} *',
                      prefix: const Icon(Icons.fastfood_outlined),
                      hint: 'e.g. Margherita Pizza',
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'enter food name'.tr : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: controller.textEditingControllerFoodShortCode,
                    decoration: _inputDecoration(
                      theme: theme,
                      label: '${'short code'.tr} *',
                      prefix: const Icon(Icons.code_outlined),
                      hint: 'e.g. PZ001',
                    ),
                    maxLength: 16,
                    buildCounter: (_, {required currentLength, maxLength, required isFocused}) => const SizedBox.shrink(),
                    textInputAction: TextInputAction.next,
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'enter short code'.tr : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Category + Prep time
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Obx(
                    () => DropdownButtonFormField<int>(
                      decoration: _inputDecoration(
                        theme: theme,
                        label: '${'category'.tr} *',
                        prefix: const Icon(Icons.category_outlined),
                      ),
                      value: controller.selectedCategoryId.value == 0 ? null : controller.selectedCategoryId.value,
                      hint: Text('select category'.tr),
                      isExpanded: true,
                      items: controller.rxCategoryList
                          .map(
                            (categoryType) => DropdownMenuItem(
                              value: categoryType.id,
                              child: Text(categoryType.categoryName ?? 'Unnamed Category'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        controller.selectedCategoryId.value = value ?? 0;
                        if (value != null && value != 0) {
                          final selectedCategory = controller.rxCategoryList.firstWhereOrNull((c) => c.id == value);
                          controller.textEditingControllerFoodCategory.text = selectedCategory?.categoryName ?? "";
                        } else {
                          controller.textEditingControllerFoodCategory.text = "";
                        }
                      },
                      validator: (val) => (val == null || val == 0) ? 'select category error'.tr : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: controller.textEditingControllerPrepTime,
                    decoration: _inputDecoration(
                      theme: theme,
                      label: 'prep time minutes'.tr,
                      prefix: const Icon(Icons.timer_outlined),
                      hint: 'e.g. 10',
                    ),
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Stock + Kitchen dept
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller.textEditingControllerStock,
                    decoration: _inputDecoration(
                      theme: theme,
                      label: "Enter the Stock",
                      prefix: const Icon(Icons.inventory_outlined),
                      hint: 'e.g. 20',
                    ),
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: controller.textEditingControllerKitchenDepName,
                    decoration: _inputDecoration(
                      theme: theme,
                      label: "Enter the Kitchen Dep Name",
                      prefix: const Icon(Icons.kitchen_outlined),
                      hint: 'e.g. Main Kitchen',
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Windows-only image section
            Text('Image (Windows only)'.tr, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (GetPlatform.isWindows)
              Row(
                children: [
                  OutlinedButton.icon(
                    icon:  const Icon(Icons.image_outlined),
                    label: Text('Pick image'.tr),
                    onPressed: (){
                      controller.pickImageForWindows(context);
                    }
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(
                      () => Text(
                        controller.rxImageFileName.value ?? 'No file selected'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Obx(
                    () => controller.rxBase64Image.value != null
                        ? TextButton.icon(
                            onPressed: controller.clearPickedImage,
                            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                            label: Text('Remove', style: TextStyle(color: theme.colorScheme.error)),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.desktop_windows_outlined, size: 18, color: theme.colorScheme.outline),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Image picker is available on Windows only'.tr,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Obx(() {
              final b64 = controller.rxBase64Image.value;
              if (b64 == null) return const SizedBox.shrink();

              try {
                final bytes = base64Decode(b64);
                return Container(
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(bytes, fit: BoxFit.cover),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.black54,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: controller.clearPickedImage,
                            child: const Padding(
                              padding: EdgeInsets.all(6.0),
                              child: Icon(Icons.close, size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } catch (_) {
                return Text('Invalid image data', style: TextStyle(color: theme.colorScheme.error));
              }
            }),

            const SizedBox(height: 12),

            // Menu dropdown
            Obx(
              () => DropdownButtonFormField<int>(
                decoration: _inputDecoration(
                  theme: theme,
                  label: 'Select Menu'.tr,
                  prefix: const Icon(Icons.menu_book_outlined),
                ),
                value: controller.selectedMenuId.value == 0 ? null : controller.selectedMenuId.value,
                hint: Text('Choose menu'.tr),
                isExpanded: true,
                items: menuController.menuList
                    .map(
                      (menu) => DropdownMenuItem(
                        value: menu.id,
                        child: Text(menu.name),
                      ),
                    )
                    .toList(),
                onChanged: (val) => controller.selectedMenuId.value = val ?? 0,
                validator: (val) => (val == null || val == 0) ? 'Select menu'.tr : null,
              ),
            ),

            const SizedBox(height: 12),

            // Description
            TextFormField(
              controller: controller.textEditingControllerFoodDescription,
              decoration: _inputDecoration(
                theme: theme,
                label: 'food description'.tr,
                prefix: const Icon(Icons.description_outlined),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              ),
              maxLines: 4,
              textAlignVertical: TextAlignVertical.top,
            ),
            const SizedBox(height: 12),

            // Dietary type
            Padding(
              padding: const EdgeInsets.only(top: 6.0, bottom: 6.0),
              child: Text('dietary type'.tr, style: theme.textTheme.titleMedium),
            ),
            _radioListTileForIsVeg(controller, theme),
            const SizedBox(height: 12),

            // Meat + HSN
            Obx(() {
              if (!controller.selectIsVeg.value) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: _inputDecoration(
                          theme: theme,
                          label: 'meat type'.tr,
                          prefix: const Icon(Icons.kebab_dining_outlined),
                        ),
                        hint: Text('select meat type'.tr),
                        value: controller.selectedMeatType.value,
                        isExpanded: true,
                        items: meatType.map((String v) => DropdownMenuItem<String>(value: v, child: Text(v))).toList(),
                        onChanged: (String? newValue) => controller.selectedMeatType.value = newValue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: controller.textEditingControllerHSNCode,
                        decoration: _inputDecoration(
                          theme: theme,
                          label: 'hsn code'.tr,
                          prefix: const Icon(Icons.qr_code_scanner_outlined),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return TextFormField(
                controller: controller.textEditingControllerHSNCode,
                decoration: _inputDecoration(
                  theme: theme,
                  label: 'hsn code'.tr,
                  prefix: const Icon(Icons.qr_code_scanner_outlined),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentFoodTaxInfoCard(
    BuildContext context,
    ControllerFoodForm foodFormController,
    ControllerTaxConfiguration taxConfigController,
  ) {
    final ThemeData theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Obx(
            () => Text(
              foodFormController.foodNameForTaxCard.value.isEmpty
                  ? "Current Food Item"
                  : foodFormController.foodNameForTaxCard.value,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: theme.dividerColor.withAlpha(100)),
          const SizedBox(height: 12),
          Obx(() {
            final String? currentTaxUuid = foodFormController.currentTaxUuid.value;
            final EntityTax? assignedTax = (currentTaxUuid != null && currentTaxUuid.isNotEmpty)
                ? taxConfigController.rxAvailableTaxes.firstWhereOrNull((t) => t.taxUuid == currentTaxUuid)
                : null;

            if (assignedTax == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    "No tax assigned.",
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.disabledColor),
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTaxDetailRow(theme, "Tax Group:", assignedTax.taxProductName ?? "N/A"),
                _buildTaxDetailRow(theme, "Tax %:", assignedTax.taxPercentage?.toStringAsFixed(1) ?? "N/A"),
                _buildTaxDetailRow(theme, "Type:", (assignedTax.isSgstCgst ?? false) ? "SGST/CGST" : "Regular"),
                _buildTaxDetailRow(theme, "Included in Rate:", (assignedTax.isIncludeInRate ?? false) ? "Yes" : "No"),
              ],
            );
          }),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            icon:  Icon(Icons.edit_note_outlined),
            label: Obx(
              () => Text(
                (foodFormController.currentTaxUuid.value != null &&
                        foodFormController.currentTaxUuid.value!.isNotEmpty)
                    ? "Change Tax"
                    : "Assign Tax",

                  style: TextStyle(color: Colors.white),
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              backgroundColor: Colors.teal,
            ),
            onPressed: () {
              _showTaxConfigurationDialogForSection(context, foodFormController, taxConfigController);
            },
          ),
          const SizedBox(height: 10),
          Obx(() {
            if (foodFormController.currentTaxUuid.value != null &&
                foodFormController.currentTaxUuid.value!.isNotEmpty) {
              return OutlinedButton.icon(
                icon: Icon(Icons.clear_all_outlined, color: theme.colorScheme.error),
                label: Text("Clear Tax", style: TextStyle(color: theme.colorScheme.error)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  side: BorderSide(color: theme.colorScheme.error.withAlpha(128)),
                ),
                onPressed: () {
                  EntityFood foodItemToClearTax;
                  if (foodFormController.editingFood != null) {
                    foodItemToClearTax = foodFormController.editingFood!;
                    foodItemToClearTax.foodName = foodFormController.textEditingControllerFoodName.text;
                  } else {
                    foodItemToClearTax = EntityFood(
                      foodName: foodFormController.textEditingControllerFoodName.text,
                      categoryName: foodFormController.textEditingControllerFoodCategory.text,
                    );
                  }
                  taxConfigController.clearTaxForFood(foodItemToClearTax);
                  foodFormController.currentTaxUuid.value = null;
                },
              );
            }
            return const SizedBox.shrink();
          }),
        ]),
      ),
    );
  }

  Widget _pricingCard(ThemeData theme, ControllerFoodForm controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('pricing'.tr, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                textStyle: theme.textTheme.labelLarge,
              ),
              icon: const Icon(Icons.add_shopping_cart_outlined),
              label: Text('add edit prices'.tr),
              onPressed: () => _showPriceDialog(Get.context!, controller),
            ),
          ),
          const SizedBox(height: 12),
          Obx(() {
            if (controller.rxPriceList.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Text('no prices added'.tr, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.rxPriceList.length,
              itemBuilder: (context, index) {
                final priceEntry = controller.rxPriceList[index];
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(Icons.storefront_outlined, color: theme.colorScheme.onPrimaryContainer),
                    ),
                    title: Text(
                      priceEntry.roomType ?? 'N/A',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      "${priceEntry.price?.toStringAsFixed(2) ?? '0.00'} ${priceEntry.currency ?? ''}",
                      style: theme.textTheme.bodyMedium,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit_outlined, color: theme.colorScheme.primary),
                          tooltip: 'edit price'.tr,
                          onPressed: () {
                            _showPriceDialog(Get.context!, controller, existingPrice: priceEntry, priceIndex: index);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                          tooltip: 'delete price'.tr,
                          onPressed: () => controller.removePriceFromTempList(priceEntry),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ]),
      ),
    );
  }

  void _showTaxConfigurationDialogForSection(
    BuildContext context,
    ControllerFoodForm foodFormController,
    ControllerTaxConfiguration taxConfigController,
  ) {
    final theme = Theme.of(context);

    EntityFood foodItemForTaxConfig;
    if (foodFormController.editingFood != null) {
      foodItemForTaxConfig = foodFormController.editingFood!;
      foodItemForTaxConfig.foodName = foodFormController.textEditingControllerFoodName.text;
    } else {
      foodItemForTaxConfig = EntityFood(
        foodName: foodFormController.textEditingControllerFoodName.text,
        categoryName: foodFormController.textEditingControllerFoodCategory.text,
      );
    }

    taxConfigController.currentFoodForTaxConfig = foodItemForTaxConfig;
    taxConfigController.prepareForTaxConfiguration(foodItemForTaxConfig);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          title: Text(
            'Configure Tax for: ${foodItemForTaxConfig.foodName?.isNotEmpty ?? false ? foodItemForTaxConfig.foodName : "Current Food Item"}',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Obx(
                  () => DropdownButtonFormField<String?>(
                    decoration: _inputDecoration(
                      theme: theme,
                      label: "Select Tax",
                      prefix: const Icon(Icons.receipt_long_outlined),
                    ),
                    hint: const Text("Choose a tax configuration"),
                    value: taxConfigController.selectedTaxUuidInBottomSheet.value,
                    items: taxConfigController.rxAvailableTaxes.map((EntityTax tax) {
                      return DropdownMenuItem<String?>(
                        value: tax.taxUuid,
                        child: Text("${tax.taxProductName ?? 'Unnamed Tax'} (${tax.taxPercentage?.toStringAsFixed(1) ?? 'N/A'}%)"),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      taxConfigController.selectedTaxUuidInBottomSheet.value = newValue;
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => TextFormField(
                    readOnly: true,
                    decoration: _inputDecoration(
                      theme: theme,
                      label: "Tax Product Group",
                      prefix: const Icon(Icons.group_work_outlined),
                    ),
                    initialValue: taxConfigController.bottomSheetTaxGroupDisplay.value,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Obx(
                        () => TextFormField(
                          readOnly: true,
                          decoration: _inputDecoration(
                            theme: theme,
                            label: "Tax Type",
                            prefix: const Icon(Icons.merge_type_outlined),
                          ),
                          initialValue: taxConfigController.bottomSheetTaxTypeDisplay.value,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(
                        () => TextFormField(
                          readOnly: true,
                          decoration: _inputDecoration(
                            theme: theme,
                            label: "Tax Percentage",
                            prefix: const Icon(Icons.percent_outlined),
                          ),
                          initialValue: taxConfigController.bottomSheetTaxPercentageDisplay.value,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: Text('Cancel'.tr)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary),
              onPressed: () {
                taxConfigController.applyTaxSelectionToFood();
                foodFormController.currentTaxUuid.value = taxConfigController.selectedTaxUuidInBottomSheet.value;
                Get.back();
              },
              child: Text('Done'.tr),
            ),
          ],
        );
      },
    );
  }

  void _showPriceDialog(
    BuildContext context,
    ControllerFoodForm controller, {
    EntityPrice? existingPrice,
    int? priceIndex,
  }) {
    final theme = Theme.of(context);
    final formKey = GlobalKey<FormState>();

    final roomTypeRx = controller.selectedRoomTypeName;
    if (existingPrice?.roomType != null && existingPrice!.roomType!.isNotEmpty) {
      roomTypeRx.value = existingPrice.roomType!;
    }

    final currencyController = TextEditingController(text: existingPrice?.currency ?? 'INR');

    final mrpController = TextEditingController(text: (existingPrice?.mrp ?? existingPrice?.price)?.toString() ?? '');
    final discountController = TextEditingController(text: (existingPrice?.discountPercent ?? '').toString());
    final offerController = TextEditingController(
      text: (existingPrice?.offerPrice ?? existingPrice?.price ?? double.tryParse(mrpController.text) ?? 0.0).toString(),
    );

    void recalcOffer() {
      final mrp = double.tryParse(mrpController.text) ?? 0.0;
      final disc = double.tryParse(discountController.text) ?? 0.0;
      final calc = (mrp <= 0 || disc <= 0) ? mrp : (mrp - (mrp * (disc / 100)));

      final newText = calc.toStringAsFixed(2);
      offerController.value = offerController.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }

    mrpController.addListener(recalcOffer);
    discountController.addListener(recalcOffer);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        existingPrice == null ? 'Add New Price'.tr : 'Edit Price'.tr,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      // Room label
                      Obx(() {
                        final uniqueRoomNames = controller.rxRoomList
                            .map((r) => r.name ?? '')
                            .where((n) => n.isNotEmpty)
                            .toSet()
                            .toList();

                        return DropdownButtonFormField<String>(
                          value: roomTypeRx.value.isEmpty ? null : roomTypeRx.value,
                          decoration: _inputDecoration(
                            theme: theme,
                            label: 'Price Label *'.tr,
                            prefix: const Icon(Icons.meeting_room_outlined),
                          ),
                          items: uniqueRoomNames.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
                          onChanged: (val) => roomTypeRx.value = val ?? "",
                          validator: (val) => (val == null || val.isEmpty) ? 'Select room type error'.tr : null,
                        );
                      }),
                      const SizedBox(height: 16),

                      // MRP
                      TextFormField(
                        controller: mrpController,
                        decoration: _inputDecoration(
                          theme: theme,
                          label: 'MRP *'.tr,
                          prefix: const Icon(Icons.currency_rupee_outlined),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter MRP'.tr;
                          final d = double.tryParse(v);
                          if (d == null) return 'Invalid number'.tr;
                          if (d <= 0) return 'MRP must be > 0'.tr;
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Discount
                      TextFormField(
                        controller: discountController,
                        decoration: _inputDecoration(
                          theme: theme,
                          label: 'Discount %'.tr,
                          prefix: const Icon(Icons.percent_outlined),
                          hint: 'e.g. 10',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))],
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          final d = double.tryParse(v);
                          if (d == null) return 'Invalid number'.tr;
                          if (d < 0 || d > 95) return 'Enter 0 - 95'.tr;
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Offer (read-only)
                      TextFormField(
                        controller: offerController,
                        readOnly: true,
                        decoration: _inputDecoration(
                          theme: theme,
                          label: 'Offer Price'.tr,
                          prefix: const Icon(Icons.local_offer_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Currency
                      TextFormField(
                        controller: currencyController,
                        decoration: _inputDecoration(
                          theme: theme,
                          label: 'Currency *'.tr,
                          prefix: const Icon(Icons.money_outlined),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) => (value == null || value.isEmpty) ? 'Enter currency'.tr : null,
                      ),
                      const SizedBox(height: 16),

                      // Preview
                      Builder(builder: (_) {
                        final mrp = double.tryParse(mrpController.text) ?? 0.0;
                        final offer = double.tryParse(offerController.text) ?? mrp;
                        final hasDiscount = offer < mrp - 0.004;

                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (hasDiscount)
                                Text(
                                  '${currencyController.text} ${mrp.toStringAsFixed(0)}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                                  ),
                                ),
                              Text(
                                '${currencyController.text} ${offer.toStringAsFixed(0)}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 22),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(onPressed: () => Get.back(), child: Text('Cancel'.tr)),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            icon: const Icon(Icons.check_circle_outline),
                            label: Text(existingPrice == null ? 'Save'.tr : 'Update'.tr),
                            onPressed: () {
                              if (!formKey.currentState!.validate()) return;

                              final mrp = double.tryParse(mrpController.text) ?? 0.0;
                              final disc = double.tryParse(discountController.text) ?? 0.0;
                              final offer = double.tryParse(offerController.text) ?? mrp;

                              final newPrice = EntityPrice(
                                roomType: roomTypeRx.value,
                                currency: currencyController.text,
                                price: offer,
                                mrp: mrp,
                                discountPercent: (disc <= 0) ? null : disc,
                                offerPrice: offer,
                              );

                              if (existingPrice == null) {
                                controller.addPriceToTempList(newPrice);
                              } else if (priceIndex != null && priceIndex < controller.rxPriceList.length) {
                                controller.updatePriceInTempList(priceIndex, newPrice);
                              }
                              Get.back();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _radioListTileForIsVeg(ControllerFoodForm controller, ThemeData theme) {
    return Obx(
      () => Row(
        children: [
          Expanded(
            flex: 2,
            child: RadioListTile<bool>(
              title: Text('veg'.tr, style: theme.textTheme.bodyLarge),
              value: true,
              groupValue: controller.selectIsVeg.value,
              onChanged: (value) {
                controller.selectIsVeg.value = value!;
                if (value) controller.selectedMeatType.value = null;
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
              activeColor: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: RadioListTile<bool>(
              title: Text('non veg'.tr, style: theme.textTheme.bodyLarge),
              value: false,
              groupValue: controller.selectIsVeg.value,
              onChanged: (value) => controller.selectIsVeg.value = value!,
              dense: true,
              contentPadding: EdgeInsets.zero,
              activeColor: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}