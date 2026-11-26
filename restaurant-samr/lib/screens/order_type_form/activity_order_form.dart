import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../model/entity_order_type.dart';
import 'controller_order_form.dart';

class ActivityOrderForm extends StatelessWidget {
  const ActivityOrderForm({super.key});

  @override
  Widget build(BuildContext context) {
    final ControllerOrderForm controller = Get.put(ControllerOrderForm());
    final ThemeData theme = Theme.of(context);

    final EntityOrderType? arguments = Get.arguments as EntityOrderType?;
    final bool isNew = arguments == null;

    if (!isNew && controller.textEditingControllerOrderName.text.isEmpty) {
      controller.textEditingControllerOrderName.text = arguments.name ?? "";
      controller.editingOrderType = arguments;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'create_order_type'.tr : 'update_order_type'.tr),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isNew ? 'new_order_type_details'.tr : 'edit_order_type'.tr,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: controller.textEditingControllerOrderName,
                        decoration: InputDecoration(
                          labelText: 'order_type_name'.tr,
                          prefixIcon: const Icon(Icons.receipt_long_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'please_enter_order_type_name'.tr;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: Icon(isNew ? Icons.save_alt_outlined : Icons.check_circle_outline),
                        label: Text(isNew ? 'save_order_type'.tr : 'update_order_type_btn'.tr),
                        onPressed: () {
                          controller.save();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
