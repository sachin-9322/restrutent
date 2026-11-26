// lib/screens/category_type_form/activity_category_type_form.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/model/entity_cateogry_tax.dart';
import 'package:splash_screen_03/screens/home/fragments/table_order/widget/glass_card.dart';
import 'controller_category_type_from.dart';

class ActivityCategoryForm extends StatelessWidget {
  ActivityCategoryForm({super.key});

  late final List<String> categoryOptions = [
    'Main Course',
    'Starters (Appetizers)',
    'Side Dishes',
    'Indian',
    'Korean',
    'Chinese',
    'Beverages',
    'Snacks & Street Food',
    'Breakfast',
    'Soups & Salads',
    'Desserts',
    'American',
    'Middle Eastern',
    'Japanese',
    'Continental',
    'Low-Carb (Keto)',
    'Gluten-Free',
    'High-Protein (Fitness Bowls)',
    'Kids Menu',
    'Combo Meals (Platters)',
    'Chef’s Specials (Signature Dishes)',
    'Seasonal Menu',
    'Daily Specials',
  ];

  @override
  Widget build(BuildContext context) {
    final ControllerCategoryFrom controller = Get.put(ControllerCategoryFrom());
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final EntityCategoryTax? arguments = Get.arguments as EntityCategoryTax?;
    final bool isNew = arguments == null;

    // Pre-fill form if editing
    if (!isNew && controller.textEditingControllerCategoryName.text.isEmpty) {
      controller.textEditingControllerCategoryName.text =
          arguments.categoryName ?? "";
      controller.editedCategory = arguments;

      final initialIndex =
          categoryOptions.indexOf(arguments.categoryName ?? "");
      if (initialIndex != -1) {
        controller.selectedCategory.value = initialIndex;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'create_category'.tr : 'update_category'.tr),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isDark ? const Color(0xFF0E141A) : Colors.grey.shade100,
              isDark ? const Color(0xFF1B2229) : Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Form(
                key: controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GlasssCard(
                      borderRadius: 20,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'category_details'.tr,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Obx(
                            () => DropdownButtonFormField<int>(
                              decoration: InputDecoration(
                                labelText: '${'category_name'.tr} *',
                                prefixIcon: Icon(
                                  Icons.category_outlined,
                                  color: theme.colorScheme.primary,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              hint: Text('select_category'.tr),
                              value: controller.selectedCategory.value == -1
                                  ? null
                                  : controller.selectedCategory.value,
                              items: categoryOptions
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) => DropdownMenuItem<int>(
                                      value: entry.key,
                                      child: Text(entry.value),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                final idx = value ?? -1;
                                controller.selectedCategory.value = idx;
                                if (idx != -1 && idx < categoryOptions.length) {
                                  controller.textEditingControllerCategoryName
                                      .text = categoryOptions[idx];
                                } else {
                                  controller.textEditingControllerCategoryName
                                      .clear();
                                }
                              },
                              validator: (value) => (value == null || value == -1)
                                  ? 'please_select_category'.tr
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    GlasssCard(
                      borderRadius: 20,
                      padding: const EdgeInsets.all(20),
                      child: _radioListTileForExclusive(controller, theme),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      icon: Icon(isNew
                          ? Icons.save_outlined
                          : Icons.check_circle_outline),
                      label: Text(isNew
                          ? 'save_category'.tr
                          : 'update_category_btn'.tr),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ).copyWith(
                        backgroundColor: MaterialStateProperty.all(
                          theme.colorScheme.primary,
                        ),
                        foregroundColor: MaterialStateProperty.all(
                          theme.colorScheme.onPrimary,
                        ),
                      ),
                      onPressed: controller.save,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _radioListTileForExclusive(
      ControllerCategoryFrom controller, ThemeData theme) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "tax_type".tr,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          RadioListTile<bool>(
            title: Text('inclusive_tax'.tr, style: theme.textTheme.bodyMedium),
            value: false,
            groupValue: controller.selectedRadioValueForExclusive.value,
            onChanged: (val) =>
                controller.selectedRadioValueForExclusive.value = val!,
            dense: true,
            activeColor: theme.colorScheme.primary,
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<bool>(
            title: Text('exclusive_tax'.tr, style: theme.textTheme.bodyMedium),
            value: true,
            groupValue: controller.selectedRadioValueForExclusive.value,
            onChanged: (val) =>
                controller.selectedRadioValueForExclusive.value = val!,
            dense: true,
            activeColor: theme.colorScheme.primary,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
