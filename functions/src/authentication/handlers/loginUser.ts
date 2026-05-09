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

    const apiKey = process.env.FIREBASE_WEB_API_KEY;

    if (!apiKey) {
      logger.error("FIREBASE_WEB_API_KEY não configurada.");

      throw new HttpsError(
        "failed-precondition",
        "Configuração de autenticação ausente."
      );
    }

    try {
      const response = await fetch(
        "https://identitytoolkit.googleapis.com/v1/" +
          `accounts:signInWithPassword?key=${apiKey}`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
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

        throw new HttpsError(
          "unauthenticated",
          "E-mail ou senha inválidos."
        );
      }

      const uid = data.localId;

      const customToken = await admin.auth().createCustomToken(uid);

      return {
        success: true,
        token: customToken,
        message: "Login realizado com sucesso.",
      };
    } catch (error) {
      logger.error("Erro ao realizar login", error);

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        "Erro interno ao realizar login."
      );
    }
  }
);