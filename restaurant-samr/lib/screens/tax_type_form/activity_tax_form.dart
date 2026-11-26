import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/model/entity_tax.dart';
import 'package:splash_screen_03/screens/tax_type_form/controller_tax_form.dart';

class ActivityTaxForm extends StatelessWidget {
  const ActivityTaxForm({super.key});

  @override
  Widget build(BuildContext context) {
    final ControllerTaxForm controller = Get.put(ControllerTaxForm());
    final ThemeData theme = Theme.of(context);

    EntityTax? arguments = Get.arguments as EntityTax?;

    final isNew = arguments == null;
    if (!isNew) {
      controller.textEditingControllerTaxName.text = arguments.taxProductName ?? "";
      //controller.textEditingControllerTaxProductGroup.text = arguments.taxProductGroup ?? "";
      controller.textEditingControllerTaxPercentage.text = arguments
          .taxPercentage
          .toString();
      controller.isActive.value = arguments.isActive ?? true;
      controller.isHideTaxDetail.value = arguments.isHideTaxDetail ?? false;
      controller.isSgstCgst.value = arguments.isSgstCgst ?? false;
      controller.editTax = arguments;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'Add New Tax' : 'Edit New Tax'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SizedBox(
            width: 800, // Consistent width
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card 1: Tax Details
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isNew ? 'Tax Details' : "Edit Tax Details",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: controller.textEditingControllerTaxName,
                            decoration: InputDecoration(
                              labelText: "Tax Group Name (e.g., VAT, GST)*",
                              prefixIcon: Icon(
                                Icons.label_important_outline,
                                color: theme.colorScheme.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter the tax name";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller:
                            controller.textEditingControllerTaxPercentage,
                            decoration: InputDecoration(
                              labelText: "Tax Percentage (%)*",
                              prefixIcon: Icon(
                                Icons.percent_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter the tax percentage";
                              }
                              if (double.tryParse(value) == null) {
                                return "Please enter a valid number";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  // Card 2: Tax Settings
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Tax Settings",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Obx(
                                () => CheckboxListTile(
                              title: Text(
                                "Enable SGST/CGST Split",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              value: controller.isSgstCgst.value,
                              onChanged: (bool? value) {
                                controller.isSgstCgst.value = value ?? false;
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              activeColor: theme.colorScheme.primary,
                              secondary: Icon(
                                Icons.call_split_outlined,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ),
                          Obx(
                                () => CheckboxListTile(
                              title: Text(
                                "Tax is Active",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              value: controller.isActive.value,
                              onChanged: (bool? value) {
                                controller.isActive.value = value ?? false;
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              activeColor: theme.colorScheme.primary,
                              secondary: Icon(
                                Icons.check_circle_outline,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ),
                          Obx(
                                () => CheckboxListTile(
                              title: Text(
                                "Hide Tax Details on Bill",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              value: controller.isHideTaxDetail.value,
                              onChanged: (bool? value) {
                                controller.isHideTaxDetail.value =
                                    value ?? false;
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              activeColor: theme.colorScheme.primary,
                              secondary: Icon(
                                Icons.visibility_off_outlined,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ),
                          Obx(
                                () => CheckboxListTile(
                              title: Text(
                                "Include in Rate on Bill",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              value: controller.isIncludeInRate.value,
                              onChanged: (bool? value) {
                                controller.isIncludeInRate.value =
                                    value ?? false;
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              activeColor: theme.colorScheme.primary,
                              secondary: Icon(
                                Icons.verified,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text("Cancel"),
                        onPressed: () {
                          Get.back();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface
                              .withValues(alpha: 0.8),

                          side: BorderSide(
                            color: theme.colorScheme.outline.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: Icon(Icons.save_outlined),
                        label: Text(isNew?"Save Tax":"Update Tax"),
                        onPressed: () {
                          controller.saveTax();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,

                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 15,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
