//Arthur Sebastian Gurniz de Castro
//24795528

import 'package:cloud_functions/cloud_functions.dart';

class TradeService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  //1. Chama a função de depositar dinheiro
  Future<void> addSimulatedBalance(double amount) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('addBalance');

      //Envia apenas o valor. O servidor já sabe quem é o usuário pela sessão!
      final response = await callable.call({'amount': amount});

      print('Sucesso: ${response.data['message']}');
    } catch (e) {
      print('Erro ao adicionar saldo: $e');
      throw Exception('Falha ao processar depósito.');
    }
  }

  //2. Chama a função de comprar ou vender tokens
  Future<void> placeOrder({
    required String startupId,
    required String type, //'buy' ou 'sell'
    required int quantity,
    required double price,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('placeOrder');

      final response = await callable.call({
        'startupId': startupId,
        'type': type,
        'quantity': quantity,
        'price': price,
      });

      print('Sucesso: ${response.data['message']}');
    } catch (e) {
      print('Erro ao enviar ordem: $e');
      throw Exception(
        'Transação recusada. Verifique seu saldo ou os detalhes da ordem.',
      );
    }
  }
}
