import 'package:objectbox/objectbox.dart';

import 'entity_address.dart';

@Entity()
class EntityCustomer {
  @Id()
  int customerId = 0;
  // Mr. Ms. Mrs. Dr King Prince Queen Princess Sir Madam VIP
  String? salutation;
  String? firstName;
  String? lastName;
  String? countryCode;
  String? mobileNumber;
  String? email;
  String? dob;
  String? comment;
  String? userType; // Individual, Corporate
  String? restUuid;


  // if userType is Corporate then display following fields on UI
  String? pan;
  String? fassi;
  // company to company deal or VAT => if A4 print size then display this GST number on label
  String? gstOrVatOrTrn;

  ToMany<EntityAddress> address = ToMany();

  EntityCustomer({
    this.salutation,
    this.firstName,
    this.lastName,
    this.countryCode,
    this.mobileNumber,
    this.email,
    this.dob,
    this.comment,
    this.fassi,
    this.gstOrVatOrTrn,
    this.restUuid,
  });
}
