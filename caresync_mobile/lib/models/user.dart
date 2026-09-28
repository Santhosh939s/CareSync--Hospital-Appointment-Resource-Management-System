/// Represents a CareSync user (patient, doctor or admin).
///
/// Maps directly to the MongoDB User collection.
/// The [password] field is intentionally excluded — the backend
/// strips it from login responses and Flutter never stores it.
class User {
  final String id;
  final String role;
  final String name;
  final String email;
  final String? specialty;
  final int? maxPatients;
  final String? department;

  const User({
    required this.id,
    required this.role,
    required this.name,
    required this.email,
    this.specialty,
    this.maxPatients,
    this.department,
  });

  bool get isPatient => role == 'patient';
  bool get isDoctor => role == 'doctor';
  bool get isAdmin => role == 'admin';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      role: json['role'] as String? ?? 'patient',
      name: json['name'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? '',
      specialty: json['specialty'] as String?,
      maxPatients: json['maxPatients'] as int?,
      department: json['department'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'name': name,
      'email': email,
      if (specialty != null) 'specialty': specialty,
      if (maxPatients != null) 'maxPatients': maxPatients,
      if (department != null) 'department': department,
    };
  }
}
