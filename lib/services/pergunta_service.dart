// Felipe Ragonha
// RA: 24023900

import 'package:cloud_functions/cloud_functions.dart';

import '../models/pergunta_model.dart';

class PerguntasPrivadasState {
  final bool isInvestidor;
  final bool isSocio;
  final List<Pergunta> perguntas;

  const PerguntasPrivadasState({
    required this.isInvestidor,
    required this.isSocio,
    required this.perguntas,
  });
}

class PerguntaService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'southamerica-east1',
  );

  Future<PerguntasPrivadasState> getPerguntasPrivadas(String startupId) async {
    final result = await _functions.httpsCallable('listPrivateQuestions').call({
      'startupId': startupId,
    });

    final response = Map<String, dynamic>.from(result.data);
    final items = List<Map<String, dynamic>>.from(
      ((response['data'] ?? []) as List).map(
        (item) => Map<String, dynamic>.from(item),
      ),
    );

    return PerguntasPrivadasState(
      isInvestidor: response['isInvestor'] == true,
      isSocio: response['isFounder'] == true,
      perguntas: items.map((item) {
        return Pergunta.fromMap(item['id']?.toString() ?? '', item);
      }).toList(),
    );
  }

  Future<bool> isInvestidor(String startupId) async {
    return (await getPerguntasPrivadas(startupId)).isInvestidor;
  }

  Future<bool> isSocio(String startupId) async {
    return (await getPerguntasPrivadas(startupId)).isSocio;
  }

  Future<List<Pergunta>> getPerguntas(String startupId) async {
    return (await getPerguntasPrivadas(startupId)).perguntas;
  }

  Future<void> enviarPergunta({
    required String startupId,
    required String texto,
  }) async {
    await _functions.httpsCallable('createPrivateQuestion').call({
      'startupId': startupId,
      'texto': texto,
    });
  }

  Future<void> responderPergunta({
    required String startupId,
    required String perguntaId,
    required String resposta,
  }) async {
    await _functions.httpsCallable('answerPrivateQuestion').call({
      'startupId': startupId,
      'perguntaId': perguntaId,
      'resposta': resposta,
    });
  }
}
