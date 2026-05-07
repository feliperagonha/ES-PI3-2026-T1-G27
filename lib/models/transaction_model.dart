//Arthur Sebastian Guarniz de Castro
//24795528

import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String userId;
  final double
  amount; //Valor da transação (positivo para depósito, negativo para saque/compra)
  final String description; // Ex:"Depósito via Pix"
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
      //Usa o 'as Timestamp' para o Flutter entender de onde vem o .toDate()
      date: json['date'] != null ? (json['date'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'userId': userId, 'amount': amount, 'description': description};
  }
}
