
import 'package:objectbox/objectbox.dart';
import 'package:uuid/uuid.dart';

@Entity()
class EntityPrinter {
  @Id(assignable: true)
  int id;

  String? configType; // e.g. 'KOT', 'BILL'
  //{"available":true,"comment":"","default":false,"location":"","model":"Send to Microsoft OneNote 16 Driver","name":"OneNote (Desktop)","url":"OneNote (Desktop)"}
  String? printUrl;
  String? printName;
  String? printModel;
  String? printLocation;
  String? printComment;
  bool? printDefault;
  bool? printIsAvailable;

  String? createdOn; //
  String? orderType; //quick bill ,Dine-in
  String? source; //captain app ,Atlantic Pos ,Online Order
  String? createdBy;
  String? printerSize; //58 ,80 ,A4 => use EnumPrinterSize
  int noOfCop = 1;

  @Unique()
  late String? printerUuid;

  EntityPrinter({
    this.printModel,
    this.printUrl,
    this.printName,
    this.orderType,
    this.printIsAvailable,
    this.printComment,
    this.printDefault,
    this.printLocation,
    this.id = 0,
    this.source,
    this.createdOn,
    this.createdBy,
    this.configType ,
    String? printerUuid,
    this.printerSize,
    this.noOfCop = 1,
  }) : printerUuid = printerUuid ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'configType': configType,
      'printUrl': printUrl,
      'printName': printName,
      'printModel': printModel,
      'printLocation': printLocation,
      'printComment': printComment,
      'printDefault': printDefault,
      'printIsAvailable': printIsAvailable,
      'createdOn': createdOn,
      'orderType': orderType,
      'source': source,
      'createdBy': createdBy,
      'printerSize': printerSize,
      'noOfCop': noOfCop,
      'printerUuid': printerUuid,
    };
  }


  Map<String, dynamic> toJson() {
    return {
      'printName': printName,
      'printModel': printModel,
      'printUrl': printUrl,
      'printIsAvailable': printIsAvailable,
      'printComment': printComment,
      'printDefault': printDefault,
      'printLocation': printLocation,
    };
  }

  factory EntityPrinter.fromJson(Map<String, dynamic> json) {
    return EntityPrinter(
      printName: json['printName'],
      printModel: json['printModel'],
      printUrl: json['printUrl'],
      printIsAvailable: json['printIsAvailable'],
      printComment: json['printComment'],
      printDefault: json['printDefault'],
      printLocation: json['printLocation'],
    );
  }



}