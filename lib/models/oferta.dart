// Felipe Ragonha
// RA: 24023900

import 'package:cloud_firestore/cloud_firestore.dart';

class Oferta {
  final String id;
  final String startupId;
  final String startupName;
  final String sector;
  final String stage;
  final String vendedorId;
  final String vendedorNome;
  final int quantidade;
  final double preco;
  final String type;
  final String offerStatus;
  final DateTime? criadoEm;

  Oferta({
    required this.id,
    required this.startupId,
    required this.startupName,
    required this.sector,
    required this.stage,
    required this.vendedorId,
    required this.vendedorNome,
    required this.quantidade,
    required this.preco,
    required this.type,
    required this.offerStatus,
    this.criadoEm,
  });

  static DateTime? parseDate(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  factory Oferta.fromJson(String id, Map<String, dynamic> json) {
    return Oferta(
      id: id,
      startupId: json['startupId']?.toString() ?? '',
      startupName: json['startupName']?.toString() ?? '',
      sector: json['sector']?.toString() ?? '',
      stage: json['stage']?.toString() ?? '',
      vendedorId: json['vendedorId']?.toString() ?? '',
      vendedorNome: json['vendedorNome']?.toString() ?? 'Investidor',
      quantidade: (json['quantidade'] as num?)?.toInt() ?? 0,
      preco: (json['preco'] as num?)?.toDouble() ?? 0.0,
      type: json['type']?.toString() ?? 'sell',
      offerStatus: json['offerStatus']?.toString() ?? 'open',
      criadoEm: parseDate(json['criadoEm']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startupId': startupId,
      'startupName': startupName,
      'sector': sector,
      'stage': stage,
      'vendedorId': vendedorId,
      'vendedorNome': vendedorNome,
      'quantidade': quantidade,
      'preco': preco,
      'type': type,
      'offerStatus': offerStatus,
      'criadoEm': criadoEm,
    };
  }

  double get totalValue {
    return quantidade * preco;
  }
}