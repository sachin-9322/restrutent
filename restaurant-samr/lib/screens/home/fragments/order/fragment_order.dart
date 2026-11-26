// ignore_for_file: deprecated_member_use, unnecessary_underscores

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/commons/custom_container.dart';
import 'package:splash_screen_03/model/enum_bill_status.dart';
import 'package:splash_screen_03/screens/home/fragments/order/controller_order.dart';
import 'package:splash_screen_03/screens/home/fragments/order/controller_ordetype.dart';
import 'package:splash_screen_03/screens/home/fragments/order/fragemnt_split.dart';
import 'package:splash_screen_03/screens/home/fragments/order/widget/fragment_kot_bill_tab.dart';
import 'package:splash_screen_03/screens/home/fragments/order/widget/kot_tabview.dart';
import 'package:splash_screen_03/screens/home/fragments/table_type/controller_table.dart';
import 'package:splash_screen_03/model/entity_user.dart';
import 'package:splash_screen_03/utils/sanbar.dart';

// --- Helper functions ---
Uint8List? _decodeBase64Image(String? s) {
  if (s == null || s.isEmpty) return null;
  try {
    final src = s.startsWith('data:image') ? s.split(',').last : s;
    return base64Decode(src.replaceAll('\n', '').replaceAll('\r', ''));
  } catch (_) {
    return null;
  }
}

final customerNumberController = TextEditingController();
final customerNameController = TextEditingController();
final customerAddressController = TextEditingController();
final foundUser = false.obs; // Reactive boolean from GetX

Uint8List? _tryGetFoodImageBytes(dynamic food) {
  try {
    if (food.images != null &&
        food.images is List &&
        (food.images as List).isNotEmpty) {
      final first = (food.images as List).first;
      if (first is String && first.trim().isNotEmpty) {
        final b = _decodeBase64Image(first);
        if (b != null) return b;
      }
    }
  } catch (_) {}
  try {
    final String? path = food.imgPath;
    final b = _decodeBase64Image(path);
    if (b != null) return b;
  } catch (_) {}
  return null;
}

class ActivityCategoryFood extends StatefulWidget {
  final int initialTabIndex;
  const ActivityCategoryFood({super.key, this.initialTabIndex = 0});

  @override
  State<ActivityCategoryFood> createState() => _ActivityCategoryFoodState();
}

