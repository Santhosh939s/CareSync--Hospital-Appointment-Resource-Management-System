/// Purchase Order triggered when hospital resources reach safety thresholds.
///
/// Maps to the PurchaseOrder collection in MongoDB.
class PurchaseOrder {
  final String prId;
  final String material;
  final int quantityReq;
  final String date;
  final String status;

  const PurchaseOrder({
    required this.prId,
    required this.material,
    required this.quantityReq,
    required this.date,
    this.status = 'Created',
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      prId: json['prId'] as String? ?? '',
      material: json['material'] as String? ?? '',
      quantityReq: (json['quantityReq'] as num?)?.toInt() ?? 0,
      date: json['date'] as String? ?? '',
      status: json['status'] as String? ?? 'Created',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prId': prId,
      'material': material,
      'quantityReq': quantityReq,
      'date': date,
      'status': status,
    };
  }
}
