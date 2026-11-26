import 'dart:convert';

/// _id : "688b28b73744e17a68ffabb7"
/// shortCode : "GRLD-CHKN"
/// itemName : {"en":"Grilled Chicken","hi":"ग्रिल्ड चिकन"}
/// hsnCode : "9986"
/// currentStock : 30
/// baseItemPrice : 249
/// itemType : "Menu Item"
/// categoryId : "688a7ba8c9630f57d7f815d7"
/// subCategoryId : null
/// foodType : "NON_VEG"
/// taxProductGroupId : "688a9999c9630f57d7f81600"
/// kitchenDepartmentId : "688a7e4fc9630f57d7f815e8"
/// description : {"en":"Juicy grilled chicken with BBQ spices.","hi":"बीबीक्यू मसालों के साथ रसदार ग्रिल्ड चिकन।"}
/// isActive : true
/// isRecommended : true
/// posStatus : true
/// platformStatus : true
/// digitalDiscount : false
/// discountType : null
/// discountedPrice : null
/// syncToAggregator : false
/// alternativeTitle : null
/// preparationTime : 15
/// openItem : false
/// openPrice : false
/// itemSortOrder : 1
/// isCombo : false
/// images : []
/// primaryImage : null
/// brandId : "68835e6ba989161d1ae66089"
/// restaurantId : "68889f3c3a816833d5c58247"
/// multiplePrices : [{"orderTypeId":"688a767cc9630f57d7f815b6","tableSectionId":"688a7b14c9630f57d7f815cf","price":249},{"orderTypeId":"688a767cc9630f57d7f815b7","tableSectionId":"688a7b14c9630f57d7f815d0","price":239},{"orderTypeId":"688a767cc9630f57d7f815b8","tableSectionId":"688a7b14c9630f57d7f815d1","price":229}]
/// createdBy : "688a7056c9630f57d7f8157d"
/// updatedBy : "688a7056c9630f57d7f8157d"
/// deletedBy : null
/// deletedAt : null

ModelFoodMenu modelFoodMenuFromJson(String str) =>
    ModelFoodMenu.fromJson(json.decode(str));
String modelFoodMenuToJson(ModelFoodMenu data) => json.encode(data.toJson());

class ModelFoodMenu {
  ModelFoodMenu({
    String? id,
    String? shortCode,
    ItemName? itemName,
    String? hsnCode,
    num? currentStock,
    num? baseItemPrice,
    String? itemType,
    String? categoryId,
    dynamic subCategoryId,
    String? foodType,
    String? taxProductGroupId,
    String? kitchenDepartmentId,
    Description? description,
    bool? isActive,
    bool? isRecommended,
    bool? posStatus,
    bool? platformStatus,
    bool? digitalDiscount,
    dynamic discountType,
    dynamic discountedPrice,
    bool? syncToAggregator,
    dynamic alternativeTitle,
    num? preparationTime,
    bool? openItem,
    bool? openPrice,
    num? itemSortOrder,
    bool? isCombo,
    List<dynamic>? images,
    dynamic primaryImage,
    String? brandId,
    String? restaurantId,
    List<MultiplePrices>? multiplePrices,
    String? createdBy,
    String? updatedBy,
    dynamic deletedBy,
    dynamic deletedAt,
  }) {
    _id = id;
    _shortCode = shortCode;
    _itemName = itemName;
    _hsnCode = hsnCode;
    _currentStock = currentStock;
    _baseItemPrice = baseItemPrice;
    _itemType = itemType;
    _categoryId = categoryId;
    _subCategoryId = subCategoryId;
    _foodType = foodType;
    _taxProductGroupId = taxProductGroupId;
    _kitchenDepartmentId = kitchenDepartmentId;
    _description = description;
    _isActive = isActive;
    _isRecommended = isRecommended;
    _posStatus = posStatus;
    _platformStatus = platformStatus;
    _digitalDiscount = digitalDiscount;
    _discountType = discountType;
    _discountedPrice = discountedPrice;
    _syncToAggregator = syncToAggregator;
    _alternativeTitle = alternativeTitle;
    _preparationTime = preparationTime;
    _openItem = openItem;
    _openPrice = openPrice;
    _itemSortOrder = itemSortOrder;
    _isCombo = isCombo;
    _images = images;
    _primaryImage = primaryImage;
    _brandId = brandId;
    _restaurantId = restaurantId;
    _multiplePrices = multiplePrices;
    _createdBy = createdBy;
    _updatedBy = updatedBy;
    _deletedBy = deletedBy;
    _deletedAt = deletedAt;
  }

