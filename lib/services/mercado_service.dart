// Felipe Ragonha
// RA: 24023900

//Juliano Perusso
//RA: 24023434

import 'package:cloud_functions/cloud_functions.dart';
import '../models/oferta.dart';

class MercadoService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'southamerica-east1',
  );

  Future<List<Oferta>> getOfertas() async {
    final callable = _functions.httpsCallable('listOrders');

    final result = await callable
        .call({'onlyOpen': true})
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw Exception('Tempo esgotado ao carregar ofertas.');
          },
        );

    final response = Map<String, dynamic>.from(result.data);

    final ofertasData = List<Map<String, dynamic>>.from(
      (response['data'] as List).map((item) => Map<String, dynamic>.from(item)),
    );

    return ofertasData.map((data) {
      return Oferta.fromJson(data['id'], data);
    }).toList();
  }

  Future<List<Oferta>> getOfertasPorStartup(String startupId) async {
    final callable = _functions.httpsCallable('listOrders');

    final result = await callable
        .call({'startupId': startupId, 'onlyOpen': true})
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw Exception('Tempo esgotado ao carregar ofertas.');
          },
        );

    final response = Map<String, dynamic>.from(result.data);

    final ofertasData = List<Map<String, dynamic>>.from(
      (response['data'] as List).map((item) => Map<String, dynamic>.from(item)),
    );

    return ofertasData.map((data) {
      return Oferta.fromJson(data['id'], data);
    }).toList();
  }

  Future<void> criarOferta({
    required String startupId,
    required String startupName,
    required String sector,
    required String stage,
    required int quantidade,
    required double preco,
  }) async {
    final callable = _functions.httpsCallable('placeOrder');

    await callable.call({
      'startupId': startupId,
      'startupName': startupName,
      'sector': sector,
      'stage': stage,
      'type': 'sell',
      'quantity': quantidade,
      'price': preco,
    });
  }

  Future<void> comprarToken({
    required String ofertaId,
    required int quantidade,
  }) async {
    final callable = _functions.httpsCallable('buyInvestorToken');

    await callable.call({'offerId': ofertaId, 'quantity': quantidade});
  }

  Future<void> cancelarOferta(String ofertaId) async {
    final callable = _functions.httpsCallable('cancelOrder');

    await callable.call({'offerId': ofertaId});
  }
}
