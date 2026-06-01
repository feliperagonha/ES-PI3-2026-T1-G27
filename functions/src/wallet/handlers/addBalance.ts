import {HttpsError, onCall} from "firebase-functions/v2/https";
import {addBalanceToWallet} from "../repositories/walletRepository";

const maxAddBalanceAmount = 1000000;

export const addBalance = onCall(
  {region: "southamerica-east1"},
  async (call) => {
    if (!call.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Usuario precisa estar logado."
      );
    }

    const uid = call.auth.uid;
    const amount = Number(call.data?.amount);

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

    await addBalanceToWallet(uid, amount);

    return {
      success: true,
      message: "Saldo atualizado com sucesso.",
    };
  }
);
