import 'package:flutter/material.dart';

import '../core/exceptions/app_exceptions.dart';
import '../models/allocation.dart';
import '../models/financial_ledger.dart';
import '../models/purchase_order.dart';
import '../models/resource.dart';
import '../services/resource_service.dart';

/// State management for hospital resources, allocations, financials, and purchasing.
class ResourceProvider with ChangeNotifier {
  final ResourceService _resourceService;

  HospitalResource? _resource;
  List<Allocation> _allocations = [];
  List<FinancialLedger> _financials = [];
  List<PurchaseOrder> _purchaseOrders = [];

  bool _isLoading = false;
  String? _errorMessage;

  ResourceProvider({ResourceService? resourceService})
      : _resourceService = resourceService ?? ResourceService();

  HospitalResource? get resource => _resource;
  List<Allocation> get allocations => _allocations;
  List<FinancialLedger> get financials => _financials;
  List<PurchaseOrder> get purchaseOrders => _purchaseOrders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get totalRevenue =>
      _financials.fold(0.0, (sum, item) => sum + item.amount);

  /// Loads hospital resource counts, allocations, financials, and POs.
  Future<void> loadResources() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _resourceService.getHospitalData();

      final resJson = data['hms_resources'] as Map<String, dynamic>? ?? {};
      _resource = HospitalResource.fromJson(resJson);

      final rawAlloc = data['hms_allocations'] as List<dynamic>? ?? [];
      _allocations = rawAlloc
          .whereType<Map<String, dynamic>>()
          .map((j) => Allocation.fromJson(j))
          .toList();

      final rawFin = data['hms_financials'] as List<dynamic>? ?? [];
      _financials = rawFin
          .whereType<Map<String, dynamic>>()
          .map((j) => FinancialLedger.fromJson(j))
          .toList();

      final rawPo = data['hms_purchasing'] as List<dynamic>? ?? [];
      _purchaseOrders = rawPo
          .whereType<Map<String, dynamic>>()
          .map((j) => PurchaseOrder.fromJson(j))
          .toList();
    } on AppException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load hospital resource status.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Schedules a diagnostic machine scan (MRI, CT, X-Ray, Ventilator).
  Future<bool> bookScan({
    required String patientId,
    required String equipment,
    required String date,
    required String slot,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newScan = await _resourceService.bookScan(
        patientId: patientId,
        equipment: equipment,
        date: date,
        slot: slot,
      );
      _allocations.add(newScan);
      // Reload resources to sync deducted machine availability
      await loadResources();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to book scan.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Admin action to overwrite hospital resource limits.
  Future<bool> updateResourceTotals(HospitalResource updated) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _resource = await _resourceService.updateResources(updated);
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update resource levels.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
