// Felipe Ragonha
// RA: 24023900

import {HttpsError, onCall} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore(); 

export const deleteAccount = onCall(
  {region: "southamerica-east1"},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Logue para operar.");
    }

    const uid = request.auth.uid;

    // Deleta subcoleções do usuário
    const subcollections = ["investimentos", "historico"];
    for (const sub of subcollections) {
      const snap = await db
        .collection("usuarios").doc(uid)
        .collection(sub).get();

      const batch = db.batch();
      snap.docs.forEach((doc) => batch.delete(doc.ref));
      if (!snap.empty) await batch.commit();
    }

    // Deleta documento principal em /users
    await db.collection("users").doc(uid).delete();

    // Deleta documento em /usuarios (se existir)
    await db.collection("usuarios").doc(uid).delete();

    // Deleta o usuário do Firebase Auth
    await admin.auth().deleteUser(uid);

    return {success: true, message: "Conta deletada com sucesso."};
  }
);
