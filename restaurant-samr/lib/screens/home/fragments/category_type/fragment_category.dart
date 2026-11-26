// lib/screens/home/fragments/category_type/fragment_category.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/screens/category_type_form/activity_category_type_form.dart';
import 'package:splash_screen_03/screens/home/fragments/category_type/controller_category.dart';
import 'package:splash_screen_03/screens/home/fragments/table_order/widget/glass_card.dart';

class FragmentCategory extends StatelessWidget {
  const FragmentCategory({super.key});

  @override
  Widget build(BuildContext context) {
    final ControllerCategory controller = Get.put(ControllerCategory());
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // 🔍 Search bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: SizedBox(
              width: 450,
              child: TextField(
                decoration: InputDecoration(
                  hintText: "search_categories".tr,
                  hintStyle: TextStyle(color: theme.hintColor),
                  prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                  filled: true,
                  fillColor:
                      isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
                ),
                style: theme.textTheme.bodyLarge,
                onChanged: controller.filterCategoryTypes,
              ),
            ),
          ),
        ),

        // 🧾 Category List
        Expanded(
          child: Obx(() {
            if (controller.rxCategoryList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.category_outlined, size: 80, color: theme.disabledColor),
                    const SizedBox(height: 16),
                    Text(
                      "no_categories_found".tr,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(color: theme.disabledColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "no_categories_help".tr,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.disabledColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              itemCount: controller.rxCategoryList.length,
              itemBuilder: (context, index) {
                final category = controller.rxCategoryList[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: GlasssCard(
                    borderRadius: 14,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      trailing: IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext dialogContext) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              title: Text(
                                "confirm_delete".tr,
                                style: theme.textTheme.headlineSmall,
                              ),
                              content: Text.rich(
                                TextSpan(
                                  text: "${'confirm_delete_msg'.tr} ",
                                  style: theme.textTheme.bodyMedium,
                                  children: [
                                    TextSpan(
                                      text:
                                          "'${category.categoryName ?? 'unnamed_category'.tr}'",
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                    const TextSpan(text: "?"),
                                  ],
                                ),
                              ),
                              actions: <Widget>[
                                OutlinedButton(
                                  child: Text(
                                    "cancel".tr,
                                    style: TextStyle(
                                      color: theme.colorScheme.secondary,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                  },
                                ),
                                OutlinedButton(
                                  child: Text(
                                    "delete".tr,
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                  onPressed: () {
                                    controller.removeCategoryAtIndex(index);
                                    Navigator.of(dialogContext).pop();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.redAccent,
                      ),
                      title: Text(
                        category.categoryName ?? 'unnamed_category'.tr,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          // Placeholder for extra info (e.g., tax)
                          // Text("tax_label".trParams({'tax': '${category.taxPercentage ?? 0}'}))
                        ],
                      ),
                      onTap: () {
                        Get.to(() =>  ActivityCategoryForm(),
                            arguments: category);
                      },
                      onLongPress: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext dialogContext) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            title: Text(
                              "confirm_delete".tr,
                              style: theme.textTheme.headlineSmall,
                            ),
                            content: Text(
                              "${'confirm_delete_msg'.tr} '${category.categoryName ?? 'unnamed_category'.tr}'?",
                              style: theme.textTheme.bodyMedium,
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: Text(
                                  "cancel".tr,
                                  style: TextStyle(
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                              ),
                              TextButton(
                                child: Text(
                                  "delete".tr,
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                                onPressed: () {
                                  controller.removeCategoryAtIndex(index);
                                  Navigator.of(dialogContext).pop();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          }),
        ),

        // ➕ Floating Action Button
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FloatingActionButton(
              onPressed: () {
                Get.to(() =>  ActivityCategoryForm());
              },
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              tooltip: "add_category".tr,
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ],
    );
  }
}