  ModelFoodMenu.fromJson(dynamic json) {
    _id = json['_id'];
    _shortCode = json['shortCode'];
    _itemName = json['itemName'] != null
        ? ItemName.fromJson(json['itemName'])
        : null;
    _hsnCode = json['hsnCode'];
    _currentStock = json['currentStock'];
    _baseItemPrice = json['baseItemPrice'];
    _itemType = json['itemType'];
    _categoryId = json['categoryId'];
    _subCategoryId = json['subCategoryId'];
    _foodType = json['foodType'];
    _taxProductGroupId = json['taxProductGroupId'];
    _kitchenDepartmentId = json['kitchenDepartmentId'];
    _description = json['description'] != null
        ? Description.fromJson(json['description'])
        : null;
    _isActive = json['isActive'];
    _isRecommended = json['isRecommended'];
    _posStatus = json['posStatus'];
    _platformStatus = json['platformStatus'];
    _digitalDiscount = json['digitalDiscount'];
    _discountType = json['discountType'];
    _discountedPrice = json['discountedPrice'];
    _syncToAggregator = json['syncToAggregator'];
    _alternativeTitle = json['alternativeTitle'];
    _preparationTime = json['preparationTime'];
    _openItem = json['openItem'];
    _openPrice = json['openPrice'];
    _itemSortOrder = json['itemSortOrder'];
    _isCombo = json['isCombo'];
    if (json['images'] != null) {
      _images = [];
      json['images'].forEach((v) {
        _images?.add(dynamic.fromJson(v));
      });
    }
    _primaryImage = json['primaryImage'];
    _brandId = json['brandId'];
    _restaurantId = json['restaurantId'];
    if (json['multiplePrices'] != null) {
      _multiplePrices = [];
      json['multiplePrices'].forEach((v) {
        _multiplePrices?.add(MultiplePrices.fromJson(v));
      });
    }
    _createdBy = json['createdBy'];
    _updatedBy = json['updatedBy'];
    _deletedBy = json['deletedBy'];
    _deletedAt = json['deletedAt'];
  }
  String? _id;
  String? _shortCode;
  ItemName? _itemName;
  String? _hsnCode;
  num? _currentStock;
  num? _baseItemPrice;
  String? _itemType;
  String? _categoryId;
  dynamic _subCategoryId;
  String? _foodType;
  String? _taxProductGroupId;
  String? _kitchenDepartmentId;
  Description? _description;
  bool? _isActive;
  bool? _isRecommended;
  bool? _posStatus;
  bool? _platformStatus;
  bool? _digitalDiscount;
  dynamic _discountType;
  dynamic _discountedPrice;
  bool? _syncToAggregator;
  dynamic _alternativeTitle;
  num? _preparationTime;
  bool? _openItem;
  bool? _openPrice;
  num? _itemSortOrder;
  bool? _isCombo;
  List<dynamic>? _images;
  dynamic _primaryImage;
  String? _brandId;
  String? _restaurantId;
  List<MultiplePrices>? _multiplePrices;
  String? _createdBy;
  String? _updatedBy;
  dynamic _deletedBy;
  dynamic _deletedAt;
  ModelFoodMenu copyWith({
    String? id,
    String? shortCode,
    ItemName? itemName,
    String? hsnCode,
    num? currentStock,
    num? baseItemPrice,
    String? itemType,
    String? categoryId,
    dynamic subCategoryId,
    String? foodType,
    String? taxProductGroupId,
    String? kitchenDepartmentId,
    Description? description,
    bool? isActive,
    bool? isRecommended,
    bool? posStatus,
    bool? platformStatus,
    bool? digitalDiscount,
    dynamic discountType,
    dynamic discountedPrice,
    bool? syncToAggregator,
    dynamic alternativeTitle,
    num? preparationTime,
    bool? openItem,
    bool? openPrice,
    num? itemSortOrder,
    bool? isCombo,
    List<dynamic>? images,
    dynamic primaryImage,
    String? brandId,
    String? restaurantId,
    List<MultiplePrices>? multiplePrices,
    String? createdBy,
    String? updatedBy,
    dynamic deletedBy,
    dynamic deletedAt,
  }) => ModelFoodMenu(
    id: id ?? _id,
    shortCode: shortCode ?? _shortCode,
    itemName: itemName ?? _itemName,
    hsnCode: hsnCode ?? _hsnCode,
    currentStock: currentStock ?? _currentStock,
    baseItemPrice: baseItemPrice ?? _baseItemPrice,
    itemType: itemType ?? _itemType,
    categoryId: categoryId ?? _categoryId,
    subCategoryId: subCategoryId ?? _subCategoryId,
    foodType: foodType ?? _foodType,
    taxProductGroupId: taxProductGroupId ?? _taxProductGroupId,
    kitchenDepartmentId: kitchenDepartmentId ?? _kitchenDepartmentId,
    description: description ?? _description,
    isActive: isActive ?? _isActive,
    isRecommended: isRecommended ?? _isRecommended,
    posStatus: posStatus ?? _posStatus,
    platformStatus: platformStatus ?? _platformStatus,
    digitalDiscount: digitalDiscount ?? _digitalDiscount,
    discountType: discountType ?? _discountType,
    discountedPrice: discountedPrice ?? _discountedPrice,
    syncToAggregator: syncToAggregator ?? _syncToAggregator,
    alternativeTitle: alternativeTitle ?? _alternativeTitle,
    preparationTime: preparationTime ?? _preparationTime,
    openItem: openItem ?? _openItem,
    openPrice: openPrice ?? _openPrice,
    itemSortOrder: itemSortOrder ?? _itemSortOrder,
    isCombo: isCombo ?? _isCombo,
    images: images ?? _images,
    primaryImage: primaryImage ?? _primaryImage,
    brandId: brandId ?? _brandId,
    restaurantId: restaurantId ?? _restaurantId,
    multiplePrices: multiplePrices ?? _multiplePrices,
    createdBy: createdBy ?? _createdBy,
    updatedBy: updatedBy ?? _updatedBy,
    deletedBy: deletedBy ?? _deletedBy,
    deletedAt: deletedAt ?? _deletedAt,
  );
  String? get id => _id;
  String? get shortCode => _shortCode;
  ItemName? get itemName => _itemName;
  String? get hsnCode => _hsnCode;
  num? get currentStock => _currentStock;
  num? get baseItemPrice => _baseItemPrice;
  String? get itemType => _itemType;
  String? get categoryId => _categoryId;
  dynamic get subCategoryId => _subCategoryId;
  String? get foodType => _foodType;
  String? get taxProductGroupId => _taxProductGroupId;
  String? get kitchenDepartmentId => _kitchenDepartmentId;
  Description? get description => _description;
  bool? get isActive => _isActive;
  bool? get isRecommended => _isRecommended;
  bool? get posStatus => _posStatus;
  bool? get platformStatus => _platformStatus;
  bool? get digitalDiscount => _digitalDiscount;
  dynamic get discountType => _discountType;
  dynamic get discountedPrice => _discountedPrice;
  bool? get syncToAggregator => _syncToAggregator;
  dynamic get alternativeTitle => _alternativeTitle;
  num? get preparationTime => _preparationTime;
  bool? get openItem => _openItem;
  bool? get openPrice => _openPrice;
  num? get itemSortOrder => _itemSortOrder;
  bool? get isCombo => _isCombo;
  List<dynamic>? get images => _images;
  dynamic get primaryImage => _primaryImage;
  String? get brandId => _brandId;
  String? get restaurantId => _restaurantId;
  List<MultiplePrices>? get multiplePrices => _multiplePrices;
  String? get createdBy => _createdBy;
  String? get updatedBy => _updatedBy;
  dynamic get deletedBy => _deletedBy;
  dynamic get deletedAt => _deletedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = _id;
    map['shortCode'] = _shortCode;
    if (_itemName != null) {
      map['itemName'] = _itemName?.toJson();
    }
    map['hsnCode'] = _hsnCode;
    map['currentStock'] = _currentStock;
    map['baseItemPrice'] = _baseItemPrice;
    map['itemType'] = _itemType;
    map['categoryId'] = _categoryId;
    map['subCategoryId'] = _subCategoryId;
    map['foodType'] = _foodType;
    map['taxProductGroupId'] = _taxProductGroupId;
    map['kitchenDepartmentId'] = _kitchenDepartmentId;
    if (_description != null) {
      map['description'] = _description?.toJson();
    }
    map['isActive'] = _isActive;
    map['isRecommended'] = _isRecommended;
    map['posStatus'] = _posStatus;
    map['platformStatus'] = _platformStatus;
    map['digitalDiscount'] = _digitalDiscount;
    map['discountType'] = _discountType;
    map['discountedPrice'] = _discountedPrice;
    map['syncToAggregator'] = _syncToAggregator;
    map['alternativeTitle'] = _alternativeTitle;
    map['preparationTime'] = _preparationTime;
    map['openItem'] = _openItem;
    map['openPrice'] = _openPrice;
    map['itemSortOrder'] = _itemSortOrder;
    map['isCombo'] = _isCombo;
    if (_images != null) {
      map['images'] = _images?.map((v) => v.toJson()).toList();
    }
    map['primaryImage'] = _primaryImage;
    map['brandId'] = _brandId;
    map['restaurantId'] = _restaurantId;
    if (_multiplePrices != null) {
      map['multiplePrices'] = _multiplePrices?.map((v) => v.toJson()).toList();
    }
    map['createdBy'] = _createdBy;
    map['updatedBy'] = _updatedBy;
    map['deletedBy'] = _deletedBy;
    map['deletedAt'] = _deletedAt;
    return map;
  }
}

