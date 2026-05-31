// Felipe Ragonha
// RA: 24023900

import {defineSecret} from "firebase-functions/params";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as nodemailer from "nodemailer";

const gmailUser = defineSecret("GMAIL_USER");
const gmailPass = defineSecret("GMAIL_PASS");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

export const resendTwoFactorCode = onCall(
  {
    region: "southamerica-east1",
    secrets: [gmailUser, gmailPass],
  },
  async (request) => {
    const uid = request.data?.uid;

    if (typeof uid !== "string" || uid.trim().length === 0) {
      throw new HttpsError("invalid-argument", "UID obrigatorio.");
    }

    const userDoc = await db.collection("users").doc(uid).get();
    const userData = userDoc.data();

    if (!userDoc.exists || userData?.twoFactorEnabled !== true) {
      throw new HttpsError(
        "failed-precondition",
        "2FA nao esta habilitado para este usuario."
      );
    }

    const userRecord = await admin.auth().getUser(uid);
    const email = userRecord.email;

    if (!email) {
      throw new HttpsError("not-found", "Email nao encontrado.");
    }

    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const expiry = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 10 * 60 * 1000)
    );

    await db.collection("users").doc(uid).update({
      twoFactorCode: code,
      twoFactorExpiry: expiry,
    });

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
      subject: "Seu novo codigo de acesso - MesclaInvest",
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto;">
          <h2 style="color: #6A4CFF;">MesclaInvest</h2>
          <p>Ola! Seu novo codigo de acesso e:</p>
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
            Este codigo e valido por <strong>10 minutos</strong>.<br/>
            Se voce nao tentou fazer login, ignore este email.
          </p>
        </div>
      `,
    });

    return {success: true, message: "Novo codigo enviado para seu email."};
  }
);
