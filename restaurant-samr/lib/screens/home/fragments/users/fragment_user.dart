import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/model/entity_user.dart';
import '../../../../objectbox.g.dart';
import 'controller_user.dart';

class FragmentUser extends StatelessWidget {
  const FragmentUser({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ControllerUser());

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // 🎨 Color palette with improved contrast
    final Color searchBg = isDark ? Colors.grey[850]! : Colors.grey[200]!;
    final Color tableBg = isDark ? Colors.black : Colors.white;
    final Color headerBg = isDark ? Colors.grey[800]! : Colors.teal[100]!;
    final Color textPrimary = isDark ? Colors.white : Colors.black87;
    final Color textSecondary = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔍 Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: SizedBox(
              width: 450,
              child: TextField(
                decoration: InputDecoration(
                  fillColor: searchBg,
                  filled: true,
                  hintText: "Search user...",
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 22,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                onChanged: (value) {
                  if (value.isEmpty) {
                    controller.fetchUsers();
                  } else {
                    controller.rxUserList.value = controller.userBox
                        .query(
                          EntityUser_.userName.contains(
                            value,
                            caseSensitive: false,
                          ),
                        )
                        .build()
                        .find();
                  }
                },
              ),
            ),
          ),
        ),

        Expanded(
          child: Obx(() {
            // ⏳ SHOW LOADER
            if (controller.isLoading.value) {
              return Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.3, end: 1),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Opacity(opacity: value, child: child);
                  },
                  onEnd: () {
                    // restart animation
                    controller.isLoading.refresh();
                  },
                  child: SizedBox(
                    height: 90,
                    width: 90,
                    child: Image.asset(
                      "assets/logo/logo.png", // your logo
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            }

            // 👉 NO USERS
            final userList = controller.rxUserList;
            if (userList.isEmpty) {
              return Center(
                child: Text(
                  "No users found",
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }

            // 👉 USERS TABLE (original code)
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: MediaQuery.of(context).size.width,
                color: tableBg,
                child: DataTable(
                  columnSpacing: 24,
                  headingRowColor: WidgetStateProperty.all(headerBg),
                  headingTextStyle: TextStyle(
                    color: isDark ? Colors.tealAccent[100] : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  dataTextStyle: TextStyle(color: textPrimary, fontSize: 14),
                  columns: const [
                    DataColumn(label: Text("Sr.")),
                    DataColumn(label: Text("Name")),
                    DataColumn(label: Text("Pin")),
                    DataColumn(label: Text("Phone")),
                    DataColumn(label: Text("Role")),
                  ],
                  rows: userList.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final user = entry.value;

                    return DataRow(
                      cells: [
                        DataCell(Text(index.toString())),
                        DataCell(Text(user.userName ?? "—")),
                        DataCell(Text(user.pin ?? "—")),
                        DataCell(
                          Text(
                            (user.mobile ?? '').isEmpty ? "-" : user.mobile!,
                            style: TextStyle(
                              color: (user.mobile ?? '').isEmpty
                                  ? textSecondary
                                  : textPrimary,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              user.userType ?? "Unknown",
                              style: TextStyle(
                                color: isDark
                                    ? Colors.tealAccent[100]
                                    : Colors.teal[800],
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
