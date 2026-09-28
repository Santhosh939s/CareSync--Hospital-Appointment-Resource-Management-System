import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/exceptions/app_exceptions.dart';
import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/prescription.dart';
import '../models/user.dart';
import '../services/appointment_service.dart';
import '../services/consultation_service.dart';
import '../services/doctor_service.dart';
import '../services/notification_service.dart';

/// State management for Appointments, Doctors, Slot availability, and Prescriptions.
class AppointmentProvider with ChangeNotifier {
  final AppointmentService _appointmentService;
  final DoctorService _doctorService;
  final ConsultationService _consultationService;
  final NotificationService _notificationService;

  List<Appointment> _appointments = [];
  List<Doctor> _doctors = [];
  Map<String, int> _slotBookings = {};

  bool _isLoading = false;
  bool _isSlotChecking = false;
  String? _errorMessage;

  AppointmentProvider({
    AppointmentService? appointmentService,
    DoctorService? doctorService,
    ConsultationService? consultationService,
    NotificationService? notificationService,
  })  : _appointmentService = appointmentService ?? AppointmentService(),
        _doctorService = doctorService ?? DoctorService(),
        _consultationService = consultationService ?? ConsultationService(),
        _notificationService = notificationService ?? NotificationService();

  List<Appointment> get appointments => _appointments;
  List<Doctor> get doctors => _doctors;
  Map<String, int> get slotBookings => _slotBookings;
  bool get isLoading => _isLoading;
  bool get isSlotChecking => _isSlotChecking;
  String? get errorMessage => _errorMessage;

  // --- Derived Getters for Patient ---

  /// Finds patient's next upcoming appointment.
  Appointment? getUpcomingAppointment(String patientId) {
    final scheduled = _appointments
        .where((a) => a.patientId == patientId && a.status == AppConstants.statusScheduled)
        .toList();
    if (scheduled.isEmpty) return null;
    scheduled.sort((a, b) => a.date.compareTo(b.date));
    return scheduled.first;
  }

  /// Patient's appointments list sorted by date descending.
  List<Appointment> getPatientAppointments(String patientId) {
    final list = _appointments.where((a) => a.patientId == patientId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// Patient's prescriptions extracted from completed appointments.
  List<Prescription> getPatientPrescriptions(String patientId) {
    final completed = _appointments
        .where((a) => a.patientId == patientId && a.status == AppConstants.statusCompleted)
        .toList();

    completed.sort((a, b) => b.date.compareTo(a.date));

    return completed.map((a) {
      final doc = getDoctorById(a.doctorId);
      return Prescription.fromAppointment(
        a,
        doctorName: doc?.name ?? a.doctorId,
        doctorSpecialty: doc?.specialty ?? 'Hospital Care',
      );
    }).toList();
  }

  /// Count of unread prescription updates for patient badge.
  int getUnreadPrescriptionCount(String patientId) {
    final patientAppts = _appointments.where((a) => a.patientId == patientId).toList();
    return _notificationService.getUnreadCount(patientAppts);
  }

  bool isPrescriptionUnread(Appointment appt) {
    return _notificationService.hasUnreadUpdate(appt);
  }

  // --- Derived Getters for Doctor ---

  List<Appointment> getDoctorAppointments(String doctorId) {
    final list = _appointments.where((a) => a.doctorId == doctorId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<Appointment> getDoctorTodayAppointments(String doctorId, String todayDate) {
    return _appointments
        .where((a) => a.doctorId == doctorId && a.date == todayDate)
        .toList();
  }

  List<Appointment> getDoctorPendingAppointments(String doctorId) {
    return _appointments
        .where((a) => a.doctorId == doctorId && a.status == AppConstants.statusScheduled)
        .toList();
  }

  List<Appointment> getDoctorCompletedAppointments(String doctorId) {
    return _appointments
        .where((a) => a.doctorId == doctorId && a.status == AppConstants.statusCompleted)
        .toList();
  }

  Doctor? getDoctorById(String doctorId) {
    try {
      return _doctors.firstWhere((d) => d.id == doctorId);
    } catch (_) {
      return null;
    }
  }

  // --- Actions ---

  /// Loads doctors and appointments for the active user context.
  Future<void> loadData(User? user) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final docs = await _doctorService.getDoctors();
      _doctors = docs;

      final appts = await _appointmentService.getAllAppointments();
      _appointments = appts;
    } on AppException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load hospital data.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Checks live slot availability for a chosen doctor and date.
  Future<void> checkSlotAvailability({
    required String doctorId,
    required String date,
  }) async {
    _isSlotChecking = true;
    notifyListeners();

    try {
      _slotBookings = await _appointmentService.getSlotBookings(
        doctorId: doctorId,
        date: date,
      );
    } catch (e) {
      // Keep existing map on error
    } finally {
      _isSlotChecking = false;
      notifyListeners();
    }
  }

  /// Books an appointment with double-check availability.
  Future<bool> bookAppointment({
    required String doctorId,
    required String patientId,
    required String date,
    required String slot,
    String? problem,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newAppt = await _appointmentService.bookAppointment(
        doctorId: doctorId,
        patientId: patientId,
        date: date,
        slot: slot,
        problem: problem,
      );
      _appointments.add(newAppt);
      // Refresh slot counts
      await checkSlotAvailability(doctorId: doctorId, date: date);
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Booking failed unexpectedly.';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates appointment status (e.g. Scheduled -> Cancelled, etc).
  Future<bool> updateAppointmentStatus({
    required String appointmentId,
    required String status,
  }) async {
    try {
      final updated = await _appointmentService.updateStatus(
        appointmentId: appointmentId,
        status: status,
      );
      final idx = _appointments.indexWhere((a) => a.id == appointmentId);
      if (idx != -1) {
        _appointments[idx] = updated;
        notifyListeners();
      }
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Status update failed.';
      notifyListeners();
      return false;
    }
  }

  /// Submits consultation results and triggers hospital backend resource allocation.
  Future<bool> completeConsultation({
    required String appointmentId,
    required String problem,
    required String prescription,
    bool admitPatientBed = false,
    String? bloodType,
    int bloodUnits = 0,
    String? scanRequired,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _consultationService.completeConsultation(
        appointmentId: appointmentId,
        problem: problem,
        prescription: prescription,
        admitPatientBed: admitPatientBed,
        bloodType: bloodType,
        bloodUnits: bloodUnits,
        scanRequired: scanRequired,
      );
      final idx = _appointments.indexWhere((a) => a.id == appointmentId);
      if (idx != -1) {
        _appointments[idx] = updated;
      }
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Consultation submission failed.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates existing prescription without resource re-allocation.
  Future<bool> updatePrescription({
    required String appointmentId,
    required String problem,
    required String prescription,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _consultationService.updatePrescription(
        appointmentId: appointmentId,
        problem: problem,
        prescription: prescription,
      );
      final idx = _appointments.indexWhere((a) => a.id == appointmentId);
      if (idx != -1) {
        _appointments[idx] = updated;
      }
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Prescription update failed.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Marks a prescription notification as read.
  Future<void> markPrescriptionRead(String appointmentId) async {
    await _notificationService.markAsViewed(appointmentId);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
