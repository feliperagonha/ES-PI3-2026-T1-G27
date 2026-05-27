
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pergunta_model.dart';

/// Serviço responsável por operações na subcoleção
/// startups/{startupId}/perguntas
class PublicPerguntaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── Referência à subcoleção ─────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _col(String startupId) =>
      _db.collection('startups').doc(startupId).collection('perguntas_publicas');

  // ─── Verificação: usuário é investidor da startup? ────────────────────────────
  //
  // Os tokens ficam registrados na coleção "transactions".
  // Cada doc tem: compradorId/buyerId, vendedorId/sellerId, startupId, quantidade/quantity.
  // Saldo = Σ compras - Σ vendas. Se saldo > 0 → é investidor ativo.

  Future<bool> isInvestidor(String startupId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final snap = await _db
        .collection('transactions')
        .where('startupId', isEqualTo: startupId)
        .get();

    int saldo = 0;

    for (final doc in snap.docs) {
      final data = doc.data();
      final quantidade =
          (data['quantidade'] ?? data['quantity'] ?? 0) as num;

      if (quantidade <= 0) continue;

      if (data['compradorId'] == uid || data['buyerId'] == uid) {
        saldo += quantidade.toInt();
      }

      if (data['vendedorId'] == uid || data['sellerId'] == uid) {
        saldo -= quantidade.toInt();
      }
    }

    return saldo > 0;
  }

  // ─── Verificação: usuário é sócio (founder) da startup? ──────────────────────
  //
  // Verifica o campo "founderUids" (lista de UIDs) no documento da startup.
  // Adicione esse campo no Firestore com os UIDs dos fundadores de cada startup.

  Future<bool> isSocio(String startupId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final doc = await _db.collection('startups').doc(startupId).get();
    if (!doc.exists) return false;

    final data = doc.data();
    final founderUids = List<String>.from(data?['founderUids'] ?? []);
    return founderUids.contains(uid);
  }

  // ─── CRUD de perguntas ────────────────────────────────────────────────────────

  /// Envia uma nova pergunta (somente investidores com saldo > 0).
  Future<void> enviarPergunta({
    required String startupId,
    required String texto,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado.');


    final nome = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!
        : user.email ?? 'Investidor';

    await _col(startupId).add({
      'autorId': user.uid,
      'autorNome': nome,
      'texto': texto.trim(),
      'resposta': null,
      'respondidoPorId': null,
      'respondidoPorNome': null,
      'status': 'pendente',
      'criadoEm': FieldValue.serverTimestamp(),
      'respondidoEm': null,
    });
  }

  Future<List<Pergunta>> getPerguntas(String startupId) async {
  final snapshot = await _col(startupId)
      .orderBy('criadoEm', descending: true)
      .get();

  return snapshot.docs.map(Pergunta.fromDoc).toList();
}