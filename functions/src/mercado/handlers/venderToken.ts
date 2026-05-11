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

    // Verifica se o usuário tem tokens suficientes
    const investimentoRef = db
      .collection("users").doc(uid)
      .collection("investimentos").doc(startupId);

    const investimentoSnap = await investimentoRef.get();

    if (!investimentoSnap.exists) {
      throw new HttpsError(
        "failed-precondition",
        "Você não possui tokens desta startup."
      );
    }

    const totalShares = investimentoSnap.data()?.totalShares ?? 0;

    if (totalShares < quantidade) {
      throw new HttpsError(
        "failed-precondition",
        `Tokens insuficientes. Você possui ${totalShares} token${totalShares !== 1 ? "s" : ""} desta startup.`
      );
    }

    // Verifica se já tem ofertas abertas e soma
    const ofertasSnap = await db
      .collection("mercado")
      .where("vendedorId", "==", uid)
      .where("startupId", "==", startupId)
      .get();

    const tokensJaAnunciados = ofertasSnap.docs.reduce(
      (acc, doc) => acc + (doc.data().quantidade ?? 0), 0
    );

    if (tokensJaAnunciados + quantidade > totalShares) {
      throw new HttpsError(
        "failed-precondition",
        `Você já tem ${tokensJaAnunciados} token${tokensJaAnunciados !== 1 ? "s" : ""} anunciado${tokensJaAnunciados !== 1 ? "s" : ""}. Disponível para venda: ${totalShares - tokensJaAnunciados}.`
      );
    }

    // Busca nome do usuário
    const userDoc = await db.collection("users").doc(uid).get();
    const vendedorNome = userDoc.data()?.name ?? "Investidor";

    // Cria a oferta
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
