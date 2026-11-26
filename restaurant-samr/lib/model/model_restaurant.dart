class ModelRestaurant {
  String? restUuid;
  String? name;
  String? address;
  String? mobileNumber;
  String? email;
  String? gstNumber;
  String? fssaiLicense;
  String? logo;
  String? brandName;

  ModelRestaurant({
    this.restUuid,
    this.name,
    this.address,
    this.mobileNumber,
    this.email,
    this.gstNumber,
    this.fssaiLicense,
    this.logo,
    this.brandName,
  });

  /// ✅ Converts object to Map (for local storage)
  Map<String, dynamic> toMap() {
    return {
      'restUuid': restUuid,
      'name': name,
      'address': address,
      'mobileNumber': mobileNumber,
      'email': email,
      'gstNumber': gstNumber,
      'fssaiLicense': fssaiLicense,
      'logo': logo,
      'brandName': brandName,
    };
  }

  /// ✅ Create from map (for local restore)
  factory ModelRestaurant.fromMap(Map<String, dynamic> map) {
    return ModelRestaurant(
      restUuid: map['restUuid'],
      name: map['name'],
      address: map['address'],
      mobileNumber: map['mobileNumber'],
      email: map['email'],
      gstNumber: map['gstNumber'],
      fssaiLicense: map['fssaiLicense'],
      logo: map['logo'],
      brandName: map['brandName'],
    );
  }

  /// ✅ Create directly from API JSON
  factory ModelRestaurant.fromApi(Map<String, dynamic> json) {
    final addressObj = json['address'] ?? {};
    final nameObj = json['name'] ?? {};
    final brandObj = json['brandName'] ?? {};

    return ModelRestaurant(
      restUuid: json['_id'] ?? '',
      name: nameObj['en'] ?? nameObj['ar'] ?? 'Unknown',
      address: [
        addressObj['addressLine1'],
        addressObj['addressLine2'],
        addressObj['city'],
        addressObj['state'],
        addressObj['country'],
        addressObj['pincode'],
      ].where((v) => v != null && v.toString().isNotEmpty).join(', '),
      mobileNumber:
          (json['notificationPhone'] is List && json['notificationPhone'].isNotEmpty)
              ? json['notificationPhone'][0]
              : '',
      email:
          (json['notificationEmails'] is List && json['notificationEmails'].isNotEmpty)
              ? json['notificationEmails'][0]
              : '',
      gstNumber: json['trnOrGstNo'] ?? '',
      fssaiLicense: json['fssaiLicense'] ?? '',
      logo: json['logo'] ?? '',
      brandName: brandObj['en'] ?? '',
    );
  }
}