extension on Type {
  fromJson(v) {}
}

/// orderTypeId : "688a767cc9630f57d7f815b6"
/// tableSectionId : "688a7b14c9630f57d7f815cf"
/// price : 249

MultiplePrices multiplePricesFromJson(String str) =>
    MultiplePrices.fromJson(json.decode(str));
String multiplePricesToJson(MultiplePrices data) => json.encode(data.toJson());

class MultiplePrices {
  MultiplePrices({String? orderTypeId, String? tableSectionId, num? price}) {
    _orderTypeId = orderTypeId;
    _tableSectionId = tableSectionId;
    _price = price;
  }

  MultiplePrices.fromJson(dynamic json) {
    _orderTypeId = json['orderTypeId'];
    _tableSectionId = json['tableSectionId'];
    _price = json['price'];
  }
  String? _orderTypeId;
  String? _tableSectionId;
  num? _price;
  MultiplePrices copyWith({
    String? orderTypeId,
    String? tableSectionId,
    num? price,
  }) => MultiplePrices(
    orderTypeId: orderTypeId ?? _orderTypeId,
    tableSectionId: tableSectionId ?? _tableSectionId,
    price: price ?? _price,
  );
  String? get orderTypeId => _orderTypeId;
  String? get tableSectionId => _tableSectionId;
  num? get price => _price;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['orderTypeId'] = _orderTypeId;
    map['tableSectionId'] = _tableSectionId;
    map['price'] = _price;
    return map;
  }
}

