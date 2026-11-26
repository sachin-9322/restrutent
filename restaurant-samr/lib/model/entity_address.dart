import 'package:objectbox/objectbox.dart';

@Entity()
class EntityAddress {
  @Id()
  int addressId = 0;
  String? type; // home, office, other
  String? state;
  String? city;
  String? pinCode;
  String? addressLine1;
  String? addressLine2;
  String? restUuid;

  EntityAddress({
    required this.type,
    this.state,
    this.city,
    this.pinCode,
    required this.addressLine1,
    this.addressLine2,
    this.restUuid
  });
}
