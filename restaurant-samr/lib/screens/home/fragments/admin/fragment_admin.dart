import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/screens/home/fragments/category_type/fragment_category.dart';
import 'package:splash_screen_03/screens/home/fragments/food_type/fragment_food.dart';
import 'package:splash_screen_03/screens/home/fragments/master_configure/tax_group/fragment_tax_product.dart';
import 'package:splash_screen_03/screens/home/fragments/menu/fragment_menu.dart';
import 'package:splash_screen_03/screens/home/fragments/room_type/fragment_rooom.dart';
import 'package:splash_screen_03/screens/home/fragments/table_order/widget/glass_card.dart';
import 'package:splash_screen_03/screens/home/fragments/table_type/fragment_table.dart';
import 'package:splash_screen_03/screens/home/fragments/users/fragment_user.dart';

import '../../../../repository/repo_home.dart';

class FragmentAdmin extends StatefulWidget {
  const FragmentAdmin({super.key});

  @override
  State<FragmentAdmin> createState() => _FragmentAdminState();
}

class _FragmentAdminState extends State<FragmentAdmin>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> adminTabs = [
    "Room Type",
    "Tables",
    "Category",
    "Foods",
    "Menu",
    "Tax Group",
    "Users", 
  ];

  final List<Widget> adminScreens = [
    FragmentRoom(),
    FragmentTable(),
    FragmentCategory(),
    FragmentFood(),
    FragmentMenu(),
    FragmentTaxProduct(),
    FragmentUser(), 
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: adminTabs.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color selectedTabBackgroundColor =
        isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.35);
    final Color tabBarBackgroundColor =
        isDark ? Colors.white.withOpacity(0.04) : Colors.white.withOpacity(0.20);
    final Color dividerLineColor =
        isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // ------ TAB BAR -------
          GlasssCard(
            borderRadius: 12,
            padding: const EdgeInsets.all(8),
            child: Container(
              width: Get.width * 0.6,
              decoration: BoxDecoration(
                color: tabBarBackgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: dividerLineColor, width: 1),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: adminTabs.map((e) => Tab(text: e)).toList(),
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: selectedTabBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(0.9),
                      width: 2.5,
                    ),
                  ),
                ),
                dividerColor: dividerLineColor,
                labelColor: isDark ? Colors.white : Colors.black87,
                unselectedLabelColor: isDark
                    ? Colors.white.withOpacity(0.5)
                    : Colors.black.withOpacity(0.6),
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                unselectedLabelStyle:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                labelPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ---- CONTENT ----
          Expanded(
            child: GlasssCard(
              borderRadius: 16,
              padding: EdgeInsets.zero,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TabBarView(
                  controller: _tabController,
                  children: adminScreens,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
