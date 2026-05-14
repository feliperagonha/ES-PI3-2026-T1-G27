// Felipe Ragonha
// RA: 24023900

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pergunta_model.dart';

/// Serviço responsável por operações na subcoleção
/// startups/{startupId}/perguntas
class PerguntaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Referência à subcoleção

  CollectionReference<Map<String, dynamic>> _col(String startupId) =>
      _db.collection('startups').doc(startupId).collection('perguntas');

  // Verificação: usuário é investidor da startup?

  /// Retorna true se o usuário atual possui ao menos 1 token da startup.
  /// A verificação é feita na coleção "portfolios/{uid}/tokens"
  /// onde cada documento tem o campo "startupId".
  ///
  /// Ajuste o caminho se a sua coleção de portfólio tiver outro nome.
  Future<bool> isInvestidor(String startupId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    // Busca no portfólio do usuário se há tokens desta startup
    final query = await _db
        .collection('portfolios')
        .doc(uid)
        .collection('tokens')
        .where('startupId', isEqualTo: startupId)
        .where('quantidade', isGreaterThan: 0)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  // Verificação: usuário é sócio (founder) da startup?

  /// Retorna true se o uid do usuário atual está listado como fundador.
  /// Verifica no documento da startup se há um campo "founderUids" (lista de UIDs).
  ///
  /// Se ainda não tiver este campo no Firestore, pode adicioná-lo ou
  /// ajustar a lógica aqui para usar outro campo.
  Future<bool> isSocio(String startupId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final doc = await _db.collection('startups').doc(startupId).get();
    if (!doc.exists) return false;

    final data = doc.data();
    final founderUids = List<String>.from(data?['founderUids'] ?? []);
    return founderUids.contains(uid);
  }

  // CRUD de perguntas

  /// Envia uma nova pergunta (somente investidores autorizados).
  /// Lança [Exception] se o usuário não for investidor.
  Future<void> enviarPergunta({
    required String startupId,
    required String texto,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado.');

    final investidor = await isInvestidor(startupId);
    if (!investidor) {
      throw Exception(
        'Acesso negado: apenas investidores desta startup podem enviar perguntas.',
      );
    }

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

  /// Busca as perguntas visíveis para o usuário atual:
  /// - Se for sócio: retorna TODAS as perguntas da startup.
  /// - Se for investidor: retorna apenas as perguntas que ele mesmo fez.
  /// - Caso contrário: retorna lista vazia.
  Future<List<Pergunta>> getPerguntas(String startupId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final socio = await isSocio(startupId);

    QuerySnapshot<Map<String, dynamic>> snapshot;

    if (socio) {
      // Sócios veem tudo, ordenado por data
      snapshot = await _col(startupId)
          .orderBy('criadoEm', descending: true)
          .get();
    } else {
      // Investidor vê apenas suas próprias perguntas
      final investidor = await isInvestidor(startupId);
      if (!investidor) return [];

      snapshot = await _col(startupId)
          .where('autorId', isEqualTo: uid)
          .orderBy('criadoEm', descending: true)
          .get();
    }

    return snapshot.docs.map(Pergunta.fromDoc).toList();
  }

  /// Responde a uma pergunta (somente sócios).
  /// Lança [Exception] se o usuário não for sócio.
  Future<void> responderPergunta({
    required String startupId,
    required String perguntaId,
    required String resposta,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado.');

    final socio = await isSocio(startupId);
    if (!socio) {
      throw Exception(
        'Acesso negado: apenas sócios podem responder perguntas.',
      );
    }

    final nome = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!
        : user.email ?? 'Sócio';

    await _col(startupId).doc(perguntaId).update({
      'resposta': resposta.trim(),
      'respondidoPorId': user.uid,
      'respondidoPorNome': nome,
      'status': 'respondida',
      'respondidoEm': FieldValue.serverTimestamp(),
    });
  }
}
