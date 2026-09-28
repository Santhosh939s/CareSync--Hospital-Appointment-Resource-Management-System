import 'package:flutter_test/flutter_test.dart';
import 'package:caresync_mobile/core/constants/app_constants.dart';
import 'package:caresync_mobile/models/resource.dart';

void main() {
  group('Resource & Capacity Calculations', () {
    test('Bed occupancy and threshold statuses', () {
      // Healthy status (> 50% available)
      const healthyBeds = BedResource(total: 50, available: 30);
      expect(healthyBeds.occupied, 20);
      expect(healthyBeds.availabilityRatio, 0.60);
      expect(healthyBeds.status, 'healthy');

      // Moderate status (20% - 50% available)
      const moderateBeds = BedResource(total: 50, available: 15);
      expect(moderateBeds.occupied, 35);
      expect(moderateBeds.availabilityRatio, 0.30);
      expect(moderateBeds.status, 'moderate');

      // Critical status (< 20% available)
      const criticalBeds = BedResource(total: 50, available: 8);
      expect(criticalBeds.occupied, 42);
      expect(criticalBeds.availabilityRatio, 0.16);
      expect(criticalBeds.status, 'critical');
    });

    test('Equipment machine calculations and safety status', () {
      const mri = EquipmentResource(total: 3, available: 2);
      expect(mri.inUse, 1);
      expect(mri.availabilityRatio, closeTo(0.66, 0.01));
      expect(mri.status, 'healthy');

      const fullyInUse = EquipmentResource(total: 2, available: 0);
      expect(fullyInUse.inUse, 2);
      expect(fullyInUse.status, 'critical');
    });

    test('HospitalResource entity parsing and blood bank threshold', () {
      final json = {
        'beds': {'total': 60, 'available': 25},
        'bloodBank': {
          'A+': 20,
          'A-': 5, // critical (<= 10)
          'B+': 35,
          'O+': 40,
        },
        'equipment': {
          'MRI': {'total': 2, 'available': 1},
          'CT-Scan': {'total': 3, 'available': 0},
        },
      };

      final resource = HospitalResource.fromJson(json);

      expect(resource.beds.total, 60);
      expect(resource.beds.available, 25);
      expect(resource.bloodBank['A+'], 20);
      expect(resource.bloodBank['A-'], 5);
      expect(resource.equipment['MRI']?.available, 1);
      expect(resource.equipment['CT-Scan']?.available, 0);
    });

    test('Time slot validation strictly excludes lunch hours 12:00 PM - 2:00 PM', () {
      expect(AppConstants.timeSlots.length, 5);
      expect(AppConstants.timeSlots, contains('10:00 AM'));
      expect(AppConstants.timeSlots, contains('11:00 AM'));
      expect(AppConstants.timeSlots, contains('02:00 PM'));
      expect(AppConstants.timeSlots, contains('03:00 PM'));
      expect(AppConstants.timeSlots, contains('04:00 PM'));

      // Ensure lunch break is NOT in selectable slots
      expect(AppConstants.timeSlots, isNot(contains('12:00 PM')));
      expect(AppConstants.timeSlots, isNot(contains('01:00 PM')));

      // Maximum 3 patients per slot rule
      expect(AppConstants.maxPatientsPerSlot, 3);
    });
  });
}
