class InvoiceEntity {
  final String id;
  final String tripId;
  final String customerId;
  final String customerName;
  final String invoiceNumber;
  final double amount;
  final String status; // draft, sent, paid, void
  final DateTime issueDate;
  final DateTime dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const InvoiceEntity({
    required this.id,
    required this.tripId,
    required this.customerId,
    required this.customerName,
    required this.invoiceNumber,
    required this.amount,
    this.status = 'draft',
    required this.issueDate,
    required this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'customerId': customerId,
      'customerName': customerName,
      'invoiceNumber': invoiceNumber,
      'amount': amount,
      'status': status,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory InvoiceEntity.fromMap(Map<String, dynamic> map) {
    return InvoiceEntity(
      id: map['id'] as String? ?? '',
      tripId: map['tripId'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      invoiceNumber: map['invoiceNumber'] as String? ?? '',
      amount: (map['amount'] as num? ?? 0.0).toDouble(),
      status: map['status'] as String? ?? 'draft',
      issueDate: map['issueDate'] != null
          ? DateTime.parse(map['issueDate'] as String)
          : DateTime.now(),
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'] as String)
          : DateTime.now(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
      deletedAt: map['deletedAt'] != null
          ? DateTime.parse(map['deletedAt'] as String)
          : null,
    );
  }

  InvoiceEntity copyWith({
    String? id,
    String? tripId,
    String? customerId,
    String? customerName,
    String? invoiceNumber,
    double? amount,
    String? status,
    DateTime? issueDate,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return InvoiceEntity(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
