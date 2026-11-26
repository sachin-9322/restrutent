// lib/screens/room_type_form/activity_room_form.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/model/entity_room_type.dart';
import 'package:splash_screen_03/screens/home/fragments/table_order/widget/glass_card.dart';
import 'controller_room_form.dart';

class ActivityRoomForm extends StatelessWidget {
  const ActivityRoomForm({super.key});

  @override
  Widget build(BuildContext context) {
    final ControllerRoomForm controller = Get.put(ControllerRoomForm());
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final EntityRoomType? arguments = Get.arguments as EntityRoomType?;
    final bool isNew = arguments == null;

    // Populate controller fields if updating an existing room
    if (!isNew && controller.textEditingControllerName.text.isEmpty) {
      controller.textEditingControllerName.text = arguments?.name ?? "";
      controller.editingRoom = arguments;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'create_room_type'.tr : 'update_room_type'.tr),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isDark
                  ? const Color(0xFF0D1117)
                  : Colors.grey.shade200,
              isDark
                  ? const Color(0xFF161B22)
                  : Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: GlasssCard(
                borderRadius: 24,
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isNew
                            ? 'add_new_room_type'.tr
                            : 'edit_room_type_details'.tr,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: controller.textEditingControllerName,
                        decoration: InputDecoration(
                          labelText: 'room_type_name'.tr + ' *',
                          prefixIcon:
                              const Icon(Icons.meeting_room_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'room_type_name_required'.tr;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: Icon(isNew
                            ? Icons.save_alt_outlined
                            : Icons.check_circle_outline),
                        label: Text(isNew
                            ? 'save_room_type'.tr
                            : 'update_room_type_btn'.tr),
                        onPressed: controller.submit,
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
