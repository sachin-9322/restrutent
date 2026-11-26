import 'package:flutter/material.dart';

import '../screens/home/fragments/category_type/fragment_category.dart';
import '../screens/home/fragments/food_type/fragment_food.dart';
import '../screens/home/fragments/room_type/fragment_rooom.dart';
import '../screens/home/fragments/table_order/fragment_table_order.dart';
import '../screens/home/fragments/table_type/fragment_table.dart';

class RepoCaptain {
  static final menuList = [
    CaptainMenu(icon: Icons.meeting_room, title: "Room Types"),
    CaptainMenu(icon: Icons.table_bar, title: "Tables"),
    CaptainMenu(icon: Icons.category, title: "Categories"),
    CaptainMenu(icon: Icons.fastfood, title: "Food"),
    CaptainMenu(icon: Icons.table_chart, title: "Orders"),
    CaptainMenu(icon: Icons.refresh, title: "pull data"),
  ];

  static final screen = [
    FragmentRoom(),
    FragmentTable(),
    FragmentCategory(),
    FragmentFood(),
    FragmentTableOrder(),
  ];
}

class CaptainMenu {
  final IconData icon;
  final String title;
  CaptainMenu({required this.icon, required this.title});
}