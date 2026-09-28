/// Model representing hospital resources: Beds, Blood Bank, and Equipment.
///
/// Corresponds to the singleton Resource document in MongoDB.
class HospitalResource {
  final BedResource beds;
  final Map<String, int> bloodBank;
  final Map<String, EquipmentResource> equipment;

  const HospitalResource({
    required this.beds,
    required this.bloodBank,
    required this.equipment,
  });

  factory HospitalResource.fromJson(Map<String, dynamic> json) {
    // Beds
    final bedsJson = json['beds'] as Map<String, dynamic>? ?? {};
    final beds = BedResource.fromJson(bedsJson);

    // Blood Bank
    final bloodBankJson = json['bloodBank'] as Map<String, dynamic>? ?? {};
    final bloodBank = <String, int>{};
    bloodBankJson.forEach((key, value) {
      bloodBank[key] = (value as num?)?.toInt() ?? 0;
    });

    // Equipment
    final equipmentJson = json['equipment'] as Map<String, dynamic>? ?? {};
    final equipment = <String, EquipmentResource>{};
    equipmentJson.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        equipment[key] = EquipmentResource.fromJson(value);
      }
    });

    return HospitalResource(
      beds: beds,
      bloodBank: bloodBank,
      equipment: equipment,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'beds': beds.toJson(),
      'bloodBank': bloodBank,
      'equipment': equipment.map((k, v) => MapEntry(k, v.toJson())),
    };
  }

  HospitalResource copyWith({
    BedResource? beds,
    Map<String, int>? bloodBank,
    Map<String, EquipmentResource>? equipment,
  }) {
    return HospitalResource(
      beds: beds ?? this.beds,
      bloodBank: bloodBank ?? this.bloodBank,
      equipment: equipment ?? this.equipment,
    );
  }
}

class BedResource {
  final int total;
  final int available;

  const BedResource({
    this.total = 50,
    this.available = 22,
  });

  int get occupied => (total - available).clamp(0, total);
  double get availabilityRatio => total > 0 ? (available / total) : 0.0;
  double get occupancyRatio => total > 0 ? (occupied / total) : 0.0;

  /// Threshold status: 'critical' (<20%), 'moderate' (20-50%), 'healthy' (>50%)
  String get status {
    if (availabilityRatio < 0.20) return 'critical';
    if (availabilityRatio <= 0.50) return 'moderate';
    return 'healthy';
  }

  factory BedResource.fromJson(Map<String, dynamic> json) {
    return BedResource(
      total: (json['total'] as num?)?.toInt() ?? 50,
      available: (json['available'] as num?)?.toInt() ?? 22,
    );
  }

  Map<String, dynamic> toJson() => {
    'total': total,
    'available': available,
  };
}

class EquipmentResource {
  final int total;
  final int available;

  const EquipmentResource({
    this.total = 1,
    this.available = 1,
  });

  int get inUse => (total - available).clamp(0, total);
  double get availabilityRatio => total > 0 ? (available / total) : 0.0;

  /// Threshold: 'critical' (0 or available <= 1 with total >= 3), 'healthy'
  String get status {
    if (available == 0) return 'critical';
    if (availabilityRatio <= 0.33) return 'moderate';
    return 'healthy';
  }

  factory EquipmentResource.fromJson(Map<String, dynamic> json) {
    return EquipmentResource(
      total: (json['total'] as num?)?.toInt() ?? 1,
      available: (json['available'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'total': total,
    'available': available,
  };
}
