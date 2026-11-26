import 'dart:convert';

ModelFoodItem2 modelFoodItem2FromJson(String str) => ModelFoodItem2.fromJson(json.decode(str));

String modelFoodItem2ToJson(ModelFoodItem2 data) => json.encode(data.toJson());

class ModelFoodItem2 {
  ModelFoodItem2({
    num? id,
    String? name,
    String? description,
    num? price,
    String? category,
    bool? availability,
    num? totalCount,
    int? quantity,

  }) {
    _id = id;
    _name = name;
    _description = description;
    _price = price;
    _category = category;
    _availability = availability;
    _totalCount = totalCount;
    _quantity = quantity;
  }

  // ✅ FIXED: Safe from int/String → num/bool conversion issues
  ModelFoodItem2.fromJson(dynamic json) {
    _id = num.tryParse(json['id'].toString());
    _name = json['name']?.toString();
    _description = json['description']?.toString();
    _price = num.tryParse(json['price'].toString());
    _category = json['category']?.toString();
    _quantity = json['quantity']?.toString() as int?;

    // Safe availability parsing
    var avail = json['availability'];
    if (avail is bool) {
      _availability = avail;
    } else if (avail is int) {
      _availability = avail == 1;
    } else if (avail is String) {
      _availability = avail == '1' || avail.toLowerCase() == 'true';
    } else {
      _availability = null;
    }

    _totalCount = num.tryParse(json['totalCount'].toString());
  }

  num? _id;
  String? _name;
  String? _description;
  num? _price;
  String? _category;
  bool? _availability;
  num? _totalCount;
  int? _quantity;

  // Copy method (optional)
  ModelFoodItem2 copyWith({
    num? id,
    String? name,
    String? description,
    num? price,
    String? category,
    bool? availability,
    num? totalCount,
    int? quantity,
  }) =>
      ModelFoodItem2(
        id: id ?? _id,
        name: name ?? _name,
        description: description ?? _description,
        price: price ?? _price,
        category: category ?? _category,
        availability: availability ?? _availability,
        totalCount: totalCount ?? _totalCount,
        quantity: quantity?? _quantity,
      );

  // Getters
  num? get id => _id;
  String? get name => _name;
  String? get description => _description;
  num? get price => _price;
  String? get category => _category;
  bool? get availability => _availability;
  num? get totalCount => _totalCount;
  int? get quantity => _quantity;

  set quantity(int? value) {
    if(value != null){
    _quantity = value;}
    else
      {
         _quantity = 1;
      }
  }

  /*set quantity(int? value){
     if(value == null){
       _quantity = null;
     }
     else
       {
          _quantity = value ;
       }
  }*/


  // JSON converter
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['name'] = _name;
    map['description'] = _description;
    map['price'] = _price;
    map['category'] = _category;
    map['availability'] = _availability;
    map['totalCount'] = _totalCount;
    map['quantity'] = _quantity;
    return map;
  }
}
