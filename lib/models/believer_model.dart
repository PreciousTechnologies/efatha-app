/// Model representing a believer/church member
/// Maps to tbl_believers in the database
class BelieverModel {
  // Personal Information
  String? believerId;
  String firstName;
  String middleName;
  String lastName;
  String gender;
  DateTime birthDate;
  String? photo;

  // Location Information
  int? countryId;
  String? countryName;
  int? regionId;
  String? regionName;
  int? districtId;
  String? districtName;
  String birthPlace;
  String residence;
  String street;
  String houseNumber;
  String? houseDescription;
  String? houseStatus;

  // Contact Information
  String postalAddress;
  String phone;
  String email;

  // Additional Personal Info
  String? marriageStatus;
  String? educationLevel;
  String? jobStatus;

  // Church/Service Information
  int? serviceRegionId;
  String? serviceRegionName;
  int? centreId;
  String? centreName;
  int? areaId;
  String? areaName;
  int? zoneId;
  String? zoneName;
  int? cellId;
  String? cellName;
  String? attendedClasses;
  String? classLevel;
  String churchPosition;

  // System Information
  String? registrationNumber;
  DateTime? registrationDate;
  int? userId;

  BelieverModel({
    this.believerId,
    required this.firstName,
    this.middleName = '',
    required this.lastName,
    required this.gender,
    required this.birthDate,
    this.photo,
    this.countryId,
    this.countryName,
    this.regionId,
    this.regionName,
    this.districtId,
    this.districtName,
    this.birthPlace = '',
    this.residence = '',
    this.street = '',
    this.houseNumber = '',
    this.houseDescription,
    this.houseStatus,
    this.postalAddress = '',
    required this.phone,
    required this.email,
    this.marriageStatus,
    this.educationLevel,
    this.jobStatus,
    this.serviceRegionId,
    this.serviceRegionName,
    this.centreId,
    this.centreName,
    this.areaId,
    this.areaName,
    this.zoneId,
    this.zoneName,
    this.cellId,
    this.cellName,
    this.attendedClasses,
    this.classLevel,
    this.churchPosition = '',
    this.registrationNumber,
    this.registrationDate,
    this.userId,
  });

  /// Convert model to JSON for API submission
  Map<String, dynamic> toJson() {
    return {
      'Believer_ID': believerId,
      'First_Name': firstName,
      'Middle_Name': middleName,
      'Last_Name': lastName,
      'Gender': gender,
      'Birth_Date': birthDate.toIso8601String().split('T')[0],
      'Photo': photo ?? '',
      'Country_ID': countryId ?? 0,
      'Region_ID': regionId ?? 0,
      'District_ID': districtId ?? 0,
      'Birth_Place': birthPlace,
      'Residence': residence,
      'Street': street,
      'House_Number': houseNumber,
      'House_Description': houseDescription ?? '',
      'House_Status': houseStatus ?? '',
      'Postal_Address': postalAddress,
      'Phone': phone,
      'Email': email,
      'Marriage_Status': marriageStatus ?? '',
      'Education_Level': educationLevel ?? '',
      'Job_Status': jobStatus ?? '',
      'Service_Region_ID': serviceRegionId ?? 0,
      'Centre_ID': centreId ?? 0,
      'Area_ID': areaId ?? 0,
      'Zone_ID': zoneId ?? 0,
      'Cell_ID': cellId ?? 0,
      'Attendend_Classes': attendedClasses ?? '',
      'Class_Level': classLevel ?? '',
      'Church_Position': churchPosition,
      'Registration_Number': registrationNumber ?? '',
      'Registration_Date': registrationDate?.toIso8601String().split('T')[0] ?? '',
      'User_ID': userId ?? 0,
    };
  }

  /// Create model from JSON response
  factory BelieverModel.fromJson(Map<String, dynamic> json) {
    return BelieverModel(
      believerId: json['Believer_ID']?.toString(),
      firstName: json['First_Name'] ?? '',
      middleName: json['Middle_Name'] ?? '',
      lastName: json['Last_Name'] ?? '',
      gender: json['Gender'] ?? '',
      birthDate: DateTime.parse(json['Birth_Date']),
      photo: json['Photo'],
      countryId: json['Country_ID'],
      regionId: json['Region_ID'],
      districtId: json['District_ID'],
      birthPlace: json['Birth_Place'] ?? '',
      residence: json['Residence'] ?? '',
      street: json['Street'] ?? '',
      houseNumber: json['House_Number'] ?? '',
      houseDescription: json['House_Description'],
      houseStatus: json['House_Status'],
      postalAddress: json['Postal_Address'] ?? '',
      phone: json['Phone'] ?? '',
      email: json['Email'] ?? '',
      marriageStatus: json['Marriage_Status'],
      educationLevel: json['Education_Level'],
      jobStatus: json['Job_Status'],
      serviceRegionId: json['Service_Region_ID'],
      centreId: json['Centre_ID'],
      areaId: json['Area_ID'],
      zoneId: json['Zone_ID'],
      cellId: json['Cell_ID'],
      attendedClasses: json['Attendend_Classes'],
      classLevel: json['Class_Level'],
      churchPosition: json['Church_Position'] ?? '',
      registrationNumber: json['Registration_Number'],
      registrationDate: json['Registration_Date'] != null 
          ? DateTime.parse(json['Registration_Date']) 
          : null,
      userId: json['User_ID'],
    );
  }

  /// Get full name
  String get fullName {
    final names = [firstName];
    if (middleName.isNotEmpty) names.add(middleName);
    names.add(lastName);
    return names.join(' ');
  }

  /// Get age from birth date
  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Validate if model has required fields
  bool get isValid {
    return firstName.isNotEmpty &&
           lastName.isNotEmpty &&
           gender.isNotEmpty &&
           phone.isNotEmpty &&
           email.isNotEmpty;
  }
}
