// Felipe Ragonha
// RA: 24023900

//Juliano Perusso
//RA: 24023434

import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import * as nodemailer from "nodemailer";
import {ensureWallet} from "../shared/ensureWallet";
import {defineSecret} from "firebase-functions/params";
import {
  LoginResponseData,
  FirebaseSignInResponse,
} from "../types";
import {validateLoginData} from "../shared/validation";

const gmailUser = defineSecret("GMAIL_USER");
const gmailPass = defineSecret("GMAIL_PASS");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

export const loginUser = onCall(
  {
    region: "southamerica-east1",
    secrets: [gmailUser, gmailPass],
  },
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
      // Autentica com email e senha
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

      await ensureWallet(uid);

      // Verifica se o usuário tem 2FA ativado
      const userDoc = await db.collection("users").doc(uid).get();
      const userData = userDoc.data();
      const twoFactorEnabled = userData?.twoFactorEnabled === true;

      if (twoFactorEnabled) {
        // Gera e salva código de 6 dígitos
        const code = Math.floor(100000 + Math.random() * 900000).toString();
        const expiry = admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + 10 * 60 * 1000)
        );

        await db.collection("users").doc(uid).update({
          twoFactorCode: code,
          twoFactorExpiry: expiry,
        });

        // Envia email com Nodemailer
        const transporter = nodemailer.createTransport({
          service: "gmail",
          auth: {
            user: gmailUser.value(),
            pass: gmailPass.value(),
          },
        });

        await transporter.sendMail({
          from: `"MesclaInvest" <${gmailUser.value()}>`,
          to: email,
          subject: "Seu código de acesso — MesclaInvest",
          html: `
            <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto;">
              <h2 style="color: #6A4CFF;">MesclaInvest</h2>
              <p>Olá! Seu código de acesso é:</p>
              <div style="
                background: #EDE7FF;
                border-radius: 12px;
                padding: 24px;
                text-align: center;
                margin: 24px 0;
              ">
                <span style="
                  font-size: 36px;
                  font-weight: 900;
                  letter-spacing: 8px;
                  color: #3A1C71;
                ">${code}</span>
              </div>
              <p style="color: #6B7280; font-size: 13px;">
                Este código é válido por <strong>10 minutos</strong>.<br/>
                Se você não tentou fazer login, ignore este email.
              </p>
            </div>
          `,
        });

        return {
          success: false,
          requiresTwoFactor: true,
          uid,
          token: "",
          message: "Código 2FA enviado para seu email.",
        };
      }

      // Sem 2FA = loga direto
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
