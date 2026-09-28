/// Financial transaction model (expense / income).
class Transaction {
  const Transaction({
    this.id,
    required this.type,
    required this.amount,
    required this.category,
    this.description = '',
    this.createdAt,
  });

  /// Database row id (null for unsaved items).
  final int? id;

  /// 'expense' or 'income'.
  final String type;

  /// Amount in minor units (e.g. cents) to avoid float issues.
  final int amount;

  /// Category key, e.g. 'food', 'transport', 'salary'.
  final String category;

  /// Free-text note.
  final String description;

  /// Creation timestamp.
  final DateTime? createdAt;

  static const String typeExpense = 'expense';
  static const String typeIncome = 'income';

  bool get isExpense => type == typeExpense;
  bool get isIncome => type == typeIncome;

  Transaction copyWith({
    int? id,
    String? type,
    int? amount,
    String? category,
    String? description,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'type': type,
      'amount': amount,
      'category': category,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, Object?> map) {
    return Transaction(
      id: map['id'] as int?,
      type: (map['type'] as String?) ?? typeExpense,
      amount: (map['amount'] as int?) ?? 0,
      category: (map['category'] as String?) ?? 'other',
      description: (map['description'] as String?) ?? '',
      createdAt: map['created_at'] is String
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, Object?> toJson() => toMap();

  factory Transaction.fromJson(Map<String, Object?> json) =>
      Transaction.fromMap(json);

  @override
  String toString() =>
      'Transaction(id: $id, type: $type, amount: $amount, category: $category)';
}
