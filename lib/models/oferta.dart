// lib/models/oferta.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Oferta {
  final String id;
  final String startupId;
  final String startupName;
  final String startupSector;
  final String startupStage;
  final String vendedorId;
  final String vendedorNome;
  final int quantidade;
  final double preco;
  final DateTime? criadoEm;

  const Oferta({
    required this.id,
    required this.startupId,
    required this.startupName,
    required this.startupSector,
    required this.startupStage,
    required this.vendedorId,
    required this.vendedorNome,
    required this.quantidade,
    required this.preco,
    this.criadoEm,
  });

  factory Oferta.fromJson(String id, Map<String, dynamic> json) {
    return Oferta(
      id: id,
      startupId: json['startupId'] ?? '',
      startupName: json['startupName'] ?? '',
      startupSector: json['startupSector'] ?? '',
      startupStage: json['startupStage'] ?? '',
      vendedorId: json['vendedorId'] ?? '',
      vendedorNome: json['vendedorNome'] ?? '',
      quantidade: ((json['quantidade'] ?? 0) as num).toInt(),
      preco: ((json['preco'] ?? 0) as num).toDouble(),
      criadoEm: json['criadoEm'] != null
          ? (json['criadoEm'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startupId': startupId,
      'startupName': startupName,
      'startupSector': startupSector,
      'startupStage': startupStage,
      'vendedorId': vendedorId,
      'vendedorNome': vendedorNome,
      'quantidade': quantidade,
      'preco': preco,
      'criadoEm': FieldValue.serverTimestamp(),
    };
  }
}
