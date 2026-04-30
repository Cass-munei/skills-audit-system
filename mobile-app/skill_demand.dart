class SkillDemand {
  final String id;
  final String name;
  final String department;
  final double demandLevel;
  final String requiredLevel;
  final double gapPercentage;
  final int employeesMatching;
  final int totalEmployees;
  final String description;

  SkillDemand({
    required this.id,
    required this.name,
    required this.department,
    required this.demandLevel,
    required this.requiredLevel,
    required this.gapPercentage,
    required this.employeesMatching,
    required this.totalEmployees,
    required this.description,
  });

  factory SkillDemand.fromMap(Map<String, dynamic> data, String id) {
    String name = data['name'] != null ? data['name'].toString() : '';
    String department = data['department'] != null ? data['department'].toString() : '';
    String requiredLevel = data['requiredLevel'] != null ? data['requiredLevel'].toString() : 'Intermediate';
    String description = data['description'] != null ? data['description'].toString() : '';
    int employeesMatching = int.tryParse((data['employeesMatching']?.toString()) ?? '') ?? 0;
    int totalEmployees = int.tryParse((data['totalEmployees']?.toString()) ?? '') ?? 0;
    double gapPercentage = totalEmployees > 0 ? (totalEmployees - employeesMatching) / totalEmployees : 0.0;
    return SkillDemand(
      id: id,
      name: name,
      department: department,
      demandLevel: 1 - gapPercentage,
      requiredLevel: requiredLevel,
      gapPercentage: gapPercentage,
      employeesMatching: employeesMatching,
      totalEmployees: totalEmployees,
      description: description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'department': department,
      'demandLevel': demandLevel,
      'requiredLevel': requiredLevel,
      'gapPercentage': gapPercentage,
      'employeesMatching': employeesMatching,
      'totalEmployees': totalEmployees,
      'description': description,
    };
  }
}
