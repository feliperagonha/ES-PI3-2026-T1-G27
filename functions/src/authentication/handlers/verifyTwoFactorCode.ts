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
    const update: Record<string, unknown> = {
      twoFactorCode: admin.firestore.FieldValue.delete(),
      twoFactorExpiry: admin.firestore.FieldValue.delete(),
    };

    // Se estiver ativando o 2FA, marca como ativado
    if (ativando === true) {
      update.twoFactorEnabled = true;
    }

    await db.collection("users").doc(uid).update(update);

    // Se for verificação de login (não ativação), retorna custom token
    if (!ativando) {
      const customToken = await admin.auth().createCustomToken(uid);
      return {
        success: true,
        token: customToken,
        message: "Código verificado com sucesso.",
      };
    }

    return {success: true, token: "", message: "2FA ativado com sucesso."};
  }
);
