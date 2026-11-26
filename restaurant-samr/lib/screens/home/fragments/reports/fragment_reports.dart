import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/screens/home/fragments/reports/controller_reports.dart';
import 'package:splash_screen_03/screens/home/fragments/table_order/widget/glass_card.dart';
import '../../../../repository/repo_home.dart';

class FragmentReports extends StatefulWidget {
  const FragmentReports({super.key});

  @override
  State<FragmentReports> createState() => _FragmentReportsState();
}

class _FragmentReportsState extends State<FragmentReports>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ControllerReports controller = Get.put(ControllerReports());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: RepoHome.menuReports.length,
      vsync: this,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        controller.changeScreen(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color selectedTabBackgroundColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.white.withOpacity(0.35);
    final Color tabBarBackgroundColor = isDark
        ? Colors.white.withOpacity(0.04)
        : Colors.white.withOpacity(0.20);
    final Color dividerLineColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.05);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final bool isMobile = width < 700;
        final bool isTablet = width >= 700 && width < 1100;

        if (RepoHome.menuReports.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  size: isMobile ? 40 : 48,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: 12),
                Text(
                  "No reports available",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          );
        }

        // Base padding and tab scaling
        final horizontalPadding = isMobile ? 8.0 : (isTablet ? 16.0 : 24.0);
        final tabTextSize = isMobile ? 13.0 : 14.0;
        final tabWidthFactor = isMobile
            ? 0.95
            : isTablet
            ? 0.8
            : 0.8;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: isMobile ? 10 : 16),

              // 🌫️ --- Glassmorphic Tab Bar Wrapper ---
              GlasssCard(
                borderRadius: 12,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Container(
                  width: Get.width * tabWidthFactor,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: tabBarBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: dividerLineColor, width: 1),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabs: RepoHome.menuReports
                        .map((e) => Tab(text: e.title))
                        .toList(),

                    // ✨ Glassmorphic Tab Indicator
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

                    // Text styling
                    labelColor: isDark ? Colors.white : Colors.black87,
                    unselectedLabelColor: isDark
                        ? Colors.white.withOpacity(0.6)
                        : Colors.black.withOpacity(0.6),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: tabTextSize,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: tabTextSize,
                    ),
                    labelPadding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 14 : 20,
                      vertical: isMobile ? 10 : 12,
                    ),
                    tabAlignment: TabAlignment.start,
                  ),
                ),
              ),

              SizedBox(height: isMobile ? 12 : 20),

              // 🌈 --- Glassmorphic Content Area ---
              Expanded(
                child: GlasssCard(
                  borderRadius: 16,
                  padding: EdgeInsets.zero,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 10 : 16,
                      8,
                      isMobile ? 10 : 16,
                      isMobile ? 10 : 16,
                    ),
                    child: TabBarView(
                      controller: _tabController,
                      children: RepoHome.reportScreen,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
