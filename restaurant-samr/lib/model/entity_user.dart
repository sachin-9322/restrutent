import 'package:objectbox/objectbox.dart';
import 'package:uuid/uuid.dart';

@Entity()
class EntityUser {
  // ObjectBox internal ID
  @Id()
  int objectId = 0;

  // Your old field (KEEP IT - required by many screens)
  int userId = 0;

  // Real backend ID (NEW)
  int backendUserId = 0;

  String? userName; // stored lowercase
  String? userPassword;
  String? userType;
  String? first;
  String? last;
  String? countryCode;
  String? mobile;
  String? dob;
  String? gender;
  String? idProofKey;
  String? address;
  String? idProofValue;
  String? restaurantName;
  String? pin; // captain PIN

  @Unique()
  late String userUuid;

  EntityUser({
    required this.backendUserId,
    required this.userName,
    required this.userPassword,
    required this.userType,
    required this.first,
    required this.last,
    required this.countryCode,
    required this.mobile,
    required this.dob,
    required this.gender,
    this.idProofKey,
    this.idProofValue,
    this.address,
    this.pin,
    this.restaurantName,
    String? userUuid,
  }) : userUuid = userUuid ?? const Uuid().v4();
}

//
// ------------------------------------------------------------
// Mapper (FINAL)
// ------------------------------------------------------------
extension EntityUserMapper on EntityUser {
  static EntityUser fromJson(Map<String, dynamic> json) {
    final user = EntityUser(
      backendUserId: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userName: json['username']?.toString() ?? '',
      userPassword: '', // NEVER STORE API PASSWORD
      userType: json['role']?['name']?['en']?.toString() ?? '',
      first: '',
      last: '',
      countryCode: '',
      mobile: json['phone']?.toString() ?? '',
      dob: '',
      gender: '',
      address: json['company']?.toString() ?? '',
      restaurantName: json['company']?.toString() ?? '',
      pin: '',
    );

    // KEEP YOUR OLD FIELD FOR EXISTING SCREENS
    user.userId = int.tryParse(json['id']?.toString() ?? '0') ?? 0;

    return user;
  }

  Map<String, dynamic> toJson() {
    return {
      "objectId": objectId,
      "userId": userId,
      "backendUserId": backendUserId,
      "userUuid": userUuid,
      "userName": userName,
      "userPassword": userPassword,
      "userType": userType,
      "first": first,
      "last": last,
      "countryCode": countryCode,
      "mobile": mobile,
      "dob": dob,
      "gender": gender,
      "idProofKey": idProofKey,
      "idProofValue": idProofValue,
      "address": address,
      "restaurantName": restaurantName,
      "pin": pin,
    };
  }
}
