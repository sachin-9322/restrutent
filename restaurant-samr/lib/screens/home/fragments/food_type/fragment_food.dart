// lib/screens/home/fragments/food/fragment_food.dart
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/commons/all_custom_field.dart';
import 'package:splash_screen_03/screens/home/fragments/food_type/controller_food.dart';
import 'package:splash_screen_03/screens/home/fragments/table_order/widget/glass_card.dart';
import 'package:splash_screen_03/services/excel_import_service.dart';
import 'package:splash_screen_03/utils/app_routes.dart';

// ---------------- Helpers to decode Base64 image safely ----------------
Uint8List? _decodeBase64Image(String? s) {
  if (s == null || s.isEmpty) return null;
  try {
    final src = s.startsWith('data:image') ? s.split(',').last : s;
    return base64Decode(src.replaceAll('\n', '').replaceAll('\r', ''));
  } catch (_) {
    return null;
  }
}

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

// ---------------- Main Fragment ----------------
class FragmentFood extends StatefulWidget {
  const FragmentFood({super.key});

  @override
  State<FragmentFood> createState() => _FragmentFoodState();
}

class _FragmentFoodState extends State<FragmentFood> {
  bool _isCompactView = false;

  @override
  Widget build(BuildContext context) {
    final ControllerFood controller = Get.put(ControllerFood());
    final theme = Theme.of(context);
    final bool isWideScreen = MediaQuery.of(context).size.width > 1000;
    final bool isDark = theme.brightness == Brightness.dark;

    final subtleBorder = isDark ? Colors.white12 : Colors.black12;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          // 🔍 Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    hint: 'search_food_items'.tr,
                    prefixIcon: Icons.search,
                    onChanged: controller.setSearchQuery,
                  ),
                ),
                const SizedBox(width: 12),
                CustomButton(
                  label: 'upload_from_excel',
                  icon: Icons.upload_file_outlined,
                  onPressed: () async {
                    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
                    try {
                      final fileResult = await ExcelImportService.pickAndImport(context);
                      if (Get.isDialogOpen ?? false) Get.back();

                      if (fileResult == null) {
                        Get.snackbar('Cancelled', 'import_cancelled'.tr, snackPosition: SnackPosition.BOTTOM);
                        return;
                      }

                      final sb = StringBuffer();
                      sb.writeln("${'imported'.tr}: ${fileResult.imported}");
                      sb.writeln("${'skipped'.tr}: ${fileResult.skipped}");
                      if (fileResult.errors.isNotEmpty) {
                        sb.writeln('\n${'errors'.tr}:');
                        for (final e in fileResult.errors) sb.writeln('- $e');
                      }

                      Get.dialog(
                        AlertDialog(
                          title: Text('Import result'),
                          content: SingleChildScrollView(child: Text(sb.toString())),
                          actions: [TextButton(onPressed: () => Get.back(), child: Text('ok'.tr))],
                        ),
                      );
                    } catch (e) {
                      if (Get.isDialogOpen ?? false) Get.back();
                      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.redAccent.withOpacity(0.9));
                    }
                  },
                ),
                const SizedBox(width: 12),
                // Toggle View
                Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: subtleBorder),
                  ),
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _isCompactView = !_isCompactView;
                      });
                    },
                    icon: Icon(
                      _isCompactView
                          ? Icons.grid_view_rounded
                          : Icons.view_list_rounded,
                      color: isDark
                          ? Colors.white70
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    tooltip: _isCompactView ? "Grid View" : "Compact View",
                  ),
                ),
              ],
            ),
          ),

          // 📂 Categories + 🍲 Food list
          Expanded(
            child: Row(
              children: [
                if (isWideScreen)
                  Container(
                    width: 140,
                    color: theme.colorScheme.surfaceContainerLowest,
                    child: Obx(() {
                      if (controller.rxDisplayCategoryList.isEmpty) {
                        return Center(child: Text('no_categories'.tr));
                      }
                      return ListView.separated(
                        itemCount: controller.rxDisplayCategoryList.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: theme.dividerColor.withOpacity(0.1),
                        ),
                        itemBuilder: (context, index) {
                          final category =
                              controller.rxDisplayCategoryList[index];
                          return Obx(() {
                            final isSelected =
                                controller.selectedCategoryUuid.value ==
                                category.categoryName;
                            return ListTile(
                              selected: isSelected,
                              selectedTileColor: theme
                                  .colorScheme
                                  .primaryContainer
                                  .withOpacity(0.3),
                              title: Text(
                                category.categoryName ?? 'unnamed_category'.tr,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: theme.colorScheme.primary,
                                    )
                                  : null,
                              onTap: () => controller.selectCategory(
                                category.categoryName,
                              ),
                            );
                          });
                        },
                      );
                    }),
                  ),
                const VerticalDivider(width: 1),

                // --- Food List ---
                Expanded(
                  child: Container(
                    color: isDark
                        ? const Color(0xFF081015)
                        : theme.colorScheme.surfaceContainerLow,
                    child: Obx(() {
                      final items = controller.rxFoodList;
                      if (controller.isLoading.value) {
                        return Center(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.3, end: 1),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeInOut,
                            builder: (context, value, child) {
                              return Opacity(opacity: value, child: child);
                            },
                            onEnd: () => controller.isLoading.refresh(),
                            child: SizedBox(
                              height: 90,
                              width: 90,
                              child: Image.asset(
                                "assets/logo/logo.png",
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        );
                      }

                      if (_isCompactView) {
                        // --- COMPACT WRAP VIEW WITH GLASS ---
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: List.generate(items.length, (index) {
                              final food = items[index];
                              final bool isVeg = food.isVeg ?? true;
                              final price = (food.price.isNotEmpty
                                  ? (food.price.first.offerPrice ??
                                        food.price.first.price ??
                                        0.0)
                                  : 0.0);
                              final indicatorColor = isVeg
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFF44336);

                              return InkWell(
                                onTap: () => Get.toNamed(
                                  AppRoutes.foodTypeForm,
                                  arguments: food,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                child: GlasssCard(
                                  borderRadius: 10,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 12,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              food.foodName ?? "Unnamed",
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark
                                                        ? Colors.white
                                                              .withOpacity(0.9)
                                                        : theme
                                                              .colorScheme
                                                              .onSurface,
                                                  ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.all(2.0),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: indicatorColor,
                                                width: 1.5,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: indicatorColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            food.shortCode ?? "",
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: isDark
                                                      ? Colors.white54
                                                      : Colors.black54,
                                                ),
                                          ),
                                          Text(
                                            price > 0
                                                ? "₹${price.toStringAsFixed(0)}"
                                                : "—",
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark
                                                      ? const Color(0xFF69C0FF)
                                                      : theme
                                                            .colorScheme
                                                            .primary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        );
                      } else {
                        // --- GRID VIEW WITH GLASS CARD ---
                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isWideScreen
                                    ? (MediaQuery.of(context).size.width > 1200
                                          ? 4
                                          : 3)
                                    : 2,
                                childAspectRatio: 4 / 3.6,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                              ),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final food = items[index];
                            final bool isVeg = food.isVeg ?? true;
                            final price = (food.price.isNotEmpty
                                ? (food.price.first.offerPrice ??
                                      food.price.first.price ??
                                      0.0)
                                : 0.0);
                            final indicatorColor = isVeg
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFF44336);
                            final Uint8List? imgBytes = _tryGetFoodImageBytes(
                              food,
                            );
                            final bool hasImage = imgBytes != null;
                            final List<Shadow> imageTextShadows = [
                              Shadow(
                                blurRadius: 8.0,
                                color: Colors.black.withOpacity(0.8),
                                offset: const Offset(0, 2),
                              ),
                            ];

                            return InkWell(
                              onTap: () => Get.toNamed(
                                AppRoutes.foodTypeForm,
                                arguments: food,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              child: GlasssCard(
                                borderRadius: 14,
                                padding: EdgeInsets.zero,
                                child: Stack(
                                  children: [
                                    if (hasImage)
                                      Positioned.fill(
                                        child: Image.memory(
                                          imgBytes,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    if (hasImage)
                                      Positioned.fill(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              stops: const [0.0, 0.6, 1.0],
                                              colors: [
                                                Colors.black.withOpacity(0.2),
                                                Colors.black.withOpacity(0.4),
                                                Colors.black.withOpacity(0.9),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            food.foodName ?? "Unnamed",
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: hasImage
                                                      ? Colors.white
                                                      : (isDark
                                                            ? Colors.white
                                                            : theme
                                                                  .colorScheme
                                                                  .onSurface),
                                                  shadows: hasImage
                                                      ? imageTextShadows
                                                      : null,
                                                ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const Spacer(),
                                          Center(
                                            child: Text(
                                              food.shortCode ?? "",
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: hasImage
                                                        ? Colors.white70
                                                        : (isDark
                                                              ? Colors.white60
                                                              : theme
                                                                    .colorScheme
                                                                    .onSurfaceVariant),
                                                    shadows: hasImage
                                                        ? imageTextShadows
                                                        : null,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            price > 0
                                                ? "₹${price.toStringAsFixed(0)}"
                                                : "—",
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: hasImage
                                                      ? Colors.white
                                                      : (isDark
                                                            ? const Color(
                                                                0xFF69C0FF,
                                                              )
                                                            : theme
                                                                  .colorScheme
                                                                  .primary),
                                                  shadows: hasImage
                                                      ? imageTextShadows
                                                      : null,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: Container(
                                        padding: const EdgeInsets.all(2.0),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(
                                            hasImage ? 0.3 : 0.0,
                                          ),
                                          border: Border.all(
                                            color: indicatorColor,
                                            width: 1.5,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: indicatorColor,
                                            shape: BoxShape.circle,
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
                      }
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
