// Felipe Ragonha
// RA: 24023900

import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import {
  LoginResponseData,
  FirebaseSignInResponse,
} from "../types";
import {validateLoginData} from "../shared/validation";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

export const loginUser = onCall(
  {region: "southamerica-east1"},
  async (request): Promise<LoginResponseData> => {
    let email: string;
    let password: string;

    try {
      const validatedData = validateLoginData(request.data);
      email = validatedData.email;
      password = validatedData.password;
    } catch (error) {
      throw new HttpsError(
        "invalid-argument",
        error instanceof Error ? error.message : "Dados inválidos."
      );
    }

    const apiKey = process.env.AUTH_WEB_API_KEY;

    if (!apiKey) {
      logger.error("AUTH_WEB_API_KEY não configurada.");
      throw new HttpsError(
        "failed-precondition",
        "Configuração de autenticação ausente."
      );
    }

    try {
      // 1. Autentica com email e senha
      const response = await fetch(
        "https://identitytoolkit.googleapis.com/v1/" +
          `accounts:signInWithPassword?key=${apiKey}`,
        {
          method: "POST",
          headers: {"Content-Type": "application/json"},
          body: JSON.stringify({
            email,
            password,
            returnSecureToken: true,
          }),
        }
      );

      const data = (await response.json()) as FirebaseSignInResponse & {
        error?: unknown;
      };

      if (!response.ok) {
        logger.error("Erro no login", data);
        throw new HttpsError("unauthenticated", "E-mail ou senha inválidos.");
      }

      const uid = data.localId;

      // 2. Verifica se o usuário tem 2FA ativado
      const userDoc = await db.collection("users").doc(uid).get();
      const userData = userDoc.data();
      const twoFactorEnabled = userData?.twoFactorEnabled === true;

      if (twoFactorEnabled) {
        // Gera e salva código de 6 dígitos
        const code = Math.floor(100000 + Math.random() * 900000).toString();
        const expiry = admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + 10 * 60 * 1000) // 10 minutos
        );

        await db.collection("users").doc(uid).update({
          twoFactorCode: code,
          twoFactorExpiry: expiry,
          twoFactorPendingUid: uid,
        });

        // Loga o código (em produção, enviar por email)
        logger.info(`[2FA Login] Código ${code} para ${email}`);

        // TODO: integrar envio de email aqui (SendGrid, Nodemailer, etc.)

        // Retorna flag para o Flutter redirecionar para tela de verificação
        // Não retorna o token ainda!
        return {
          success: false,
          requiresTwoFactor: true,
          uid,
          token: "",
          message: "Código 2FA enviado para seu email.",
        };
      }

      // 3. Sem 2FA — loga direto
      const customToken = await admin.auth().createCustomToken(uid);

      return {
        success: true,
        requiresTwoFactor: false,
        token: customToken,
        message: "Login realizado com sucesso.",
      };
    } catch (error) {
      logger.error("Erro ao realizar login", error);
      if (error instanceof HttpsError) throw error;
      throw new HttpsError("internal", "Erro interno ao realizar login.");
    }
  }
);