/// en : "Juicy grilled chicken with BBQ spices."
/// hi : "बीबीक्यू मसालों के साथ रसदार ग्रिल्ड चिकन।"

Description descriptionFromJson(String str) =>
    Description.fromJson(json.decode(str));
String descriptionToJson(Description data) => json.encode(data.toJson());

class Description {
  Description({String? en, String? hi}) {
    _en = en;
    _hi = hi;
  }

  Description.fromJson(dynamic json) {
    _en = json['en'];
    _hi = json['hi'];
  }
  String? _en;
  String? _hi;
  Description copyWith({String? en, String? hi}) =>
      Description(en: en ?? _en, hi: hi ?? _hi);
  String? get en => _en;
  String? get hi => _hi;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['en'] = _en;
    map['hi'] = _hi;
    return map;
  }
}

/// en : "Grilled Chicken"
/// hi : "ग्रिल्ड चिकन"

ItemName itemNameFromJson(String str) => ItemName.fromJson(json.decode(str));
String itemNameToJson(ItemName data) => json.encode(data.toJson());

class ItemName {
  ItemName({String? en, String? hi}) {
    _en = en;
    _hi = hi;
  }

  ItemName.fromJson(dynamic json) {
    _en = json['en'];
    _hi = json['hi'];
  }
  String? _en;
  String? _hi;
  ItemName copyWith({String? en, String? hi}) =>
      ItemName(en: en ?? _en, hi: hi ?? _hi);
  String? get en => _en;
  String? get hi => _hi;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['en'] = _en;
    map['hi'] = _hi;
    return map;
  }
}
