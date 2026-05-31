// Felipe Ragonha
// RA: 24023900

import 'package:cloud_firestore/cloud_firestore.dart';

/// Status possíveis de uma pergunta
enum PerguntaStatus { pendente, respondida }

class Pergunta {
  final String id;

  /// ID do investidor que enviou a pergunta
  final String autorId;

  /// Nome de exibição do investidor (salvo no momento do envio)
  final String autorNome;

  /// Texto da pergunta enviada pelo investidor
  final String texto;

  /// Resposta dos sócios (null enquanto não respondida)
  final String? resposta;

  /// UID do sócio que respondeu (null enquanto não respondida)
  final String? respondidoPorId;

  /// Nome do sócio que respondeu (null enquanto não respondida)
  final String? respondidoPorNome;

  final PerguntaStatus status;
  final DateTime criadoEm;
  final DateTime? respondidoEm;

  const Pergunta({
    required this.id,
    required this.autorId,
    required this.autorNome,
    required this.texto,
    this.resposta,
    this.respondidoPorId,
    this.respondidoPorNome,
    required this.status,
    required this.criadoEm,
    this.respondidoEm,
  });

  factory Pergunta.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Pergunta.fromMap(doc.id, data);
  }

  factory Pergunta.fromMap(String id, Map<String, dynamic> data) {
    return Pergunta(
      id: id,
      autorId: data['autorId'] as String? ?? '',
      autorNome: data['autorNome'] as String? ?? 'Investidor',
      texto: data['texto'] as String? ?? '',
      resposta: data['resposta'] as String?,
      respondidoPorId: data['respondidoPorId'] as String?,
      respondidoPorNome: data['respondidoPorNome'] as String?,
      status: (data['status'] as String?) == 'respondida'
          ? PerguntaStatus.respondida
          : PerguntaStatus.pendente,
      criadoEm: _parseDate(data['criadoEm']) ?? DateTime.now(),
      respondidoEm: _parseDate(data['respondidoEm']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal();
    }

    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'autorId': autorId,
      'autorNome': autorNome,
      'texto': texto,
      'resposta': resposta,
      'respondidoPorId': respondidoPorId,
      'respondidoPorNome': respondidoPorNome,
      'status': status == PerguntaStatus.respondida ? 'respondida' : 'pendente',
      'criadoEm': FieldValue.serverTimestamp(),
      'respondidoEm': respondidoEm != null
          ? Timestamp.fromDate(respondidoEm!)
          : null,
    };
  }
}
