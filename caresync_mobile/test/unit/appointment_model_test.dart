import 'package:flutter_test/flutter_test.dart';
import 'package:caresync_mobile/core/constants/app_constants.dart';
import 'package:caresync_mobile/models/appointment.dart';
import 'package:caresync_mobile/models/prescription.dart';

void main() {
  group('Appointment Model Tests', () {
    test('Correctly parses complete appointment JSON from backend', () {
      final json = {
        'id': 'apt1712345678',
        'doctorId': 'ananya@hospital.com',
        'patientId': 'abcd@gmail.com',
        'date': '2026-09-28',
        'slot': '10:00 AM',
        'status': 'Scheduled',
        'problem': 'Mild chest discomfort',
        'prescription': 'Aspirin 75mg once daily',
        'assignedResources': {
          'bed': true,
          'blood': {
            'type': 'O+',
            'units': 2,
          },
          'scan': 'MRI',
        },
        'isUpdated': true,
        'updatedAt': '2026-09-28T10:00:00.000Z',
      };

      final appointment = Appointment.fromJson(json);

      expect(appointment.id, 'apt1712345678');
      expect(appointment.doctorId, 'ananya@hospital.com');
      expect(appointment.patientId, 'abcd@gmail.com');
      expect(appointment.date, '2026-09-28');
      expect(appointment.slot, '10:00 AM');
      expect(appointment.status, 'Scheduled');
      expect(appointment.problem, 'Mild chest discomfort');
      expect(appointment.prescription, 'Aspirin 75mg once daily');
      expect(appointment.assignedResources?.bed, true);
      expect(appointment.assignedResources?.blood?.type, 'O+');
      expect(appointment.assignedResources?.blood?.units, 2);
      expect(appointment.assignedResources?.scan, 'MRI');
      expect(appointment.isUpdated, true);
      expect(appointment.updatedAt, '2026-09-28T10:00:00.000Z');
    });

    test('Correctly handles optional/null consultation fields on new scheduled appointment', () {
      final json = {
        'id': 'apt1001',
        'doctorId': 'doc1',
        'patientId': 'pat1',
        'date': '2026-09-29',
        'slot': '11:00 AM',
        'status': 'Scheduled',
      };

      final appointment = Appointment.fromJson(json);

      expect(appointment.id, 'apt1001');
      expect(appointment.problem, isNull);
      expect(appointment.prescription, isNull);
      expect(appointment.assignedResources, isNull);
      expect(appointment.isUpdated, false);
      expect(appointment.updatedAt, isNull);
    });

    test('Serializes appointment back to JSON matching backend expectation', () {
      const appointment = Appointment(
        id: 'apt1002',
        doctorId: 'doc2',
        patientId: 'pat2',
        date: '2026-09-30',
        slot: '02:00 PM',
        status: AppConstants.statusCompleted,
        problem: 'Fever',
        prescription: 'Paracetamol 500mg',
      );

      final json = appointment.toJson();

      expect(json['id'], 'apt1002');
      expect(json['doctorId'], 'doc2');
      expect(json['patientId'], 'pat2');
      expect(json['date'], '2026-09-30');
      expect(json['slot'], '02:00 PM');
      expect(json['status'], 'Completed');
      expect(json['problem'], 'Fever');
      expect(json['prescription'], 'Paracetamol 500mg');
    });

    test('Prescription model derives properly from Appointment entity', () {
      const appointment = Appointment(
        id: 'apt999',
        doctorId: 'doc_cardio',
        patientId: 'pat_jane',
        date: '2026-10-01',
        slot: '03:00 PM',
        status: AppConstants.statusCompleted,
        problem: 'Hypertension checkup',
        prescription: 'Amlodipine 5mg once daily',
        assignedResources: AssignedResources(
          bed: false,
          blood: BloodRequirement(type: 'B+', units: 1),
          scan: 'X-Ray',
        ),
      );

      final rx = Prescription.fromAppointment(
        appointment,
        doctorName: 'Dr. Jane Smith',
        doctorSpecialty: 'Cardiology',
      );

      expect(rx.appointmentId, 'apt999');
      expect(rx.doctorName, 'Dr. Jane Smith');
      expect(rx.doctorSpecialty, 'Cardiology');
      expect(rx.problem, 'Hypertension checkup');
      expect(rx.medication, 'Amlodipine 5mg once daily');
      expect(rx.hasAssignedBed, false);
      expect(rx.hasBloodTransfusion, true);
      expect(rx.hasScanRequired, true);
      expect(rx.assignedResources?.scan, 'X-Ray');
    });
  });
}
