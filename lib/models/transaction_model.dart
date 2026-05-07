//Arthur Sebastian Guarniz de Castro
//24795528

class TransactionModel {
  final String id;
  final String userId;
  final double
  amount; //Valor da transação (positivo para depósito, negativo para saque/compra)
  final String
  description; //Ex: "Depósito via Pix", "Compra de cotas da Startup X"
  final DateTime? date;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.description,
    this.date,
  });

  factory TransactionModel.fromJson(
    Map<String, dynamic> json,
    String documentId,
  ) {
    return TransactionModel(
      id: documentId,
      userId: json['userId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      date: json['date'] != null ? json['date'].toDate() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'userId': userId, 'amount': amount, 'description': description};
  }
}
