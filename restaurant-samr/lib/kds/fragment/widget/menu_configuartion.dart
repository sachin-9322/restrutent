import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/model/entity_food.dart';
import 'package:splash_screen_03/objectbox.g.dart';

// --- CONTROLLER FOR STATE MANAGEMENT ---
class MenuController extends GetxController {
  final Box<EntityFood> boxFood = Get.find<Box<EntityFood>>();

  final RxMap<String, List<EntityFood>> categorizedFoods =
      <String, List<EntityFood>>{}.obs;
  final RxMap<int, bool> toggleStates = <int, bool>{}.obs;
  final TextEditingController searchController = TextEditingController();
  RxMap<String, List<EntityFood>> filteredCategorizedFoods =
      <String, List<EntityFood>>{}.obs;

  // Dark/Light theme state
  final isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    _groupFoods();
    searchController.addListener(_filterFoods);
  }

  @override
  void onClose() {
    searchController.removeListener(_filterFoods);
    searchController.dispose();
    super.onClose();
  }

  void _groupFoods() {
    final allFoods = boxFood.getAll();
    final grouped = <String, List<EntityFood>>{};

    for (final food in allFoods) {
      final category = food.categoryName?.isNotEmpty == true
          ? food.categoryName!
          : "Uncategorized";
      grouped.putIfAbsent(category, () => []).add(food);
      toggleStates[food.foodId] = food.isActive ?? true;
    }

    categorizedFoods.assignAll(grouped);
    _filterFoods();
  }

  void _filterFoods() {
    final query = searchController.text.toLowerCase();
    if (query.isEmpty) {
      filteredCategorizedFoods.assignAll(categorizedFoods);
      return;
    }

    final filtered = <String, List<EntityFood>>{};
    categorizedFoods.forEach((category, foods) {
      final filteredFoods = foods
          .where((food) => food.foodName!.toLowerCase().contains(query))
          .toList();
      if (category.toLowerCase().contains(query) || filteredFoods.isNotEmpty) {
        filtered[category] = category.toLowerCase().contains(query)
            ? foods
            : filteredFoods;
      }
    });

    filteredCategorizedFoods.assignAll(filtered);
  }

  void toggleFoodItem(int foodId, bool isActive) =>
      toggleStates[foodId] = isActive;

  void toggleCategory(String category, bool isActive) {
    final foodsInCategory = categorizedFoods[category] ?? [];
    for (final food in foodsInCategory) toggleStates[food.foodId] = isActive;
  }

  bool isCategoryActive(String category) {
    final foodsInCategory = categorizedFoods[category] ?? [];
    if (foodsInCategory.isEmpty) return false;
    return foodsInCategory.every((food) => toggleStates[food.foodId] ?? false);
  }

  void saveChanges() {
    final List<EntityFood> foodsToUpdate = [];
    final allFoods = boxFood.getAll();

    for (var food in allFoods) {
      final newActiveState = toggleStates[food.foodId] ?? true;

      // Only update the isActive field in the database
      if (food.isActive != newActiveState) {
        food.isActive = newActiveState;
        foodsToUpdate.add(food);
      }
    }

    if (foodsToUpdate.isNotEmpty) boxFood.putMany(foodsToUpdate);

    Get.snackbar(
      "Success",
      "Menu configuration updated successfully!",
      backgroundColor: Colors.green.shade700,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    Get.changeTheme(isDarkMode.value ? ThemeData.dark() : ThemeData.light());
  }
}

// --- MENU CONFIGURATION SCREEN ---
class MenuConfigurationScreen extends StatelessWidget {
  const MenuConfigurationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MenuController());
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        title: const Text(
          "Menu Configuration",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 1.0,
        actions: [
          IconButton(
            icon: Obx(() {
              final theme = Theme.of(context);
              return Icon(
                controller.isDarkMode.value
                    ? Icons.dark_mode
                    : Icons.light_mode,
                color: theme.iconTheme.color,
              );
            }),
            onPressed: controller.toggleTheme,
          ),
          TextButton(
            onPressed: controller.saveChanges,
            child: const Text(
              "Update",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                hintText: "Search items or categories...",
                filled: true,
                fillColor: theme.cardColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.filteredCategorizedFoods.isEmpty) {
                return Center(
                  child: Text(
                    "No items found",
                    style: TextStyle(color: theme.disabledColor),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: controller.filteredCategorizedFoods.keys.length,
                itemBuilder: (context, index) {
                  final category = controller.filteredCategorizedFoods.keys
                      .elementAt(index);
                  final items = controller.filteredCategorizedFoods[category]!;
                  return CategoryCard(
                    category: category,
                    items: items,
                    controller: controller,
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

// --- CATEGORY CARD ---
class CategoryCard extends StatelessWidget {
  final String category;
  final List<EntityFood> items;
  final MenuController controller;

  const CategoryCard({
    super.key,
    required this.category,
    required this.items,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Obx(
                  () => Switch.adaptive(
                    value: controller.isCategoryActive(category),
                    onChanged: (newValue) =>
                        controller.toggleCategory(category, newValue),
                    activeColor: Colors.white,
                    activeTrackColor: Colors.green.shade300,
                    inactiveThumbColor: Colors.grey.shade400,
                    inactiveTrackColor: Colors.grey.shade200,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: items
                  .map(
                    (food) => FoodItemChip(food: food, controller: controller),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// --- FOOD ITEM CHIP ---
class FoodItemChip extends StatelessWidget {
  final EntityFood food;
  final MenuController controller;

  const FoodItemChip({super.key, required this.food, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final chipWidth = (screenWidth - 24 - 24 - 10) / 2;

    return Container(
      width: chipWidth,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              food.foodName ?? '',
              style: TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Obx(
            () => Switch.adaptive(
              value: controller.toggleStates[food.foodId] ?? true,
              onChanged: (newValue) =>
                  controller.toggleFoodItem(food.foodId, newValue),
              activeColor: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }
}