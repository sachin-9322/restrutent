import 'package:objectbox/objectbox.dart';
import 'package:splash_screen_03/model/entity_kitchen_department.dart';
import 'package:splash_screen_03/model/entity_tax.dart';
import 'package:uuid/uuid.dart';
import 'entity_name.dart';
import 'entity_price.dart';

@Entity()
class EntityFood {
  @Id()
  int foodId = 0;

  String? mongoId;

  String? shortCode;
  String? categoryName;
  String? foodDescription;
  bool? isVeg;
  String? foodType;
  bool? isActive;
  double? prepTime;
  String? hsnCode;
  int? sortIndex;

  // We store the primary image as Base64 (also mirrored in imgPath)
  List<String>? images; // first image is base64
  String? imgPath; // also base64 for compatibility

  String? foodName;
  bool? isRecommended;
  String? kitchenDepartment;
  String? opentItem;
  bool? isSync;
  String? menu;
  double? discountPrice;
  int qty;

  /// Stock quantity
  double? stock;

  @Unique()
  late String foodUuid;

  ToOne<EntityName> name = ToOne();
  ToOne<EntityTax> tax = ToOne();
  ToMany<EntityPrice> price = ToMany();
  ToOne<EntityKitchenDepartment> kitchen = ToOne();

  EntityFood({
    this.mongoId,
    this.foodType,
    this.hsnCode,
    this.sortIndex,
    this.isRecommended = false,
    this.foodDescription,
    this.prepTime,
    this.shortCode,
    required this.foodName,
    this.isVeg = true,
    this.isActive = true,
    this.images,
    this.foodId = 0,
    this.categoryName,
    this.kitchenDepartment,
    this.opentItem,
    this.imgPath,
    this.isSync,
    this.menu,
    this.discountPrice,
    this.qty = 0,
    this.stock,
  }) : foodUuid = const Uuid().v4();

  Map<String, dynamic> toJsonSimple() {
    return {
      "_id": mongoId,
      "foodId": foodId,
      "foodUuid": foodUuid,
      "foodName": foodName ?? "",
      "category": categoryName ?? "",
      "isVeg": isVeg ?? true,
      "foodType": foodType ?? "",
      "kitchenDepartment": kitchenDepartment ?? "",
      "opentItem": opentItem ?? "",
      "imgPath": imgPath ?? "", // base64
      "isSync": isSync ?? false,
      "menu": menu ?? "",
      "discountPrice": discountPrice ?? 0.0,
      "qty": qty,
      "stock": stock ?? 0.0,
      "prepTime": prepTime ?? 0.0,
      "isRecommended": isRecommended ?? false,
      "isActive": isActive ?? true,
      "hsnCode": hsnCode ?? "",
      "sortIndex": sortIndex ?? 0,
    };
  }

  static EntityFood fromJson(Map<String, dynamic> item) {
    // DEBUG: Print tax group ID from JSON
    if (item.containsKey('taxProductGroupId')) {
      print(
        "🍔 Item: ${item['itemName']?['en']} | taxProductGroupId: ${item['taxProductGroupId']}",
      );
    } else {
      print("⚠️ Item: ${item['itemName']?['en']} | MISSING taxProductGroupId");
    }

    final food = EntityFood(
      mongoId:
          item['_id']?.toString() ??
          item['id']?.toString() ??
          item['_mongoId']?.toString(),

      shortCode: item['shortCode']?.toString() ?? "",
      foodName: item['itemName']?['en'] ?? "",
      categoryName: item['categoryName']?['en'] ?? "",
      foodType: item['foodType']?.toString() ?? "",
      isVeg: (item['foodType']?.toString().toUpperCase() ?? "") == "VEG",
      isActive: item['isActive'] ?? true,
      foodDescription: "",
      prepTime: 0,
      hsnCode:
          item['taxProductGroupId']?.toString() ?? "", // ✅ Store tax group ID

      sortIndex: 0,
      images: (item['images'] != null && item['images'] is List)
          ? List<String>.from(item['images'])
          : [],
      imgPath:
          (item['images'] != null &&
              item['images'] is List &&
              item['images'].isNotEmpty)
          ? item['images'][0]
          : "",
      kitchenDepartment: item['kitchenDepartmentName']?['en'] ?? "",
      opentItem: "",
      isSync: true,
      menu: item['menuName']?['en'] ?? "",
      discountPrice: 0,
      qty: 0,
      stock: (item['currentStock'] ?? 0).toDouble(),
    );

    // Price Mapping
    if (item['multiplePrices'] != null && item['multiplePrices'] is List) {
      for (var p in item['multiplePrices']) {
        double priceValue = (p['price'] ?? 0).toDouble();
        if (priceValue > 0) {
          food.price.add(
            EntityPrice(
              price: priceValue,
              offerPrice: priceValue,
              roomType: '',
              currency: '',
            ),
          );
        }
      }
    } else if (item['baseItemPrice'] != null) {
      double priceValue = (item['baseItemPrice'] ?? 0).toDouble();
      food.price.add(
        EntityPrice(
          price: priceValue,
          offerPrice: priceValue,
          roomType: '',
          currency: '',
        ),
      );
    }

    return food;
  }
}
