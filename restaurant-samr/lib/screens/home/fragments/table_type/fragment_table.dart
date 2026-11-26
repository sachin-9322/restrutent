import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/screens/home/fragments/room_type/controller_room.dart';
import '../../../../utils/app_routes.dart';
import 'controller_table.dart';

class FragmentTable extends StatelessWidget {
  const FragmentTable({super.key});

  @override
  Widget build(BuildContext context) {
    final ControllerTable controller = Get.put(ControllerTable());
    final theme = Theme.of(context);
    final ControllerRoom controllerRoom = Get.put(
      ControllerRoom(),
    ); // <-- ADD THIS

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final bool isMobile = width < 600;
        final bool isTablet = width >= 600 && width < 1100;
        final crossAxisCount = isMobile
            ? 2
            : isTablet
            ? 3
            : 4; // ✅ auto grid adjustment

        return Scaffold(
          backgroundColor: theme.colorScheme.surfaceContainerLowest,
          floatingActionButton: FloatingActionButton(
            onPressed: () => Get.toNamed(AppRoutes.tableTypeForm),
            tooltip: "add_table".tr,
            child: const Icon(Icons.add),
          ),
          body: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 8 : 12,
            ),
            child: Column(
              children: [
                // 🔍 Search Field
                Padding(
                  padding: EdgeInsets.only(bottom: isMobile ? 10 : 16),
                  child: SizedBox(
                    height: isMobile ? 44 : 50,
                    child: TextField(
                      onChanged: (value) =>
                          controller.searchQuery.value = value,
                      style: TextStyle(fontSize: isMobile ? 14 : 15),
                      decoration: InputDecoration(
                        hintText: "search_by_table_name".tr,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                ),

                // 🧊 Table Grid Section
                Expanded(
                  child: Obx(() {
                    final filteredTables = controller.searchQuery.value.isEmpty
                        ? controller.rxTableList
                        : controller.rxTableList.where((table) {
                            final tableName =
                                table.tableName?.toLowerCase() ?? '';
                            return tableName.contains(
                              controller.searchQuery.value.toLowerCase(),
                            );
                          }).toList();

                    if (filteredTables.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: isMobile ? 60 : 80,
                                color: theme.disabledColor,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "no_tables_found".tr,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.disabledColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                controller.searchQuery.value.isEmpty
                                    ? "add_new_tables_to_see_them_here".tr
                                    : "no_tables_match_search_query".trParams({
                                        'query': controller.searchQuery.value
                                            .trim(),
                                      }),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.disabledColor.withOpacity(0.8),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(10),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: isMobile ? 4 / 2.2 : 4 / 2.0,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: filteredTables.length,
                      itemBuilder: (context, index) {
                        final table = filteredTables[index];
                        final bool isActive = table.isActive ?? false;

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.white.withOpacity(0.07)
                                      : Colors.black.withOpacity(0.07),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    theme.brightness == Brightness.dark
                                        ? Colors.white.withOpacity(0.05)
                                        : Colors.white.withOpacity(0.25),
                                    theme.brightness == Brightness.dark
                                        ? Colors.white.withOpacity(0.02)
                                        : Colors.white.withOpacity(0.15),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.shadowColor.withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(2, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(isMobile ? 8 : 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 🏷 Table Name
                                    Text(
                                      table.tableName ?? 'no_name'.tr,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            fontSize: isMobile ? 14 : 15,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),

                                    // 🪑 Seats & Room Line
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "${'seats'.tr}: ${table.seats ?? 0}",
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                fontSize: isMobile ? 12 : 13,
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant
                                                    .withOpacity(0.8),
                                              ),
                                        ),
                                        Flexible(
                                          child: Text(
                                            "${'room'.tr}: ${controllerRoom.getRoomNameByString(table.roomType ?? '')}",
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  fontSize: isMobile ? 12 : 13,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant
                                                      .withOpacity(0.8),
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const Spacer(),

                                    // ⚙️ Actions
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          iconSize: isMobile ? 18 : 20,
                                          visualDensity: const VisualDensity(
                                            horizontal: -4,
                                            vertical: -4,
                                          ),
                                          icon: Icon(
                                            Icons.delete_outline_rounded,
                                            color: theme.colorScheme.error
                                                .withOpacity(0.9),
                                          ),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: Text(
                                                  "confirm_delete".tr,
                                                ),
                                                content: Text(
                                                  "confirm_delete_table"
                                                      .trParams({
                                                        'name':
                                                            table.tableName ??
                                                            'no_name'.tr,
                                                      }),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(ctx),
                                                    child: Text("cancel".tr),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(ctx);
                                                      controller.deleteTable(
                                                        table,
                                                      );
                                                    },
                                                    style: TextButton.styleFrom(
                                                      backgroundColor: theme
                                                          .colorScheme
                                                          .errorContainer,
                                                      foregroundColor: theme
                                                          .colorScheme
                                                          .onErrorContainer,
                                                    ),
                                                    child: Text("delete".tr),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                        TextButton(
                                          onPressed: () => controller
                                              .isActiveOrDeactive(table),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            backgroundColor: isActive
                                                ? theme
                                                      .colorScheme
                                                      .primaryContainer
                                                      .withOpacity(0.3)
                                                : theme
                                                      .colorScheme
                                                      .errorContainer
                                                      .withOpacity(0.3),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                          ),
                                          child: Text(
                                            isActive
                                                ? "active".tr
                                                : "deactivated".tr,
                                            style: TextStyle(
                                              fontSize: isMobile ? 11 : 12,
                                              fontWeight: FontWeight.w600,
                                              color: isActive
                                                  ? theme.colorScheme.primary
                                                  : theme.colorScheme.error,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
