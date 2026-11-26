import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/screens/home/fragments/sub_order_type/controller_sub_order.dart';
import 'package:splash_screen_03/utils/app_routes.dart';

class FragmentSubOrder extends StatelessWidget {
  const FragmentSubOrder({super.key});

  @override
  Widget build(BuildContext context) {
    final ControllerSubOrder controller = Get.put(ControllerSubOrder());
    final ThemeData theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: SizedBox(
              width: 450,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'search_order_types'.tr,
                  hintStyle: TextStyle(color: theme.hintColor),
                  prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
                ),
                style: theme.textTheme.bodyLarge,
                onChanged: (value) {
                  controller.filterOrderTypes(value);
                },
              ),
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.rxOrderList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 80, color: theme.disabledColor),
                    const SizedBox(height: 16),
                    Text(
                      'no_order_types_found'.tr,
                      style: theme.textTheme.headlineSmall?.copyWith(color: theme.disabledColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'add_new_order_types'.tr,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              itemCount: controller.rxOrderList.length,
              itemBuilder: (context, index) {
                final order = controller.rxOrderList[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.tertiaryContainer,
                      child: Icon(Icons.assignment_turned_in_outlined, color: theme.colorScheme.onTertiaryContainer),
                    ),
                    title: Text(
                      order.name ?? 'unnamed_order_type'.tr,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                      tooltip: 'delete_order_type'.tr,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext dialogContext) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            title: Text('confirm_delete'.tr, style: theme.textTheme.headlineSmall),
                            content: Text(
                              'delete_order_type_msg'.trParams({
                                'name': order.name ?? 'unnamed_order_type'.tr,
                              }),
                              style: theme.textTheme.bodyMedium,
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: Text('cancel'.tr, style: TextStyle(color: theme.colorScheme.secondary)),
                                onPressed: () => Navigator.of(dialogContext).pop(),
                              ),
                              TextButton(
                                child: Text('delete'.tr, style: TextStyle(color: theme.colorScheme.error)),
                                onPressed: () {
                                  controller.removeOrderTypeAtIndex(index);
                                  Navigator.of(dialogContext).pop();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    onTap: () {
                      Get.toNamed(AppRoutes.orderTypeForm, arguments: order);
                    },
                  ),
                );
              },
            );
          }),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FloatingActionButton(
              onPressed: () {
                Get.toNamed(AppRoutes.orderTypeForm);
              },
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              tooltip: 'add_order_type'.tr,
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ],
    );
  }
}
