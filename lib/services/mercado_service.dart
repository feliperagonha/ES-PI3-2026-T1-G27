// Felipe Ragonha
// RA: 24023900

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/oferta.dart';

class MercadoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mesma região
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'southamerica-east1',
  );

  // Stream das ofertas ativas agrupadas por startup
  Stream<List<Oferta>> getOfertas() {
    return _firestore
        .collection('mercado')
        .orderBy('criadoEm', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Oferta.fromJson(d.id, d.data())).toList());
  }

  // Stream de ofertas de uma startup específica
  Stream<List<Oferta>> getOfertasPorStartup(String startupId) {
    return _firestore
        .collection('mercado')
        .where('startupId', isEqualTo: startupId)
        .orderBy('preco')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Oferta.fromJson(d.id, d.data())).toList());
  }

  // Criar oferta de venda via Cloud Function
  Future<void> criarOferta({
    required String startupId,
    required String startupName,
    required String startupSector,
    required String startupStage,
    required int quantidade,
    required double preco,
  }) async {
    final callable = _functions.httpsCallable('venderToken');
    await callable.call({
      'startupId': startupId,
      'startupName': startupName,
      'startupSector': startupSector,
      'startupStage': startupStage,
      'quantidade': quantidade,
      'preco': preco,
    });
  }

  // Comprar token via Cloud Function
  Future<void> comprarToken({required String ofertaId}) async {
    final callable = _functions.httpsCallable('comprarTokenMercado');
    await callable.call({'ofertaId': ofertaId});
  }

  // Cancelar oferta própria direto no Firestore
  Future<void> cancelarOferta(String ofertaId) async {
    await _firestore.collection('mercado').doc(ofertaId).delete();
  }
}