class _ActivityCategoryFoodState extends State<ActivityCategoryFood>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  final bool _isCompactView = false;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ControllerOrder());
    final tableController = Get.put(ControllerTable());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const tealColor = Color(0xFF05606D);
    final scaffoldBg = isDark ? const Color(0xFF0B0E10) : Colors.grey[50];
    final subtleBorder = isDark
        ? Colors.white.withOpacity(0.06)
        : theme.dividerColor.withOpacity(0.08);

    // Add this new method inside your _ActivityCategoryFoodState class
    Future<void> showAddCustomerDialog() async {
      // Clear previous data when opening the dialog
      customerNumberController.clear();
      customerNameController.clear();
      customerAddressController.clear();
      foundUser.value = false;

      // Local state for suggestions
      final RxList<EntityUser> suggestions = <EntityUser>[].obs;

      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              // Local lookup function for use inside the dialog
              void onSearchChanged(String val) {
                if (val.length >= 3) {
                  final results = controller.searchCustomers(val);
                  suggestions.assignAll(results);

                  // If exact match found in suggestions, we can optionally auto-select,
                  // but better to let user pick or just show "found" if exact match exists.
                  final exactMatch = results.firstWhereOrNull(
                    (u) => u.mobile == val,
                  );
                  if (exactMatch != null) {
                    // Auto-populate if exact match (optional, but user asked for suggestion)
                    // We'll just keep the list open.
                  }
                } else {
                  suggestions.clear();
                  foundUser.value = false;
                }
              }

              void selectUser(EntityUser user) {
                customerNumberController.text = user.mobile ?? "";
                customerNameController.text =
                    (user.first?.isNotEmpty == true
                            ? "${user.first} ${user.last ?? ''}"
                            : (user.userName ?? ""))
                        .trim();
                customerAddressController.text = user.address ?? "";
                foundUser.value = true;
                suggestions.clear(); // Hide list after selection
              }

              return AlertDialog(
                title: const Text("Add / Find Customer"),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: customerNumberController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: "Customer Number",
                          suffixIcon: const Icon(Icons.search),
                        ),
                        onChanged: onSearchChanged,
                      ),

                      // Suggestions List
                      // Suggestions List
                      Obx(() {
                        if (suggestions.isEmpty) return const SizedBox.shrink();
                        // Calculate height: 60 pixels per item, max 200
                        final double listHeight = (suggestions.length * 60.0)
                            .clamp(0.0, 200.0);

                        return Container(
                          height: listHeight,
                          width: double.maxFinite,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: suggestions.length,
                            itemBuilder: (ctx, i) {
                              final u = suggestions[i];
                              return ListTile(
                                dense: true,
                                title: Text(
                                  "${u.mobile} - ${u.first ?? u.userName}",
                                ),
                                subtitle: Text(u.address ?? ""),
                                onTap: () => selectUser(u),
                              );
                            },
                          ),
                        );
                      }),

                      const SizedBox(height: 16),
                      TextField(
                        controller: customerNameController,
                        decoration: const InputDecoration(
                          labelText: "Customer Name",
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: customerAddressController,
                        decoration: const InputDecoration(
                          labelText: "Customer Address",
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Use Obx to reactively show the "found" status
                      Obx(() {
                        if (!foundUser.value) return const SizedBox.shrink();
                        return Row(
                          children: const [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text("Customer found"),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final name = customerNameController.text.trim();
                      final mobile = customerNumberController.text.trim();
                      final addr = customerAddressController.text.trim();

                      if (mobile.isEmpty || name.isEmpty) {
                        showMiniSnack(
                          context,
                          "Missing Info",
                          "Please enter name and mobile number.",
                          type: MiniSnackType.error,
                        );
                        return;
                      }

                      // Use saveCustomer to persist data
                      controller.saveCustomer(
                        name: name,
                        mobile: mobile,
                        address: addr,
                      );

                      Navigator.of(context).pop();
                      showMiniSnack(
                        context,
                        "Success",
                        "Customer saved: $name",
                        type: MiniSnackType.success,
                        maxWidth: 30,
                        bottomGap: 80,
                      );
                    },
                    child: Obx(() => Text(foundUser.value ? "Select" : "Add")),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Column(
        children: [
          // --- TOP HEADER BAR ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F1215) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  // Back Button
                  Container(
                    decoration: BoxDecoration(
                      color: tealColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Search Box
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C1F22) : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                            ),
                        ],
                      ),
                      child: TextField(
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        onChanged: controller.searchFoodByName,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: isDark
                                ? Colors.white54
                                : Colors.grey.shade600,
                          ),
                          hintText: "Search by Table, Code & Name",
                          hintStyle: TextStyle(
                            color: isDark
                                ? Colors.white54
                                : Colors.grey.shade500,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Filter Buttons
                  const SizedBox(width: 6),
                  _topButton(
                    "Add Customer",
                    isDark,
                    onTap: showAddCustomerDialog,
                  ),
                  SizedBox(width: 6),
                  _topButton(
                    "Split Bill",
                    isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SplitScreenPage()),
                      );
                    },
                  ), // // Pass the function here
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.notifications_none_rounded,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 16),
                  _orderTypeButtonRow(controller, theme, isDark, tealColor),
                ],
              ),
            ),
          ),

          // --- MAIN CONTENT ---
          Expanded(
            child: Row(
              children: [
                // LEFT CATEGORY PANEL
                Expanded(
                  flex: 8,
                  child: Container(
                    color: isDark ? const Color(0xFF0E1113) : Colors.grey[100],
                    child: Obx(() {
                      final categories = controller.rxDisplayCategoryList;
                      if (categories.isEmpty) {
                        return const Center(child: Text("No Categories"));
                      }
                      return ListView.builder(
                        itemCount: categories.length,
                        itemBuilder: (_, i) {
                          final c = categories[i];
                          final selected =
                              controller.selectedCategoryUuid.value ==
                              c.categoryName;
                          return InkWell(
                            onTap: () =>
                                controller.selectCategory(c.categoryName),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              color: selected
                                  ? (isDark ? Colors.white12 : Colors.grey[200])
                                  : Colors.transparent,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      c.categoryName ?? "Unnamed",
                                      style: TextStyle(
                                        color: selected
                                            ? tealColor
                                            : (isDark
                                                  ? Colors.white60
                                                  : Colors.black87),
                                        fontWeight: selected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (selected)
                                    Icon(
                                      Icons.chevron_right,
                                      color: tealColor,
                                      size: 18,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ),

                VerticalDivider(width: 1, color: subtleBorder),

                // --- CENTER GRID PANEL ---
                Expanded(
                  flex: 55,
                  child: Obx(() {
                    final items = controller.rxDisplayedFoodItems;
                    if (items.isEmpty) {
                      return const Center(child: Text("No items found"));
                    }

                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    final crossAxisCount =
                        MediaQuery.of(context).size.width > 1200 ? 4 : 3;

                    return GridView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: items.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (_, i) {
                        final food = items[i];
                        final bool isVeg = food.isVeg ?? true;
                        final Uint8List? img = _tryGetFoodImageBytes(food);
                        final bool hasImage = img != null;

                        final indicatorColor = isVeg
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFE53935);

                        final price = (food.price.isNotEmpty
                            ? (food.price.first.offerPrice ??
                                  food.price.first.price ??
                                  0.0)
                            : 0.0);

                        // Adaptive colors
                        final bgPlaceholder = isDark
                            ? const Color(0xFF121416)
                            : const Color(0xFFE9E9E9);
                        final blurOverlay = isDark
                            ? Colors.black.withOpacity(0.35)
                            : Colors.white.withOpacity(0.45);
                        final textColor = isDark
                            ? Colors.white
                            : Colors.black87;
                        final subTextColor = isDark
                            ? Colors.white70
                            : Colors.grey.shade700;
                        final priceColor = isDark
                            ? const Color(0xFF69C0FF)
                            : const Color(0xFF0077CC);

                        return InkWell(
                          onTap: () => controller.addToOrder(food),
                          borderRadius: BorderRadius.circular(12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                // Background image or placeholder
                                Positioned.fill(
                                  child: hasImage
                                      ? Image.memory(img, fit: BoxFit.cover)
                                      : Container(
                                          color: bgPlaceholder,
                                          child: Center(
                                            child: Icon(
                                              Icons.fastfood_rounded,
                                              color: isDark
                                                  ? Colors.white24
                                                  : Colors.black26,
                                              size: 50,
                                            ),
                                          ),
                                        ),
                                ),

                                // Overlay gradient for contrast
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: isDark
                                            ? [
                                                Colors.black.withOpacity(0.2),
                                                Colors.black.withOpacity(0.5),
                                                Colors.black.withOpacity(0.8),
                                              ]
                                            : [
                                                Colors.white.withOpacity(0.05),
                                                Colors.white.withOpacity(0.3),
                                                Colors.white.withOpacity(0.6),
                                              ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Veg / Non-veg indicator
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: indicatorColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: indicatorColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),

                                // Bottom info section
                                Positioned(
                                  left: 8,
                                  right: 8,
                                  bottom: 8,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 8,
                                        sigmaY: 8,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: blurOverlay,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              food.foodName ?? "Unnamed",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: textColor,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "₹${price.toStringAsFixed(0)}",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: priceColor,
                                                  ),
                                                ),
                                                Text(
                                                  "30 min",
                                                  style: TextStyle(
                                                    color: subTextColor,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),

                VerticalDivider(width: 1, color: subtleBorder),
                // --- RIGHT PANEL - KOT/BILL TAB ---
                Expanded(
                  flex: 28,
                  child: Container(
                    color: isDark ? const Color(0xFF0E1113) : Colors.grey[100],
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        tabBarTheme: const TabBarThemeData(
                          indicator: UnderlineTabIndicator(
                            borderSide: BorderSide(
                              width: 3,
                              color: Color(0xFF05606D),
                            ),
                            insets: EdgeInsets.symmetric(horizontal: 16),
                          ),
                          labelColor: Color(0xFF05606D),
                          unselectedLabelColor: Colors.grey,
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          unselectedLabelStyle: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      child: Obx(() {
                        final controller = Get.find<ControllerOrder>();
                        final kotItems = controller.rxKotItems;

                        String kotLabel = "KOT";

                        // ✅ Show latest KOT number
                        if (kotItems.isNotEmpty) {
                          final latestKot = kotItems.reduce(
                            (a, b) => (a.kotNumber > b.kotNumber) ? a : b,
                          );
                          kotLabel = "KOT (${latestKot.kotNumber})";
                        }

                        final currentTable = controller.rxCurrentTable.value
                            .trim();
                        String billLabel = "Bill";

                        if (currentTable.isNotEmpty) {
                          final bill = controller.findLatestOpenBillForTable(
                            currentTable,
                          );
                          final prepared = controller.hasPreparedBill(
                            currentTable,
                          );

                          if (bill != null &&
                              prepared &&
                              (bill.orderNumber ?? 0) > 0) {
                            billLabel = "Bill (${bill.orderNumber})";
                          }
                        }

                        return CustomTabContainer(
                          tabController: tabController,
                          backgroundColor: Colors.transparent,
                          isDark: isDark,
                          tabs: [
                            Tab(text: kotLabel),
                            Tab(text: billLabel),
                          ],
                          tabViews: [
                            OrderTableContent(
                              theme: theme,
                              tabController: tabController,
                            ),
                            OrderTableContentBill(theme: theme),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topButton(String title, bool isDark, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap, // Use the provided callback
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Row(
          children: [
            // This part remains the same
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderTypeButtonRow(
    ControllerOrder controller,
    ThemeData theme,
    bool isDark,
    Color tealColor,
  ) {
    final orderTypeController = Get.find<ControllerOrderType>();

    return Obx(() {
      if (orderTypeController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final list = orderTypeController.rxOrderTypes;
      final selectedId = controller.rxOrderTypeId.value;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141618) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: list.map((opt) {
            final id = opt["_id"];
            final label = opt["name"]["en"];
            final isSelected = selectedId == id;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  controller.rxOrderTypeId.value = id; // SAVE ONLY ID
                  controller.rxOrderTypeLabel.value = label;

                  controller.resetFoodListOnOrderTypeChange();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? tealColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.fastfood,
                        size: 20,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }
}
