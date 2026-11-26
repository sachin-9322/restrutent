import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/screens/home/fragments/menu/controller_menu.dart';

class FragmentMenu extends StatelessWidget {
  const FragmentMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final ControllerMenu controller = Get.put(ControllerMenu());
    final TextEditingController txtController = TextEditingController();

    return Column(
      children: [
        Expanded(
          child: Obx(() {
            if (controller.menuList.isEmpty) {
              return const Center(child: Text("No menus available"));
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Adjust columns for web
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 3, // wide cards
              ),
              itemCount: controller.menuList.length,
              itemBuilder: (context, index) {
                final menu = controller.menuList[index];

                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              menu.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  txtController.text = menu.name;
                                  Get.defaultDialog(
                                    title: 'Edit Menu',
                                    content: TextField(
                                      controller: txtController,
                                    ),
                                    textConfirm: 'Update',
                                    textCancel: 'Cancel',
                                    onConfirm: () {
                                      controller.updateMenu(
                                        menu,
                                        txtController.text,
                                      );
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => controller.deleteMenu(menu),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text("Add Menu"),
            style: ElevatedButton.styleFrom(minimumSize: const Size(200, 48)),
            onPressed: () {
              txtController.clear();
              Get.defaultDialog(
                title: 'Add Menu',
                content: TextField(controller: txtController),
                textConfirm: 'Add',
                textCancel: 'Cancel',
                onConfirm: () {
                  controller.addMenu(txtController.text);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
