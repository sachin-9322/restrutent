// lib/screens/home/fragments/room/fragment_room.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/screens/home/fragments/table_order/widget/glass_card.dart';
import 'package:splash_screen_03/screens/room_type_form/activity_room_form.dart';
import 'controller_room.dart';

class FragmentRoom extends StatelessWidget {
  const FragmentRoom({super.key});

  @override
  Widget build(BuildContext context) {
    final ControllerRoom controller = Get.put(ControllerRoom());
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // 🔍 Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: SizedBox(
              width: 450,
              child: TextField(
                decoration: InputDecoration(
                  hintText: "search_room_types".tr,
                  hintStyle: TextStyle(color: theme.hintColor),
                  prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.white.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
                ),
                style: theme.textTheme.bodyLarge,
                onChanged: controller.filterRoomTypes,
              ),
            ),
          ),
        ),

        // 🏢 Room Type List
        Expanded(
          child: Obx(() {
            if (controller.rxRoomType.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.meeting_room_outlined,
                        size: 80, color: theme.disabledColor),
                    const SizedBox(height: 16),
                    Text(
                      "no_room_types_found".tr,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(color: theme.disabledColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "no_room_types_help".tr,
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
              itemCount: controller.rxRoomType.length,
              itemBuilder: (context, index) {
                final room = controller.rxRoomType[index];
                final bool isActive = room.isActive ?? false;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: GlasssCard(
                    borderRadius: 14,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 10.0),
                      leading: IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext dialogContext) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              title: Text("confirm_delete".tr,
                                  style: theme.textTheme.headlineSmall),
                              content: Text.rich(
                                TextSpan(
                                  text: "${'confirm_delete_msg'.tr} ",
                                  style: theme.textTheme.bodyMedium,
                                  children: [
                                    TextSpan(
                                      text:
                                          "'${room.name ?? 'unnamed_room'.tr}'",
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
                                  child: Text("cancel".tr,
                                      style: TextStyle(
                                          color: theme.colorScheme.secondary)),
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(),
                                ),
                                OutlinedButton(
                                  child: Text("delete".tr,
                                      style: TextStyle(
                                          color: theme.colorScheme.error)),
                                  onPressed: () {
                                    controller.removeRoomType(index);
                                    Navigator.of(dialogContext).pop();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.redAccent,
                        tooltip: "Delete Room",
                      ),
                      title: Text(
                        room.name ?? 'unnamed_room'.tr,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: TextButton(
                        onPressed: () => controller.isAvailableOrNot(room),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          backgroundColor: isActive
                              ? theme.colorScheme.primary
                                  .withOpacity(isDark ? 0.2 : 0.1)
                              : theme.colorScheme.error
                                  .withOpacity(isDark ? 0.2 : 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          isActive ? "active".tr : "deactivated".tr,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: isActive
                                ? theme.colorScheme.primary
                                : theme.colorScheme.error,
                          ),
                        ),
                      ),
                      onTap: () {
                        Get.to(() => const ActivityRoomForm(), arguments: room);
                      },
                      onLongPress: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext dialogContext) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            title: Text("confirm_delete".tr,
                                style: theme.textTheme.headlineSmall),
                            content: Text(
                              "${'confirm_delete_msg'.tr} '${room.name ?? 'unnamed_room'.tr}'?",
                              style: theme.textTheme.bodyMedium,
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: Text("cancel".tr,
                                    style: TextStyle(
                                        color: theme.colorScheme.secondary)),
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                              ),
                              TextButton(
                                child: Text("delete".tr,
                                    style: TextStyle(
                                        color: theme.colorScheme.error)),
                                onPressed: () {
                                  controller.removeRoomType(index);
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

        // ➕ Floating Add Button
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FloatingActionButton(
              onPressed: () => Get.to(() => const ActivityRoomForm()),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              tooltip: "add_room_type".tr,
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ],
    );
  }
}
