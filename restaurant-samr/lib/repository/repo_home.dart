import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:splash_screen_03/screens/home/Dashboard/fragment_dashboard.dart';
import 'package:splash_screen_03/screens/home/fragments/admin/fragment_admin.dart';
import 'package:splash_screen_03/screens/home/fragments/expness/fragment_expaness.dart';
import 'package:splash_screen_03/screens/home/fragments/menu/fragment_menu.dart';
import 'package:splash_screen_03/screens/home/fragments/receipt/fragments/Bill_Print_report/fragment_bill_report.dart';
import 'package:splash_screen_03/screens/home/fragments/receipt/fragments/category_wise/fragment_category_report.dart';

import 'package:splash_screen_03/screens/home/fragments/receipt/fragments/due_reports/fragment_due.dart';
import 'package:splash_screen_03/screens/home/fragments/receipt/fragments/kd_report/fragment_kd.dart';
import 'package:splash_screen_03/screens/home/fragments/receipt/fragments/kot_reports/fragment_kot_report.dart';
import 'package:splash_screen_03/screens/home/fragments/receipt/fragments/order_report/fragment_order_report.dart';
import 'package:splash_screen_03/screens/home/fragments/receipt/fragments/today_reports/fragment_today_reports.dart';
import 'package:splash_screen_03/screens/home/fragments/receipt/frgment_reccipt.dart';
import 'package:splash_screen_03/screens/home/fragments/receipt/payment_report/fragment_payment_repoet.dart';
import 'package:splash_screen_03/screens/home/fragments/reports/controller_reports.dart';

import 'package:splash_screen_03/screens/home/fragments/reports/fragment_reports.dart';
import 'package:splash_screen_03/screens/home/fragments/reports/open_day_report.dart';
import 'package:splash_screen_03/screens/home/fragments/setting/fragments_setting.dart';

import 'package:splash_screen_03/screens/home/fragments/users/fragment_user.dart';
import '../model/model_home_menu.dart';

import '../screens/home/fragments/category_type/fragment_category.dart';
import '../screens/home/fragments/food_type/fragment_food.dart';
import '../screens/home/fragments/master_configure/tax_group/fragment_tax_product.dart';
import '../screens/home/fragments/receipt/fragments/sales_reports/fragment_sales.dart';
import '../screens/home/fragments/room_type/fragment_rooom.dart';
import '../screens/home/fragments/table_order/fragment_table_order.dart';
import '../screens/home/fragments/table_type/fragment_table.dart';
import '../screens/home/fragments/tax_type/fragments/fragment_tax.dart';

/// ===============================
/// Menu model
/// ===============================
class MenuItemModel {
  final String title;
  final IconData icon;
  final List<MenuItemModel>? children;
  final int? screenIndex;

  MenuItemModel({
    required this.title,
    required this.icon,
    this.children,
    this.screenIndex,
  });
}

/// ===============================
/// RepoHome – Updated (NO SubOrder)
/// ===============================
class RepoHome {
  /// OLD (not used by activity_home but kept for compatibility)
  static List<ModelHomeMenu> getMenuList() {
    return [
      ModelHomeMenu(iconData: Icons.home, tooltip: "menu_home".tr),
      ModelHomeMenu(
        iconData: Icons.restaurant_outlined,
        tooltip: "menu_restaurant".tr,
      ),
      ModelHomeMenu(iconData: Icons.assignment, tooltip: "menu_receipt".tr),
      ModelHomeMenu(iconData: Icons.bar_chart, tooltip: "menu_report".tr),
      ModelHomeMenu(iconData: Icons.list, tooltip: "menu_master".tr),
      ModelHomeMenu(
        iconData: Icons.settings_suggest,
        tooltip: "menu_setting".tr,
      ),
      ModelHomeMenu(iconData: Icons.logout, tooltip: "menu_logout".tr),
      ModelHomeMenu(
        iconData: Icons.open_in_full_rounded,
        tooltip: "menu_fullscreen".tr,
      ),
      ModelHomeMenu(iconData: Icons.person, tooltip: "menu_user".tr),
      ModelHomeMenu(iconData: Icons.sync, tooltip: "menu_sync".tr),
    ];
  }

  /// ============================
  /// FIXED SCREEN LIST (NO SubOrder)
  /// ============================
  static List<Widget> screen = [
    DashboardScreen(), // 0
    FragmentTableOrder(), // 1
    ReceiptScreen(), // 2  (Shifted ↓ because SubOrder removed)
    FragmentReports(), // 3
    FragmentAdmin(), // 4
    FragmentUser(), // 5
    ExpenseDashboard(), // 6
    FragmentsSetting(), // 7
    FragmentRoom(), // 8
    FragmentTable(), // 9
    FragmentCategory(), // 10
    FragmentFood(), // 11
    FragmentMenu(), // 12
    FragmentTaxProduct(), // 13
  ];

  /// ============================
  /// FIXED MENU LIST (All indexes updated)
  /// ============================
  static List<MenuItemModel> menuList = [
    MenuItemModel(
      title: "menu_dashboard",
      icon: Icons.dashboard,
      screenIndex: 0,
    ),
    MenuItemModel(title: "menu_order", icon: Icons.restaurant, screenIndex: 1),

    MenuItemModel(
      title: "menu_receipt",
      icon: Icons.receipt_long,
      screenIndex: 2,
    ),

    MenuItemModel(
      title: "menu_reports",
      icon: Icons.description,
      screenIndex: 3,
    ),

    MenuItemModel(title: "Admin", icon: Icons.person, screenIndex: 4),

    MenuItemModel(title: "Users", icon: Icons.people, screenIndex: 5),

    MenuItemModel(
      title: "Expense",
      icon: Icons.account_balance_wallet_outlined,
      screenIndex: 6,
    ),

    MenuItemModel(title: "menu_setting", icon: Icons.settings, screenIndex: 7),

    MenuItemModel(title: "Full View", icon: Icons.fullscreen_exit),
  ];

  /// REPORT MENU (unchanged)
  static List<ModelMenuReports> menuReports = [
    ModelMenuReports(title: "Sales".tr),
    ModelMenuReports(title: "Today's".tr),
    ModelMenuReports(title: "Order".tr),
    ModelMenuReports(title: "KOT".tr),
    ModelMenuReports(title: "Payment".tr),
    ModelMenuReports(title: "Due Orders".tr),
    ModelMenuReports(title: "Category".tr),
    ModelMenuReports(title: "Bills".tr),
    ModelMenuReports(title: "Kitchen Dpt".tr),

    ModelMenuReports(title: "Shift".tr),
  ];

  static List<Widget> reportScreen = [
    FragmentSales(),
    FragmentTodayReports(),
    FragmentOrderReport(),
    FragmentKotReports(),
    FragmentPaymentRepoet(),
    FragmentDue(),
    FragmentCategoryReport(),
    FragmentBillReport(),
    FragmentKdReport(),

    OpenDayReport(),
  ];
}
