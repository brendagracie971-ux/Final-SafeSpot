class UserModel {
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String? dateOfBirth;
  final String? gender;

  final String emergencyContact1;
  final String? emergencyContact2;
  final String? emergencyContact3;

  final String? bloodGroup;
  final String? allergies;
  final String? medicalConditions;

  UserModel({
    required this.fullName,
    required this.phoneNumber,
    this.email,
    this.dateOfBirth,
    this.gender,
    required this.emergencyContact1,
    this.emergencyContact2,
    this.emergencyContact3,
    this.bloodGroup,
    this.allergies,
    this.medicalConditions,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'emergencyContact1': emergencyContact1,
      'emergencyContact2': emergencyContact2,
      'emergencyContact3': emergencyContact3,
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'medicalConditions': medicalConditions,
    };
  }
}