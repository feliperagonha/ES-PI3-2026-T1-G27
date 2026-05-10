// Felipe Ragonha
// RA: 24023900

import {HttpsError, onCall} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

const db = admin.firestore();

export const verifyTwoFactorCode = onCall(
  {region: "southamerica-east1"},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Logue para operar.");
    }

    const uid = request.auth.uid;
    const {code, ativando} = request.data;

    if (!code) {
      throw new HttpsError("invalid-argument", "Código inválido.");
    }

    const userDoc = await db.collection("users").doc(uid).get();
    const data = userDoc.data();

    if (!data) {
      throw new HttpsError("not-found", "Usuário não encontrado.");
    }

    const storedCode = data.twoFactorCode;
    const expiry = data.twoFactorExpiry?.toDate() as Date | undefined;

    // Verifica se o código existe e não expirou
    if (!storedCode || !expiry) {
      throw new HttpsError("failed-precondition", "Nenhum código solicitado.");
    }

    if (new Date() > expiry) {
      throw new HttpsError("deadline-exceeded", "Código expirado. Solicite um novo.");
    }

    if (storedCode !== code) {
      throw new HttpsError("invalid-argument", "Código incorreto.");
    }

    // Código válido: limpa e atualiza twoFactorEnabled se estiver ativando
    const update: Record<string, unknown> = {
      twoFactorCode: admin.firestore.FieldValue.delete(),
      twoFactorExpiry: admin.firestore.FieldValue.delete(),
    };

    if (ativando === true) {
      update.twoFactorEnabled = true;
    }

    await db.collection("users").doc(uid).update(update);

    return {success: true, message: "Código verificado com sucesso."};
  }
);
