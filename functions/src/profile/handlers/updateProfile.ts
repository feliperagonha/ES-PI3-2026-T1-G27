// Felipe Ragonha
// RA: 24023900

import {HttpsError, onCall} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

const db = admin.firestore(); 

export const updateProfile = onCall(
  {region: "southamerica-east1"},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Logue para operar.");
    }

    const {name, phone} = request.data;

    if (!name || name.trim() === "") {
      throw new HttpsError("invalid-argument", "Nome não pode ser vazio.");
    }

    await db.collection("users").doc(request.auth.uid).update({
      name: name.trim(),
      phone: phone?.trim() ?? "",
    });

    return {success: true, message: "Perfil atualizado."};
  }
);