// Felipe Ragonha
// RA: 24023900

import {HttpsError, onCall} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

export const verifyTwoFactorLogin = onCall(
  {region: "southamerica-east1"},
  async (request) => {
    const {uid, code} = request.data;

    if (!uid || !code) {
      throw new HttpsError("invalid-argument", "UID e código são obrigatórios.");
    }

    const userDoc = await db.collection("users").doc(uid).get();
    const data = userDoc.data();

    if (!data) {
      throw new HttpsError("not-found", "Usuário não encontrado.");
    }

    const storedCode = data.twoFactorCode;
    const expiry = data.twoFactorExpiry?.toDate() as Date | undefined;

    if (!storedCode || !expiry) {
      throw new HttpsError("failed-precondition", "Nenhum código solicitado.");
    }

    if (new Date() > expiry) {
      throw new HttpsError("deadline-exceeded", "Código expirado. Solicite um novo.");
    }

    if (storedCode !== code) {
      throw new HttpsError("invalid-argument", "Código incorreto.");
    }

    // Limpa o código usado
    await db.collection("users").doc(uid).update({
      twoFactorCode: admin.firestore.FieldValue.delete(),
      twoFactorExpiry: admin.firestore.FieldValue.delete(),
    });

    // Gera o custom token para logar
    const customToken = await admin.auth().createCustomToken(uid);

    return {
      success: true,
      token: customToken,
      message: "Login realizado com sucesso.",
    };
  }
);
