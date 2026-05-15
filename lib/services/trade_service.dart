// Arthur Sebastian Guarniz de Castro
// RA: 24795528

import 'package:cloud_functions/cloud_functions.dart';

class TradeService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'southamerica-east1',
  );

  Future<void> addSimulatedBalance(double amount) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('addBalance');
      await callable.call({'amount': amount});
    } catch (_) {
      throw Exception('Falha ao processar deposito.');
    }
  }

  Future<void> placeOrder({
    required String startupId,
    required String type,
    required int quantity,
    required double price,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('placeOrder');
      await callable.call({
        'startupId': startupId,
        'type': type,
        'quantity': quantity,
        'price': price,
      });
    } catch (_) {
      throw Exception(
        'Transacao recusada. Verifique seu saldo ou os detalhes da ordem.',
      );
    }
  }
}
