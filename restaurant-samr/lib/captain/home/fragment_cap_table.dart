import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/captain/home/fragment_captain_food.dart';
import 'package:splash_screen_03/screens/home/fragments/order/controller_order.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/controller_setting.dart';
import 'package:splash_screen_03/screens/home/fragments/sub_order_type/controller_sub_order.dart';
import 'package:splash_screen_03/screens/home/fragments/table_type/controller_table.dart';

class FragmentCapTableOrder extends StatelessWidget {
  const FragmentCapTableOrder({super.key});

  @override
  Widget build(BuildContext context) {
    final ControllerTable controller = Get.isRegistered<ControllerTable>()
        ? Get.find<ControllerTable>()
        : Get.put(ControllerTable());

    final ControllerSetting settingController =
        Get.isRegistered<ControllerSetting>()
        ? Get.find<ControllerSetting>()
        : Get.put(ControllerSetting());
    final ControllerSubOrder subController =
        Get.isRegistered<ControllerSubOrder>()
        ? Get.find<ControllerSubOrder>()
        : Get.put(ControllerSubOrder());

    final theme = Theme.of(context);

    /// Responsive columns
    int getCrossAxisCount(double width) {
      if (width > 1200) return 5;
      if (width > 900) return 4;
      if (width > 600) return 3;
      return 2;
    }

    /// Fancy table card
    Widget buildTableCard({
      required String name,
      required String room,
      required int seats,
      String? orderNumber,
      required VoidCallback onTap,
      bool isTemp = false,
      bool isActive = true,
      bool isBooked = false,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            // --- CHANGE START ---
            // The border is now the indicator for booking status.
            border: isBooked
                ? Border.all(color: Colors.teal, width: 2.5) // Teal border if booked
                : null, // No border if not booked
            // The background gradient now only depends on the table's active status.
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.1),
                      theme.colorScheme.surface,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [Colors.grey.shade200, Colors.grey.shade300],
                  ),
            // --- CHANGE END ---
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Top: Table name + Bill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (orderNumber != null && orderNumber.isNotEmpty)
                      Chip(
                        label: Text(
                          "#$orderNumber",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        backgroundColor: theme.colorScheme.primary,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                /// Middle: Seats & Room
                Row(
                  children: [
                    Icon(
                      Icons.event_seat,
                      size: 18,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "$seats ${'seats'.tr}",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.meeting_room,
                      size: 18,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        room,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                /// Status + Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isActive ? "Active".tr : "Inactive".tr,
                        style: TextStyle(
                          color: isActive
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Icon(
                      isTemp
                          ? Icons.arrow_forward_ios
                          : Icons.table_bar_rounded,
                      color: isTemp ? Colors.blue : theme.colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          /// Header with profile
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                
                  // GestureDetector(
                  //   onTap: () {
                  //     Get.to(() => const ActivityProfile(),
                  //         transition: Transition.rightToLeft,
                  //         duration: const Duration(milliseconds: 300));
                  //   },
                  //   child: CircleAvatar(
                  //     radius: 22,
                  //     backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  //     child: const Icon(Icons.person, color: Colors.black87),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),

          /// Filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Obx(() {
              return DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  hintText: 'filter_by_room_type'.tr,
                  prefixIcon: const Icon(Icons.filter_list_alt),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.2),
                ),
                dropdownColor: theme.colorScheme.surface,
                style: theme.textTheme.bodyLarge,
                value: controller.selectedRoomTypeName.value.isEmpty
                    ? null
                    : controller.selectedRoomTypeName.value,
                items: controller.rxRoomList
                    .map(
                      (rt) => DropdownMenuItem(
                        value: rt.name,
                        child: Text(rt.name ?? 'unnamed_room'.tr),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    controller.selectedRoomTypeName.value = val;
                  }
                },
                isExpanded: true,
                icon: Icon(
                  Icons.arrow_drop_down_circle_outlined,
                  color: theme.colorScheme.primary,
                ),
              );
            }),
          ),

          /// Grid
          Expanded(
            child: Obx(() {
              final filteredTables =
                  controller.selectedRoomTypeName.value.isEmpty
                  ? controller.rxTableList
                  : controller.rxTableList
                        .where(
                          (t) =>
                              t.roomType ==
                              controller.selectedRoomTypeName.value,
                        )
                        .toList();

              final temp = controller.selectedTempTable.value;
              final totalItems = filteredTables.length + (temp != null ? 1 : 0);

              if (totalItems == 0) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.table_restaurant_outlined,
                        size: 120,
                        color: theme.disabledColor.withOpacity(0.6),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'no_tables_found'.tr,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.disabledColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        controller.selectedRoomTypeName.value.isEmpty
                            ? 'try_adding_new_table'.tr
                            : 'no_tables_for_room'.tr,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.disabledColor,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final width = MediaQuery.of(context).size.width;
              final crossAxisCount = getCrossAxisCount(width);

              return GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 2 / 2.3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: totalItems,
                itemBuilder: (context, index) {
                  final tableIndex = temp != null ? index - 1 : index;
                  final table = filteredTables[tableIndex];
                  final isBooked = controller.isTableBooked(table.tableName);

                  return buildTableCard(
                    name: table.tableName ?? 'unnamed_table'.tr,
                    room: controller.getRoomTypeName(table.roomType ?? ''),
                    seats: table.seats ?? 0,
                    orderNumber: table.orderNumber?.toString(),
                    onTap: () {
                      // 1) Ensure we have one ControllerOrder instance
                      final orderCtrl = Get.isRegistered<ControllerOrder>()
                          ? Get.find<ControllerOrder>()
                          : Get.put(ControllerOrder(), permanent: true);

                      // 2) Also set the selected table in ControllerTable so other screens can read it
                      controller.selectedTable.value = table; // <-- add this

                      // 3) Push the selected table into the order controller
                      final tName = table.tableName ?? '';
                      orderCtrl.loadTableOrders(tName);

                      // 4) Navigate
                      Get.to(
                        () => const FragmentCaptainFood(),
                        transition: Transition.fadeIn,
                        duration: const Duration(milliseconds: 300),
                      );
                    },
                    isActive: table.isActive ?? true,
                    isBooked: isBooked, // <-- add this
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}