// Felipe Ragonha
// RA: 24023900

import {HttpsError, onCall} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

const db = admin.firestore();

export const disableTwoFactor = onCall(
  {region: "southamerica-east1"},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Logue para operar.");
    }

    await db.collection("users").doc(request.auth.uid).update({
      twoFactorEnabled: false,
      twoFactorCode: admin.firestore.FieldValue.delete(),
      twoFactorExpiry: admin.firestore.FieldValue.delete(),
    });

    return {success: true, message: "2FA desativado."};
  }
);
