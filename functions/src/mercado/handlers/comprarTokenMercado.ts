// Felipe Ragonha
// RA: 24023900

import {HttpsError, onCall} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

const db = admin.firestore();

export const comprarTokenMercado = onCall(
  {region: "southamerica-east1"},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Logue para operar.");
    }

    const compradorId = request.auth.uid;
    const {ofertaId} = request.data;

    if (!ofertaId) {
      throw new HttpsError("invalid-argument", "ID da oferta inválido.");
    }

    const ofertaRef = db.collection("mercado").doc(ofertaId);

    await db.runTransaction(async (transaction) => {
      const ofertaSnap = await transaction.get(ofertaRef);

      if (!ofertaSnap.exists) {
        throw new HttpsError("not-found", "Oferta não encontrada ou já foi vendida.");
      }

      const oferta = ofertaSnap.data()!;

      if (oferta.vendedorId === compradorId) {
        throw new HttpsError("failed-precondition", "Você não pode comprar sua própria oferta.");
      }

      const {startupId, startupName, quantidade, preco, vendedorId} = oferta;

      const investCompradorRef = db
        .collection("usuarios").doc(compradorId)
        .collection("investimentos").doc(startupId);

      const investVendedorRef = db
        .collection("usuarios").doc(vendedorId)
        .collection("investimentos").doc(startupId);

      const [investVendedorSnap, investCompradorSnap] = await Promise.all([
        transaction.get(investVendedorRef),
        transaction.get(investCompradorRef),
      ]);

      const tokensVendedor = investVendedorSnap.data()?.totalShares ?? 0;
      if (tokensVendedor < quantidade) {
        throw new HttpsError("failed-precondition", "Vendedor não possui tokens suficientes.");
      }

      transaction.update(investVendedorRef, {
        totalShares: admin.firestore.FieldValue.increment(-quantidade),
      });

      if (investCompradorSnap.exists) {
        transaction.update(investCompradorRef, {
          totalShares: admin.firestore.FieldValue.increment(quantidade),
        });
      } else {
        transaction.set(investCompradorRef, {
          startupId,
          startupName,
          totalShares: quantidade,
          averagePrice: preco,
        });
      }

      transaction.set(
        db.collection("usuarios").doc(compradorId).collection("historico").doc(),
        {
          tipo: "compra_mercado",
          startupId,
          startupName,
          quantidade,
          preco,
          total: preco * quantidade,
          contraparte: vendedorId,
          criadoEm: admin.firestore.FieldValue.serverTimestamp(),
        }
      );

      transaction.set(
        db.collection("usuarios").doc(vendedorId).collection("historico").doc(),
        {
          tipo: "venda_mercado",
          startupId,
          startupName,
          quantidade,
          preco,
          total: preco * quantidade,
          contraparte: compradorId,
          criadoEm: admin.firestore.FieldValue.serverTimestamp(),
        }
      );

      transaction.delete(ofertaRef);
    });

    return {success: true, message: "Compra realizada com sucesso."};
  }
);
