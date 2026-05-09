import {HttpsError, onCall} from "firebase-functions/v2/https";
import {FieldValue} from "firebase-admin/firestore";
import {db} from "../shared/firebase";

export const addBalance = onCall(
  {region: "southamerica-east1"},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Usuário precisa estar logado."
      );
    }

    const uid = request.auth.uid;
    const amount = request.data?.amount;

    if (typeof amount !== "number" || amount <= 0) {
      throw new HttpsError(
        "invalid-argument",
        "Valor inválido."
      );
    }

    const userRef = db.collection("users").doc(uid);

    await userRef.set(
      {
        balance: FieldValue.increment(amount),
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true}
    );

    return {
      success: true,
      message: "Saldo atualizado com sucesso.",
    };
  }
);