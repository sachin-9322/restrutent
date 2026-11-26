// services/excel_import_service.dart
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:splash_screen_03/model/entity_cateogry_tax.dart'; // New Import
import 'package:splash_screen_03/model/entity_food.dart';
import 'package:splash_screen_03/model/entity_price.dart';
import 'package:splash_screen_03/model/entity_room_type.dart'; // New Import
import 'package:splash_screen_03/objectbox.g.dart';
import 'package:splash_screen_03/screens/home/fragments/category_type/controller_category.dart';
import 'package:splash_screen_03/screens/home/fragments/food_type/controller_food.dart';
import 'package:splash_screen_03/screens/home/fragments/room_type/controller_room.dart';
// Adjust paths if they differ in your project structure

class ExcelImportResult {
  final int imported;
  final int skipped;
  final List<String> errors;
  ExcelImportResult({
    required this.imported,
    required this.skipped,
    required this.errors,
  });
}

class ExcelImportService {
  /// Open file picker and import
  static Future<ExcelImportResult?> pickAndImport(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.isEmpty) return null;
      final file = File(result.files.single.path!);
      return await importFromFile(context, file);
    } catch (e) {
      debugPrint("Excel pick error: $e");
      rethrow;
    }
  }

  /// Import given file and return summary
  static Future<ExcelImportResult> importFromFile(
      BuildContext context, File file) async {
    final errors = <String>[];
    int imported = 0;
    int skipped = 0;
    // Flags to check if we need to refresh controllers
    bool newCategoriesAdded = false;
    bool newRoomTypesAdded = false;

    try {
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      final sheetName = excel.sheets.keys.first;
      final sheet = excel.sheets[sheetName];
      if (sheet == null) throw Exception("No sheets found in the workbook.");

      final header = <String>[];
      final headerRow = sheet.row(0);
      for (final cell in headerRow) {
        header.add(cell?.value?.toString().trim() ?? "");
      }

      String normalize(String s) =>
          s.toLowerCase().replaceAll(RegExp(r'[_\s]'), '');
      final Map<String, int> headerIndex = {};
      for (var i = 0; i < header.length; i++) {
        headerIndex[normalize(header[i])] = i;
      }

      int? findIndex(List<String> alternatives) {
        for (final alt in alternatives) {
          final n = normalize(alt);
          if (headerIndex.containsKey(n)) return headerIndex[n];
        }
        return null;
      }

      final foodNameIdx = findIndex(['foodname', 'title', 'name']);
      final categoryIdx =
          findIndex(['categoryname', 'category', 'on category', 'oncategory']);
      if (foodNameIdx == null || categoryIdx == null) {
        throw Exception(
            'Missing required columns. Required: foodName (or title/name) and categoryName (or category).');
      }

      // Get all required ObjectBox boxes
      final Box<EntityFood> boxEntityFood = Get.find<Box<EntityFood>>();
      final Box<EntityCategoryTax> boxEntityCategory = Get.find<Box<EntityCategoryTax>>();
      final Box<EntityRoomType> boxEntityRoomType = Get.find<Box<EntityRoomType>>();

      // iterate rows starting from 1
      for (var r = 1; r <= sheet.maxRows; r++) {
        final row = sheet.row(r);

        if (row.every((c) => (c?.value ?? '').toString().trim().isEmpty)) {
          continue;
        }

        try {
          String getCellByIndex(int? idx) {
            if (idx == null || idx >= row.length) return "";
            return row[idx]?.value?.toString().trim() ?? "";
          }

          String getCellByKeys(List<String> keys) {
            final idx = findIndex(keys);
            return getCellByIndex(idx);
          }

          final foodName = getCellByIndex(foodNameIdx);
          final categoryName = getCellByIndex(categoryIdx);

          if (foodName.isEmpty || categoryName.isEmpty) {
            skipped++;
            errors.add(
                "Row ${r + 1}: missing required fields (foodName/categoryName)");
            continue;
          }

          // **NEW**: Check and create category if it doesn't exist
          final existingCategory = boxEntityCategory
              .query(EntityCategoryTax_.categoryName.equals(categoryName.trim(), caseSensitive: false))
              .build()
              .findFirst();

          if (existingCategory == null) {
            final newCategory = EntityCategoryTax(
              categoryName: categoryName.trim(),
            );
            boxEntityCategory.put(newCategory);
            newCategoriesAdded = true;
            errors.add("Row ${r + 1}: Created new category '${categoryName.trim()}'.");
          }

          // Get other cell values
          final shortCode = getCellByKeys(['shortcode', 'code']);
          final isVegStr = getCellByKeys(['isveg', 'is_veg', 'veg', 'vegetarian', 'foodtype']);
          final priceEntries = getCellByKeys(['price_entries', 'priceentries']);
          final salePriceStr = getCellByKeys(['sale price', 'saleprice', 'price', 'mrp', 'sale_price']);
          final currencyStr = getCellByKeys(['currency', 'currencycode', 'currency_code', 'cur']);
          final taxProductGroup = getCellByKeys(['tax product group', 'taxproductgroup', 'taxgroup']);
          final kitchenDepartment = getCellByKeys(['kitchendepartment', 'kitchen', 'department']);
          final stockStr = getCellByKeys(['stock', 'quantity', 'qty', 'instock']);


          // parse isVeg
          bool isVeg = true;
          if (isVegStr.isNotEmpty) {
            final low = isVegStr.toLowerCase();
            isVeg = !['false', 'no', '0', 'nonveg', 'non-veg', 'non veg', 'nveg', 'nonvegetarian', 'non vegetarian', 'non'].contains(low);
            if (!['true', 'yes', '1', 'veg', 'vegetarian', 'v'].contains(low) && !isVeg) {
                errors.add("Row ${r + 1}: ambiguous isVeg/foodtype value '$isVegStr' - defaulting to Veg");
            }
          }

          // Parse stock value
          double? stock;
          if (stockStr.isNotEmpty) {
            stock = double.tryParse(stockStr.replaceAll(',', ''));
            if (stock == null) {
              errors.add("Row ${r + 1}: could not parse stock value '$stockStr' - stock will be set to null.");
            }
          }

          // create EntityFood
          final newFood = EntityFood(
            categoryName: categoryName,
            foodName: foodName,
            isVeg: isVeg,
            shortCode: shortCode.isEmpty ? null : shortCode,
            isActive: true, // Imported items are active by default
          );

          if (kitchenDepartment.isNotEmpty) newFood.kitchenDepartment = kitchenDepartment;
          if (stock != null) newFood.stock = stock;

          // **NEW**: Helper function to create RoomType if it doesn't exist
          void checkAndCreateRoomType(String roomTypeName) {
            if (roomTypeName.isEmpty) return;
            final existingRoomType = boxEntityRoomType
                .query(EntityRoomType_.name.equals(roomTypeName.trim(), caseSensitive: false))
                .build()
                .findFirst();
            if (existingRoomType == null) {
              final newRoomType = EntityRoomType(
                name: roomTypeName.trim(),
                isActive: true, // New room types are active by default
              );
              boxEntityRoomType.put(newRoomType);
              newRoomTypesAdded = true;
              errors.add("Row ${r + 1}: Created new room type '${roomTypeName.trim()}'.");
            }
          }

          // parse price entries
          final priceList = <EntityPrice>[];
          if (priceEntries.isNotEmpty) {
            final parts = priceEntries.split('|');
            for (final part in parts) {
              if (part.trim().isEmpty) continue;
              final seg = part.split(':');
              if (seg.length < 2) {
                errors.add("Row ${r + 1}: invalid price entry '$part'");
                continue;
              }
              final roomType = seg[0].trim();
              checkAndCreateRoomType(roomType); // Create if not exists

              final priceStr = seg[1].trim();
              final currency = seg.length >= 3 ? seg[2].trim() : 'INR';
              final parsedPrice = double.tryParse(priceStr.replaceAll(',', ''));
              if (parsedPrice == null) {
                errors.add("Row ${r + 1}: invalid price number '$priceStr' in entry '$part'");
                continue;
              }
              priceList.add(EntityPrice(roomType: roomType, price: parsedPrice, currency: currency));
            }
          } else if (salePriceStr.isNotEmpty) {
            const saleRoomTypeName = 'Sale';
            checkAndCreateRoomType(saleRoomTypeName); // Create "Sale" room type if not exists
            
            final parsedPrice = double.tryParse(salePriceStr.replaceAll(',', ''));
            if (parsedPrice != null) {
              final currency = currencyStr.isNotEmpty ? currencyStr : 'INR';
              priceList.add(EntityPrice(roomType: saleRoomTypeName, price: parsedPrice, currency: currency));
            } else {
              
              // Attempt to extract numeric part if mixed with currency symbols etc.
              final numeric = RegExp(r'[\d,.]+').stringMatch(salePriceStr) ?? '';
              final parsed2 = double.tryParse(numeric.replaceAll(',', ''));
              if (parsed2 != null) {
                final currency = currencyStr.isNotEmpty ? currencyStr : (salePriceStr.replaceAll(numeric, '').trim().isNotEmpty ? salePriceStr.replaceAll(numeric, '').trim() : 'INR');
                priceList.add(EntityPrice(roomType: saleRoomTypeName, price: parsed2, currency: currency));
              } else {
                errors.add("Row ${r + 1}: could not parse sale/price column value '$salePriceStr'");
              }
            }
          }

          newFood.price.addAll(priceList);

          if (taxProductGroup.isNotEmpty) {
            errors.add("Row ${r + 1}: found tax product group '$taxProductGroup' (not mapped to model).");
          }

          boxEntityFood.put(newFood);
          imported++;
        } catch (rowEx) {
          skipped++;
          errors.add("Row ${r + 1}: ${rowEx.toString()}");
        }
      }

      // **UPDATED**: Refresh all relevant controllers
      if (Get.isRegistered<ControllerFood>()) {
        try { Get.find<ControllerFood>().refreshFoodData(); } catch (_) {}
      }
      if (newCategoriesAdded && Get.isRegistered<ControllerCategory>()) {
        try { Get.find<ControllerCategory>().fetchDataFromCategory(); } catch (_) {}
      }
      if (newRoomTypesAdded && Get.isRegistered<ControllerRoom>()) {
        try { Get.find<ControllerRoom>().fetchRoomType(); } catch (_) {}
      }

    } catch (e) {
      debugPrint("Import error: $e");
      rethrow;
    }

    return ExcelImportResult(imported: imported, skipped: skipped, errors: errors);
  }
}