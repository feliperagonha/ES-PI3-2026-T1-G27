import 'package:cloud_functions/cloud_functions.dart';

import '../models/pergunta_model.dart';

class PublicPerguntaService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'southamerica-east1',
  );

  Future<void> enviarPergunta({
    required String startupId,
    required String texto,
  }) async {
    await _functions.httpsCallable('createPublicQuestion').call({
      'startupId': startupId,
      'texto': texto,
    });
  }

  Future<List<Pergunta>> getPerguntas(String startupId) async {
    final result = await _functions.httpsCallable('listPublicQuestions').call({
      'startupId': startupId,
    });

    final response = Map<String, dynamic>.from(result.data);
    final items = List<Map<String, dynamic>>.from(
      ((response['data'] ?? []) as List).map(
        (item) => Map<String, dynamic>.from(item),
      ),
    );

    return items.map((item) {
      return Pergunta.fromMap(item['id']?.toString() ?? '', item);
    }).toList();
  }

  Future<void> responderPergunta({
    required String startupId,
    required String perguntaId,
    required String resposta,
  }) async {
    await _functions.httpsCallable('answerPublicQuestion').call({
      'startupId': startupId,
      'perguntaId': perguntaId,
      'resposta': resposta,
    });
  }
}
