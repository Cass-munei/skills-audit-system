class TrainingRecordViewModel {
  final String userId;
  final String employeeId;
  final String employeeName;
  final String trainingName;
  final String provider;
  final String startDate;
  final String endDate;
  final String status;
  final String trainingId;

  TrainingRecordViewModel({
    required this.userId,
    required this.employeeId,
    required this.employeeName,
    required this.trainingName,
    required this.provider,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.trainingId,
  });

  factory TrainingRecordViewModel.fromMap(Map<String, dynamic> data) {
    return TrainingRecordViewModel(
      userId: data['userId'] ?? '',
      employeeId: data['employeeId'] ?? '',
      employeeName: data['employeeName'] ?? '',
      trainingName: data['trainingName'] ?? '',
      provider: data['provider'] ?? '',
      startDate: data['startDate'] ?? '',
      endDate: data['endDate'] ?? '',
      status: data['status'] ?? '',
      trainingId: data['trainingId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'trainingName': trainingName,
      'provider': provider,
      'startDate': startDate,
      'endDate': endDate,
      'status': status,
      'trainingId': trainingId,
    };
  }
}

class EmployeeViewModel {
  final String userId;
  final String employeeId;
  final String employeeName;

  EmployeeViewModel({
    required this.userId,
    required this.employeeId,
    required this.employeeName,
  });

  factory EmployeeViewModel.fromMap(Map<String, dynamic> data) {
    return EmployeeViewModel(
      userId: data['userId'] ?? '',
      employeeId: data['employeeId'] ?? '',
      employeeName: data['employeeName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'employeeId': employeeId,
      'employeeName': employeeName,
    };
  }
}

class TrainingRecordsViewModel {
  final List<TrainingRecordViewModel> trainingRecords;
  final List<EmployeeViewModel> employees;
  final String adminId;

  TrainingRecordsViewModel({
    required this.trainingRecords,
    required this.employees,
    required this.adminId,
  });

  factory TrainingRecordsViewModel.fromMap(Map<String, dynamic> data) {
    return TrainingRecordsViewModel(
      trainingRecords: (data['trainingRecords'] as List<dynamic>?)
          ?.map((e) => TrainingRecordViewModel.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      employees: (data['employees'] as List<dynamic>?)
          ?.map((e) => EmployeeViewModel.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      adminId: data['adminId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trainingRecords': trainingRecords.map((e) => e.toMap()).toList(),
      'employees': employees.map((e) => e.toMap()).toList(),
      'adminId': adminId,
    };
  }
}
