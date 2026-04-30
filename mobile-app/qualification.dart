class Qualification {
  final String id;
  final String name;
  final String institution;
  final String date;

  Qualification({
    required this.id,
    required this.name,
    required this.institution,
    required this.date,
  });

  factory Qualification.fromMap(Map<String, dynamic> data, String id) {
    return Qualification(
      id: id,
      name: data['name'] ?? data['Name'] ?? data['qualificationName'] ?? '',
      institution: data['institution'] ?? data['Institution'] ?? data['institutionName'] ?? '',
      date: data['date'] ?? data['Date'] ?? data['year'] ?? '',
    );
  }

  factory Qualification.fromJson(Map<String, dynamic> json) {
    return Qualification(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      institution: json['institution'] ?? '',
      date: json['date'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'Name': name, 'Institution': institution, 'Date': date};
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'Name': name,
      'Institution': institution,
      'Date': date,
    };
  }
}
