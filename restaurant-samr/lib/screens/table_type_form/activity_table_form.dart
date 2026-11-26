import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/model/entity_table.dart';
import 'controller_table_form.dart';

class ActivityTableForm extends StatelessWidget {
  ActivityTableForm({super.key});

  final ControllerTableForm controller = Get.put(ControllerTableForm());

  final List<int> seatOptions = List.generate(10, (index) => index + 1);

  final EntityTable? arguments = Get.arguments as EntityTable?;
  late final bool isNew = arguments == null;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Prefill controller fields if editing and controller not already populated
    if (!isNew && controller.textEditingControllerTableName.text.isEmpty) {
      controller.textEditingControllerTableName.text = arguments?.tableName ?? '';
      controller.selectedSeats.value = arguments?.seats ?? 0;
      controller.selectedRoomTypeName.value = arguments?.roomType ?? '';
      controller.textEditingControllerRoomUuid.text = arguments?.roomUuid ?? '';
      controller.editTable = arguments;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'create_table'.tr : 'update_table'.tr),
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
                        isNew ? 'enter_table_details'.tr : 'edit_table_details'.tr,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: controller.textEditingControllerTableName,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.table_restaurant_outlined),
                          labelText: 'table_name'.tr + ' *',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'table_name_required'.tr;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Obx(
                        () => DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.chair_outlined),
                            labelText: 'number_of_seats'.tr + ' *',
                          ),
                          hint: Text('select_seats'.tr),
                          value: controller.selectedSeats.value == 0
                              ? null
                              : controller.selectedSeats.value,
                          items: seatOptions
                              .map(
                                (seat) => DropdownMenuItem(
                                  value: seat,
                                  child: Text(
                                    // simple pluralization
                                    '$seat ${seat > 1 ? 'seats_short'.tr : 'seat_short'.tr}',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            controller.selectedSeats.value = value ?? 0;
                          },
                          validator: (value) {
                            if (value == null || value == 0) {
                              return 'select_seats_required'.tr;
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Obx(
                        () => DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.meeting_room_outlined),
                            labelText: 'room_type'.tr + ' *',
                          ),
                          hint: Text('select_room_type'.tr),
                          value: controller.selectedRoomTypeName.value.isEmpty
                              ? null
                              : controller.selectedRoomTypeName.value,
                          items: controller.rxRoomList
                              .map(
                                (roomType) => DropdownMenuItem(
                                  value: roomType.name,
                                  child: Text(roomType.name ?? 'unnamed_room'.tr),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            controller.selectedRoomTypeName.value = value ?? '';
                            if (value != null && value.isNotEmpty) {
                              final selectRoomType = controller.rxRoomList.firstWhere(
                                (room) => (room.name ?? '') == value,
                                orElse: () => controller.rxRoomList.isNotEmpty
                                    ? controller.rxRoomList.first
                                    : null as dynamic,
                              );
                              if (selectRoomType != null) {
                                controller.textEditingControllerRoomUuid.text =
                                    selectRoomType.roomUuid ?? '';
                              }
                            } else {
                              controller.textEditingControllerRoomUuid.clear();
                            }
                          },
                          validator: (value) =>
                              (value == null || value.isEmpty) ? 'room_type_required'.tr : null,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save_alt_outlined),
                        label: Text(isNew ? 'save_table'.tr : 'update_table_btn'.tr),
                        onPressed: controller.saveTableDetails,
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