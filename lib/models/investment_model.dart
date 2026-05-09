//Arthur Sebastian Guarniz de Castro
//24795528

class InvestmentModel {
  final String id;
  final String startupId;
  final int totalShares; //Total de cotas que o usuário possui desta startup
  final double averagePrice; //Preço médio pago pelas cotas

  InvestmentModel({
    required this.id,
    required this.startupId,
    required this.totalShares,
    required this.averagePrice,
  });

  factory InvestmentModel.fromJson(
    Map<String, dynamic> json,
    String documentId,
  ) {
    return InvestmentModel(
      id: documentId,
      startupId: json['startupId'] ?? '',
      totalShares: json['totalShares'] ?? 0,
      averagePrice: (json['averagePrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startupId': startupId,
      'totalShares': totalShares,
      'averagePrice': averagePrice,
    };
  }
}
