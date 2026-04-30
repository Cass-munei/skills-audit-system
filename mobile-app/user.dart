class User {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String employeeId;
  final String department;
  final String hod;
  final String? dateOfBirth;
  final String? gender;
  final String? contact;
  final String? address;
  final String? idNumber;
  final String? jobTitle;
  final String? headOfUnit;
  final String? additionalInfo;
  final String? photoUrl;
  final String? photoBase64;
  final bool isDisabled;

  User({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.employeeId,
    required this.department,
    required this.hod,
    this.dateOfBirth,
    this.gender,
    this.contact,
    this.address,
    this.idNumber,
    this.jobTitle,
    this.headOfUnit,
    this.additionalInfo,
    this.photoUrl,
    this.photoBase64,
    this.isDisabled = false,
  });

  User copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? employeeId,
    String? department,
    String? hod,
    String? dateOfBirth,
    String? gender,
    String? contact,
    String? address,
    String? idNumber,
    String? jobTitle,
    String? headOfUnit,
    String? additionalInfo,
    String? photoUrl,
    String? photoBase64,
    bool? isDisabled,
  }) {
    return User(
      uid: uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      employeeId: employeeId ?? this.employeeId,
      department: department ?? this.department,
      hod: hod ?? this.hod,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      contact: contact ?? this.contact,
      address: address ?? this.address,
      idNumber: idNumber ?? this.idNumber,
      jobTitle: jobTitle ?? this.jobTitle,
      headOfUnit: headOfUnit ?? this.headOfUnit,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      photoUrl: photoUrl ?? this.photoUrl,
      photoBase64: photoBase64 ?? this.photoBase64,
      isDisabled: isDisabled ?? this.isDisabled,
    );
  }

  factory User.fromMap(Map<String, dynamic> data, String uid) {
    String? photoUrl = data['photoUrl'] as String?;
    if (photoUrl != null && photoUrl.isEmpty) photoUrl = null;
    String? photoBase64 = data['photoBase64'] as String?;
    if (photoBase64 != null && photoBase64.isEmpty) photoBase64 = null;
    return User(
      uid: uid,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      employeeId: data['employeeId'] ?? '',
      department: data['department'] ?? '',
      hod: data['hod'] ?? '',
      dateOfBirth: data['dateOfBirth'],
      gender: data['gender'],
      contact: data['contact'],
      address: data['address'],
      idNumber: data['idNumber'],
      jobTitle: data['jobTitle'],
      headOfUnit: data['headOfUnit'],
      additionalInfo: data['additionalInfo'],
      photoUrl: photoUrl,
      photoBase64: photoBase64,
      isDisabled: data['isDisabled'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'employeeId': employeeId,
      'department': department,
      'hod': hod,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'contact': contact,
      'address': address,
      'idNumber': idNumber,
      'jobTitle': jobTitle,
      'headOfUnit': headOfUnit,
      'additionalInfo': additionalInfo,
      'photoUrl': photoUrl,
      'photoBase64': photoBase64,
      'isDisabled': isDisabled,
    };
  }
}
