// Felipe Ragonha
// RA: 24023900

import {HttpsError, onCall} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

const db = admin.firestore();

export const venderToken = onCall(
  {region: "southamerica-east1"},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Logue para operar.");
    }

    const uid = request.auth.uid;
    const {startupId, startupName, startupSector, startupStage, quantidade, preco} = request.data;

    if (!startupId || !startupName) {
      throw new HttpsError("invalid-argument", "Startup inválida.");
    }
    if (!quantidade || quantidade <= 0) {
      throw new HttpsError("invalid-argument", "Quantidade inválida.");
    }
    if (!preco || preco <= 0) {
      throw new HttpsError("invalid-argument", "Preço inválido.");
    }

    const userDoc = await db.collection("users").doc(uid).get();
    const vendedorNome = userDoc.data()?.name ?? "Investidor";

    await db.collection("mercado").add({
      startupId,
      startupName,
      startupSector: startupSector ?? "",
      startupStage: startupStage ?? "",
      vendedorId: uid,
      vendedorNome,
      quantidade,
      preco,
      criadoEm: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {success: true, message: "Oferta criada com sucesso."};
  }
);
