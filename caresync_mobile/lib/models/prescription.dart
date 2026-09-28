import 'appointment.dart';

/// Clinical Prescription model derived from a completed Appointment.
///
/// Encapsulates diagnosis, prescribed medication, bed allocation, blood units,
/// required diagnostic scans, and modification timestamps.
class Prescription {
  final String appointmentId;
  final String doctorId;
  final String? doctorName;
  final String? doctorSpecialty;
  final String patientId;
  final String date;
  final String? problem;
  final String? medication;
  final AssignedResources? assignedResources;
  final bool isUpdated;
  final String? updatedAt;

  const Prescription({
    required this.appointmentId,
    required this.doctorId,
    this.doctorName,
    this.doctorSpecialty,
    required this.patientId,
    required this.date,
    this.problem,
    this.medication,
    this.assignedResources,
    this.isUpdated = false,
    this.updatedAt,
  });

  /// Factory constructor to derive a Prescription from an Appointment
  factory Prescription.fromAppointment(Appointment appointment, {String? doctorName, String? doctorSpecialty}) {
    return Prescription(
      appointmentId: appointment.id,
      doctorId: appointment.doctorId,
      doctorName: doctorName,
      doctorSpecialty: doctorSpecialty,
      patientId: appointment.patientId,
      date: appointment.date,
      problem: appointment.problem,
      medication: appointment.prescription,
      assignedResources: appointment.assignedResources,
      isUpdated: appointment.isUpdated,
      updatedAt: appointment.updatedAt,
    );
  }

  bool get hasMedication => medication != null && medication!.trim().isNotEmpty;
  bool get hasAssignedBed => assignedResources?.bed == true;
  bool get hasBloodTransfusion =>
      assignedResources?.blood != null &&
      assignedResources!.blood!.units > 0;
  bool get hasScanRequired =>
      assignedResources?.scan != null &&
      assignedResources!.scan!.trim().isNotEmpty;
}
