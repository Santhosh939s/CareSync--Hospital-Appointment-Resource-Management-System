/// Financial ledger entry for CareSync billing (FI/CO).
///
/// Maps to the FinancialLedger collection in MongoDB.
class FinancialLedger {
  final String docId;
  final String patientId;
  final String type;
  final double amount;
  final String date;
  final String status;

  const FinancialLedger({
    required this.docId,
    required this.patientId,
    required this.type,
    required this.amount,
    required this.date,
    this.status = 'Posted',
  });

  factory FinancialLedger.fromJson(Map<String, dynamic> json) {
    return FinancialLedger(
      docId: json['docId'] as String? ?? '',
      patientId: json['patientId'] as String? ?? '',
      type: json['type'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] as String? ?? '',
      status: json['status'] as String? ?? 'Posted',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'docId': docId,
      'patientId': patientId,
      'type': type,
      'amount': amount,
      'date': date,
      'status': status,
    };
  }
}
