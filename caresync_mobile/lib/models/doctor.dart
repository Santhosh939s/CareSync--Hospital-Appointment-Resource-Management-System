/// Represents a Doctor in CareSync.
///
/// Mirrors doctor fields from the MongoDB User collection where role == 'doctor'.
class Doctor {
  final String id;
  final String name;
  final String email;
  final String specialty;
  final String department;
  final int maxPatients;

  const Doctor({
    required this.id,
    required this.name,
    required this.email,
    required this.specialty,
    required this.department,
    this.maxPatients = 3,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      specialty: json['specialty'] as String? ?? 'General Medicine',
      department: json['department'] as String? ?? 'Outpatient',
      maxPatients: (json['maxPatients'] as num?)?.toInt() ?? 3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': 'doctor',
      'specialty': specialty,
      'department': department,
      'maxPatients': maxPatients,
    };
  }

  Doctor copyWith({
    String? id,
    String? name,
    String? email,
    String? specialty,
    String? department,
    int? maxPatients,
  }) {
    return Doctor(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      specialty: specialty ?? this.specialty,
      department: department ?? this.department,
      maxPatients: maxPatients ?? this.maxPatients,
    );
  }

  @override
  String toString() => 'Doctor(id: $id, name: $name, specialty: $specialty)';
}
