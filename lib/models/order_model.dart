//Arthur Sebastian Guarniz de Castro
//24795528

class OrderModel {
  final String id;
  final String userId;
  final String startupId;
  final String type; //'buy' (comprar) ou 'sell' (vender)
  final int quantity; //Quantidade de cotas/ações
  final double price; //Preço unitário na hora da ordem
  final String
  status; //'open' (aberta), 'completed' (concluída), 'cancelled' (cancelada)
  final DateTime? createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.startupId,
    required this.type,
    required this.quantity,
    required this.price,
    required this.status,
    this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json, String documentId) {
    return OrderModel(
      id: documentId,
      userId: json['userId'] ?? '',
      startupId: json['startupId'] ?? '',
      type: json['type'] ?? 'buy',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      status: json['status'] ?? 'open',
      //Verifica se a data existe antes de converter do Firestore Timestamp
      createdAt: json['createdAt'] != null ? json['createdAt'].toDate() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'startupId': startupId,
      'type': type,
      'quantity': quantity,
      'price': price,
      'status': status,
      //Aviso: Ao criar no banco, o ideal é usar FieldValue.serverTimestamp() direto na chamada do Firestore
    };
  }
}
