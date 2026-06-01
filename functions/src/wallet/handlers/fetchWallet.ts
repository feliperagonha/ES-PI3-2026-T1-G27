// Guilherme Marras
// RA: 24027681


//Juliano Perusso
//RA: 24023434

import {HttpsError, onCall} from "firebase-functions/v2/https";
import {fetchOrCreateWallet} from "../repositories/walletRepository";

export const fetchWallet = onCall(
  {region: "southamerica-east1"},
  async (call) => {
    if (!call.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Usuário não logado."
      );
    }

    const uid = call.auth.uid;

    return fetchOrCreateWallet(uid);
  }
);
