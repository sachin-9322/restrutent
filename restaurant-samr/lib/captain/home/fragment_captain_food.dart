// activity_category_food.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:objectbox/objectbox.dart';
import 'package:splash_screen_03/captain/home/fragment_cart.dart';
import 'package:splash_screen_03/captain/pull/controller_captain_pull.dart';
import 'package:splash_screen_03/model/entity_cateogry_tax.dart';
import 'package:splash_screen_03/model/entity_food.dart';
import 'package:splash_screen_03/objectbox.g.dart';
import 'package:splash_screen_03/screens/home/fragments/order/controller_order.dart';
import 'package:splash_screen_03/screens/home/fragments/table_type/controller_table.dart';

class FragmentCaptainFood extends StatefulWidget {
  const FragmentCaptainFood({super.key});

  @override
  State<FragmentCaptainFood> createState() => _FragmentCaptainFoodState();
}

// Helpers to decode Base64 image safely
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

class _FragmentCaptainFoodState extends State<FragmentCaptainFood> {
  late final ControllerOrder controller;
  late final ControllerTable tableController;
  ControllerCaptainPull? captain; // <— optional ref to loading state

  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;
  Worker? _searchWorker; // GetX subscription
  StreamSubscription<Query<EntityCategoryTax>>? _catWatch;
  StreamSubscription<Query<EntityFood>>? _foodWatch;

  @override
  void initState() {
    super.initState();

    tableController = Get.isRegistered<ControllerTable>()
        ? Get.find<ControllerTable>()
        : Get.put(ControllerTable());

    controller = Get.isRegistered<ControllerOrder>()
        ? Get.find<ControllerOrder>()
        : Get.put(ControllerOrder(), permanent: true);

    // Optional: hook captain pull controller if available
    if (Get.isRegistered<ControllerCaptainPull>()) {
      captain = Get.find<ControllerCaptainPull>();
    }
    final orderController = Get.find<ControllerOrder>();
 
    orderController.selectOrderTypeById(
      id: "local-dinein", // local ID for Dine In
      label: "Dine In",
    );

    final tName = tableController.selectedTable.value?.tableName?.trim();
    if ((tName ?? '').isNotEmpty) {
      controller.loadTableOrders(tName!);
    }

    // Show local data immediately
    controller.refreshFoodList();

    // Keep search in sync with controller
    _searchWorker = ever<String>(controller.rxSearchQuery, (q) {
      if (!mounted) return;
      if (_searchCtrl.text != q) {
        _searchCtrl.value = TextEditingValue(
          text: q,
          selection: TextSelection.collapsed(offset: q.length),
        );
      }
    });

    // Watch foods — trigger immediately and resolve query to detect changes
    final boxFood = Get.find<Box<EntityFood>>();
    _foodWatch = boxFood.query().watch(triggerImmediately: true).listen((q) {
      q.find(); // resolve
      if (!mounted) return;
      controller.refreshFoodList();
    });

    // Watch categories — chips update immediately
    final boxCat = Get.find<Box<EntityCategoryTax>>();
    _catWatch = boxCat.query().watch(triggerImmediately: true).listen((q) {
      // The query 'q' from the stream gives us the latest results.
      final allCategories = q.find();
      if (!mounted) return;

      // ========================= FIX START =========================
      // Explicitly update the controller's category list. This ensures the
      // UI chips are always in sync with the database, which solves the
      // problem of categories not appearing.
      allCategories.sort(
        (a, b) => (a.categoryName ?? "").compareTo(b.categoryName ?? ""),
      );
      controller.rxMasterCategoryList.assignAll(allCategories);
      // ========================== FIX END ==========================

      // Also call refreshFoodList() to update the displayed food items based
      // on the current filters after the category list has been updated.
      controller.refreshFoodList();
    });
  }

