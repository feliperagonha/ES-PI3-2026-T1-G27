// Felipe Ragonha
// RA: 24023900

import {HttpsError, onCall} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

const db = admin.firestore();

export const sendTwoFactorCode = onCall(
  {region: "southamerica-east1"},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Logue para operar.");
    }

    const uid = request.auth.uid;

    // Gera código de 6 dígitos
    const code = Math.floor(100000 + Math.random() * 900000).toString();

    // Expira em 10 minutos
    const expiry = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 10 * 60 * 1000)
    );

    // Salva no Firestore
    await db.collection("users").doc(uid).update({
      twoFactorCode: code,
      twoFactorExpiry: expiry,
    });

    // Busca o email do usuário
    const userRecord = await admin.auth().getUser(uid);
    const email = userRecord.email;

    if (!email) {
      throw new HttpsError("not-found", "Email não encontrado.");
    }

    console.log(`[2FA] Código ${code} enviado para ${email}`);

    return {success: true, message: "Código enviado para seu email."};
  }
);
