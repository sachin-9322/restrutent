import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/screens/home/fragments/table_order/widget/glass_card.dart';
import '../../repository/repo_home.dart';
import '../../utils/app_routes.dart';
import 'controller_home.dart';

// Sidebar color helpers
Color _sidebarFg(bool isDark, bool selected) =>
    selected ? Colors.white : (isDark ? Colors.white : Colors.black87);

Color _sidebarBg(bool selected) =>
    selected ? const Color(0xFF005D6A) : Colors.transparent;

class ActivityHome extends StatelessWidget {
  const ActivityHome({super.key});

  @override
  Widget build(BuildContext context) {
    final ControllerHome controller = Get.put(ControllerHome());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 5,
      child: RawKeyboardListener(
        focusNode: controller.keyFocusNode,
        autofocus: true,
        onKey: controller.handleKey,
        child: Scaffold(
          body: Row(
            children: [
              _buildSidebar(context, controller, isDark),

              Expanded(
                child: Obx(() {
                  final idx = controller.selectedIndex.value;
                  if (idx < 0 || idx >= RepoHome.screen.length) {
                    return Center(
                      child: Text(
                        "Invalid screen index: $idx",
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    );
                  }
                  return RepoHome.screen[idx];
                }),
              ),
            ],
          ),

          floatingActionButton: Obx(() {
            switch (controller.selectedIndex.value) {
              case 9:
                return FloatingActionButton(
                  heroTag: 'fab_room_type',
                  onPressed: () => Get.toNamed(AppRoutes.roomTypeForm),
                  child: const Icon(Icons.add),
                );
              case 11:
                return FloatingActionButton(
                  heroTag: 'fab_category',
                  onPressed: () => Get.toNamed(AppRoutes.categoryTypeForm),
                  child: const Icon(Icons.add),
                );
              case 12:
                return FloatingActionButton(
                  heroTag: 'fab_food',
                  onPressed: () => Get.toNamed(AppRoutes.foodTypeForm),
                  child: const Icon(Icons.add),
                );
              default:
                return const SizedBox.shrink();
            }
          }),
        ),
      ),
    );
  }

  Widget _buildSidebar(
      BuildContext context, ControllerHome controller, bool isDark) {
    return Obx(() {
      final bool collapsed = controller.isCollapsed.value;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        width: collapsed ? 90 : 180,
        child: GlasssCard(
          borderRadius: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildSidebarHeader(controller, isDark, collapsed),
              const SizedBox(height: 12),

              Expanded(
                child: _buildMenuList(context, controller, isDark, collapsed),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSidebarHeader(
      ControllerHome controller, bool isDark, bool collapsed) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SvgPicture.asset(
            collapsed ? 'assets/logo/logo_icon.svg' : 'assets/logo/logo.svg',
            height: collapsed ? 24 : 28,
            semanticsLabel: 'RH POS Logo',
          ),
          IconButton(
            tooltip: collapsed ? 'Expand' : 'Collapse',
            onPressed: controller.toggleCollapse,
            icon: Icon(
              collapsed ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
              color: isDark ? Colors.white70 : Colors.black54,
              size: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList(BuildContext context, ControllerHome controller,
      bool isDark, bool collapsed) {
    return ListView.separated(
      itemCount: RepoHome.menuList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10), // SPACING FIXED
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemBuilder: (context, index) {
        final menuItem = RepoHome.menuList[index];

        // Fullscreen menu (desktop only)
        if (menuItem.title == "menu_fullscreen" ||
            menuItem.title == "Full View") {
          if (!GetPlatform.isDesktop) return const SizedBox.shrink();
          return Obx(() =>
              _buildFullScreenTile(context, controller, isDark, collapsed));
        }

        return _buildRegularMenuTile(
            context, controller, menuItem, isDark, collapsed);
      },
    );
  }

  Widget _buildFullScreenTile(BuildContext context,
      ControllerHome controller, bool isDark, bool collapsed) {
    final bool isFull = controller.isFullScreen.value;
    final tooltip = isFull ? "Exit Full Screen" : "Enter Full Screen";
    final icon = isFull ? Icons.fullscreen_exit : Icons.fullscreen;

    if (collapsed) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Tooltip(
          message: tooltip,
          child: IconButton(
            onPressed: controller.toggleFullScreen,
            iconSize: 22,
            icon: Icon(icon, color: _sidebarFg(isDark, false)),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.transparent,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, size: 20, color: _sidebarFg(isDark, false)),
        title: Text(
          tooltip,
          style: TextStyle(
            fontSize: 14,
            color: _sidebarFg(isDark, false),
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: controller.toggleFullScreen,
      ),
    );
  }

  Widget _buildRegularMenuTile(
      BuildContext context,
      ControllerHome controller,
      MenuItemModel menuItem,
      bool isDark,
      bool collapsed) {
    return Obx(() {
      final bool isSelected =
          menuItem.screenIndex != null &&
              controller.selectedIndex.value == menuItem.screenIndex;

      // COLLAPSED VERSION (ICON ONLY)
      if (collapsed) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8), // spacing
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _sidebarBg(isSelected),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Tooltip(
            message: menuItem.title.tr,
            child: IconButton(
              onPressed: () {
                if (menuItem.screenIndex != null) {
                  controller.changeScreen(menuItem.screenIndex!);
                }
              },
              iconSize: 22,
              icon: Icon(menuItem.icon, color: _sidebarFg(isDark, isSelected)),
            ),
          ),
        );
      }

      // EXPANDED VERSION (ICON + TEXT)
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8), // spacing
        decoration: BoxDecoration(
          color: _sidebarBg(isSelected),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Icon(menuItem.icon,
              size: 20, color: _sidebarFg(isDark, isSelected)),
          title: Text(
            menuItem.title.tr,
            style: TextStyle(
              fontSize: 14,
              color: _sidebarFg(isDark, isSelected),
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () {
            if (menuItem.screenIndex != null) {
              controller.changeScreen(menuItem.screenIndex!);
            }
          },
        ),
      );
    });
  }
}
