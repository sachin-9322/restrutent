import 'package:flutter/material.dart';

class CustomTabContainer extends StatelessWidget {
  final TabController tabController;
  final List<Tab> tabs;
  final List<Widget> tabViews;
  final Color backgroundColor;
  final bool isDark;

  const CustomTabContainer({
    super.key,
    required this.tabController,
    required this.tabs,
    required this.tabViews,
    required this.backgroundColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: TabBar(
            controller: tabController,
            tabs: tabs,
            labelColor: isDark ? Colors.white : Theme.of(context).colorScheme.primary,
            unselectedLabelColor: isDark ? Colors.white60 : Theme.of(context).disabledColor,
            indicatorColor: isDark ? const Color(0xFF69C0FF) : Theme.of(context).primaryColor,
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: tabViews,
          ),
        ),
      ],
    );
  }
}
