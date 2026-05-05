import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

if (!admin.apps.length) {
  admin.initializeApp();
}

export const recuperarSenha = onCall(
  {region: "southamerica-east1"},
  async (request) => {
    const email = request.data?.email;

    if (!email || typeof email !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "Informe um e-mail válido."
      );
    }

    try {
      const actionCodeSettings = {
        url: "https://mesclainvest.firebaseapp.com/login",
        handleCodeInApp: false,
      };

      const link = await admin
        .auth()
        .generatePasswordResetLink(email, actionCodeSettings);

      logger.info("Link de recuperação de senha gerado", {email});

      return {
        success: true,
        message: "Link de recuperação de senha gerado com sucesso.",
        resetLink: link,
      };
    } catch (error) {
      logger.error("Erro ao gerar link de recuperação", error);

      throw new HttpsError(
        "not-found",
        "Não foi possível gerar o link. Verifique se o e-mail está cadastrado."
      );
    }
  }
);