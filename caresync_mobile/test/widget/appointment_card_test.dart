import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caresync_mobile/app/theme.dart';
import 'package:caresync_mobile/models/appointment.dart';
import 'package:caresync_mobile/models/doctor.dart';
import 'package:caresync_mobile/widgets/appointment_card.dart';

void main() {
  testWidgets('AppointmentCard renders appointment details and status badge', (WidgetTester tester) async {
    const doctor = Doctor(
      id: 'doc101',
      name: 'Dr. Ananya Sharma',
      email: 'ananya@hospital.com',
      specialty: 'Cardiology',
      department: 'Cardiology',
    );

    const appointment = Appointment(
      id: 'apt1001',
      doctorId: 'doc101',
      patientId: 'pat_test',
      date: '2026-10-05',
      slot: '10:00 AM',
      status: 'Scheduled',
      problem: 'Routine health check',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: AppointmentCard(
            appointment: appointment,
            doctor: doctor,
          ),
        ),
      ),
    );

    expect(find.text('Dr. Ananya Sharma'), findsOneWidget);
    expect(find.text('Cardiology'), findsOneWidget);
    expect(find.text('2026-10-05'), findsOneWidget);
    expect(find.text('10:00 AM'), findsOneWidget);
    expect(find.text('SCHEDULED'), findsOneWidget);
    expect(find.text('Diagnosis: Routine health check'), findsOneWidget);
  });
}
