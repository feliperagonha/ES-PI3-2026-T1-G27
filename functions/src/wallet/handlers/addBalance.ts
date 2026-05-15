import {HttpsError, onCall} from "firebase-functions/v2/https";
import {FieldValue} from "firebase-admin/firestore";
import {db} from "../shared/firebase";

const maxAddBalanceAmount = 1000000;

export const addBalance = onCall(
  {region: "southamerica-east1"},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Usuario precisa estar logado."
      );
    }

    const uid = request.auth.uid;
    const amount = Number(request.data?.amount);

    if (!Number.isFinite(amount) || amount <= 0) {
      throw new HttpsError(
        "invalid-argument",
        "Valor invalido."
      );
    }

    if (amount > maxAddBalanceAmount) {
      throw new HttpsError(
        "invalid-argument",
        "Valor acima do limite permitido para saldo ficticio."
      );
    }

    const walletRef = db.collection("wallets").doc(uid);

    await walletRef.set(
      {
        userId: uid,
        balance: FieldValue.increment(amount),
        reservedBalance: FieldValue.increment(0),
        createdAt: FieldValue.serverTimestamp(),
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