  @override
  void dispose() {
    _foodWatch?.cancel();
    _catWatch?.cancel();
    _searchWorker?.dispose();
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      controller.searchFoodByName(query);
      if (mounted) setState(() {}); // update clear icon visibility
    });
  }

  void _clearSearch() {
    if (!mounted) return;
    _searchCtrl.clear();
    controller.searchFoodByName('');
    setState(() {});
    _searchFocus.requestFocus();
  }

  bool isNarrow(BuildContext context) =>
      MediaQuery.of(context).size.width < 900;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF005D6A),
        title: const Text(
          "Food",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        actions: [
          // Manual refresh + show spinner
          Obx(() {
            final loading = captain?.isLoading.value ?? false;
            return IconButton(
              tooltip: loading ? 'Syncing...' : 'Refresh',
              onPressed: loading
                  ? null
                  : () async {
                      try {
                        await captain?.manualRefresh();
                      } catch (_) {}
                    },
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.sync),
            );
          }),
          Obx(() {
            final itemCount = controller.totalItemsCount.value;
            return IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.shopping_cart),
                  if (itemCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.red,
                        child: Text(
                          "$itemCount",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () => Get.to(() => CartScreen(controller: controller)),
            );
          }),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildSearchBar(theme),
              _buildCategoryChips(theme),
              Expanded(
                // Pull-to-refresh
                child: Obx(() {
                  final loading = captain?.isLoading.value ?? false;
                  return RefreshIndicator(
                    onRefresh: () async {
                      try {
                        await captain?.manualRefresh();
                      } catch (_) {}
                    },
                    child: _buildFoodStaggeredGrid(theme, width, loading),
                  );
                }),
              ),
            ],
          ),

          // Thin syncing bar overlay at top when loading (doesn't block UI)
          Obx(() {
            final loading = captain?.isLoading.value ?? false;
            if (!loading) return const SizedBox.shrink();
            return const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 2),
            );
          }),
        ],
      ),
    );
  }

  // SEARCH BAR
  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: TextField(
        controller: _searchCtrl,
        focusNode: _searchFocus,
        onChanged: _onSearchChanged,
        onSubmitted: (_) => _searchFocus.unfocus(),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search items...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 12,
          ),
        ),
      ),
    );
  }

  // CATEGORY CHIPS
  Widget _buildCategoryChips(ThemeData theme) {
    return Obx(() {
      final categories = controller.rxMasterCategoryList;
      final selected = controller.selectedCategoryUuid.value;
      final isSearching = controller.rxSearchQuery.value.isNotEmpty;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            ChoiceChip(
              label: const Text("All Items"),
              selected: selected == ControllerOrder.ALL_ITEMS_UUID,
              onSelected: (_) {
                if (!isSearching) {
                  controller.selectCategory(ControllerOrder.ALL_ITEMS_UUID);
                } else {
                  _clearSearch();
                  controller.selectCategory(ControllerOrder.ALL_ITEMS_UUID);
                }
              },
            ),
            const SizedBox(width: 8),
            ...categories.map(
              (cat) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(cat.categoryName ?? "Unnamed"),
                  selected: selected == (cat.categoryName ?? ''),
                  onSelected: (_) {
                    if (controller.rxSearchQuery.value.isNotEmpty) {
                      _clearSearch();
                    }
                    controller.selectCategory(cat.categoryName);
                  },
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // FOOD GRID (with skeleton when loading and empty)
  Widget _buildFoodStaggeredGrid(
    ThemeData theme,
    double width,
    bool isLoading,
  ) {
    return Obx(() {
      final items = controller.rxDisplayedFoodItems;

      // If still loading and nothing local yet, show skeleton placeholders
      if (isLoading && items.isEmpty) {
        return _buildFoodSkeleton(theme, width);
      }

      if (items.isEmpty) {
        final searching = controller.rxSearchQuery.value.isNotEmpty;
        final message = searching
            ? "No matching items found"
            : (controller.selectedCategoryUuid.value ==
                      ControllerOrder.ALL_ITEMS_UUID
                  ? "No food items available"
                  : "No items in this category");

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.no_food_outlined,
                size: 80,
                color: theme.disabledColor,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.disabledColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      final crossAxisCount = width >= 1200 ? 4 : (width >= 800 ? 3 : 2);

      return MasonryGridView.count(
        padding: const EdgeInsets.all(12),
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final food = items[index];
          final isVeg = (food.isVeg ?? true);
          final dietaryType = isVeg ? 'Veg' : 'Non-Veg';
          final priceText = controller.getFoodPriceDisplay(food);

          final Uint8List? imgBytes = _tryGetFoodImageBytes(food);

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 120,
                  child: (imgBytes != null)
                      ? Image.memory(
                          imgBytes,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                      : Container(
                          color: theme.colorScheme.tertiaryContainer,
                          child: Icon(
                            Icons.fastfood,
                            size: 50,
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                        ),
                ),

                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        food.foodName ?? 'Unnamed',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        priceText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isVeg ? Icons.circle : Icons.change_circle,
                            size: 10,
                            color: isVeg ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            dietaryType,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.75),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text("Add"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => controller.addToOrder(food),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  // Simple skeleton grid (no extra packages)
  Widget _buildFoodSkeleton(ThemeData theme, double width) {
    final crossAxisCount = width >= 1200 ? 4 : (width >= 800 ? 3 : 2);
    final baseColor = theme.colorScheme.surfaceContainerHighest.withOpacity(
      0.4,
    );
    final onBase = theme.colorScheme.onSurface.withOpacity(0.06);

    return MasonryGridView.count(
      padding: const EdgeInsets.all(12),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      itemCount: 8,
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(height: 120, color: baseColor),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Container(height: 18, width: 140, color: baseColor),
                    const SizedBox(height: 8),
                    Container(height: 14, width: 80, color: baseColor),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(height: 10, width: 10, color: baseColor),
                        const SizedBox(width: 6),
                        Container(height: 12, width: 50, color: baseColor),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: onBase,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
