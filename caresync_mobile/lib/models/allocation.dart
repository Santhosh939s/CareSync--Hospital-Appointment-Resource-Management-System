/// Represents a resource allocation record (Beds, Blood, Scan machines).
///
/// Maps to the Allocation collection in MongoDB.
class Allocation {
  final String id;
  final String type;
  final String patientId;
  final int amount;
  final String date;
  final String? slot;
  final String status;

  const Allocation({
    required this.id,
    required this.type,
    required this.patientId,
    this.amount = 1,
    required this.date,
    this.slot,
    this.status = 'Scheduled',
  });

  factory Allocation.fromJson(Map<String, dynamic> json) {
    return Allocation(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      patientId: json['patientId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 1,
      date: json['date'] as String? ?? '',
      slot: json['slot'] as String?,
      status: json['status'] as String? ?? 'Scheduled',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'patientId': patientId,
      'amount': amount,
      'date': date,
      if (slot != null) 'slot': slot,
      'status': status,
    };
  }

  Allocation copyWith({
    String? id,
    String? type,
    String? patientId,
    int? amount,
    String? date,
    String? slot,
    String? status,
  }) {
    return Allocation(
      id: id ?? this.id,
      type: type ?? this.type,
      patientId: patientId ?? this.patientId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      slot: slot ?? this.slot,
      status: status ?? this.status,
    );
  }
}
