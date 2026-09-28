/// Represents a hospital appointment.
///
/// Maps to the MongoDB Appointment collection. Uses `{strict: false}` on the
/// backend, so extra fields like [problem], [prescription], [assignedResources],
/// [isUpdated] and [updatedAt] may or may not be present.
class AssignedResources {
  final bool bed;
  final BloodRequirement? blood;
  final String? equipment;

  const AssignedResources({
    this.bed = false,
    this.blood,
    this.equipment,
  });

  factory AssignedResources.fromJson(Map<String, dynamic> json) {
    return AssignedResources(
      bed: json['bed'] == true,
      blood: json['blood'] != null ? BloodRequirement.fromJson(json['blood'] as Map<String, dynamic>) : null,
      equipment: json['equipment'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (bed) 'bed': true,
      if (blood != null) 'blood': blood!.toJson(),
      if (equipment != null) 'equipment': equipment,
    };
  }

  bool get hasAny => bed || blood != null || equipment != null;
}

class BloodRequirement {
  final String type;
  final int units;

  const BloodRequirement({required this.type, required this.units});

  factory BloodRequirement.fromJson(Map<String, dynamic> json) {
    return BloodRequirement(
      type: json['type'] as String? ?? '',
      units: (json['units'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {'type': type, 'units': units};
}

class Appointment {
  final String id;
  final String doctorId;
  final String patientId;
  final String date;
  final String slot;
  final String status;
  final String? problem;
  final String? prescription;
  final AssignedResources? assignedResources;
  final bool isUpdated;
  final String? updatedAt;

  const Appointment({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.date,
    required this.slot,
    this.status = 'Pending',
    this.problem,
    this.prescription,
    this.assignedResources,
    this.isUpdated = false,
    this.updatedAt,
  });

  /// Whether this appointment is in a terminal state.
  bool get isEnded =>
      status.contains('Cancelled') ||
      status.contains('Withdrawn') ||
      status.contains('Declined');

  bool get isPending => status == 'Pending';
  bool get isApproved => status == 'Approved';
  bool get isCompleted => status == 'Completed';

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      doctorId: json['doctorId'] as String? ?? '',
      patientId: json['patientId'] as String? ?? '',
      date: json['date'] as String? ?? '',
      slot: json['slot'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending',
      problem: json['problem'] as String?,
      prescription: json['prescription'] as String?,
      assignedResources: json['assignedResources'] != null
          ? AssignedResources.fromJson(json['assignedResources'] as Map<String, dynamic>)
          : null,
      isUpdated: json['isUpdated'] == true,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorId': doctorId,
      'patientId': patientId,
      'date': date,
      'slot': slot,
      'status': status,
      if (problem != null) 'problem': problem,
      if (prescription != null) 'prescription': prescription,
    };
  }
}
