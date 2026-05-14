// Felipe Ragonha
// RA: 24023900

import {HttpsError, onCall} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as nodemailer from "nodemailer";
import {defineSecret} from "firebase-functions/params";

const gmailUser = defineSecret("GMAIL_USER");
const gmailPass = defineSecret("GMAIL_PASS");

const db = admin.firestore();

export const sendTwoFactorCode = onCall(
  {
    region: "southamerica-east1",
    secrets: [gmailUser, gmailPass],
  },
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

    // Configura o transporter do Nodemailer com Gmail
    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: gmailUser.value(),
        pass: gmailPass.value(),
      },
    });

    // Envia o email
    await transporter.sendMail({
      from: `"MesclaInvest" <${gmailUser.value()}>`,
      to: email,
      subject: "Seu código de verificação — MesclaInvest",
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto;">
          <h2 style="color: #6A4CFF;">MesclaInvest</h2>
          <p>Olá! Seu código de verificação é:</p>
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
            Se você não solicitou este código, ignore este email.
          </p>
        </div>
      `,
    });

    return {success: true, message: "Código enviado para seu email."};
  }
);
