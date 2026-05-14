// Guilherme Marras
// RA: 24027681


//Juliano Perusso
//RA: 24023434

import {HttpsError, onCall} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

const db = admin.firestore();

export const fetchWallet = onCall(
  {region: "southamerica-east1"},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Usuário não logado."
      );
    }

    const uid = request.auth.uid;

    const walletRef = db.collection("wallets").doc(uid);
    const walletSnap = await walletRef.get();

    if (!walletSnap.exists) {
      await walletRef.set({
        userId: uid,
        balance: 10000,
        reservedBalance: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        userId: uid,
        balance: 10000,
        reservedBalance: 0,
      };
    }

    const walletData = walletSnap.data() ?? {};

    return {
      userId: uid,
      balance: walletData.balance ?? 0,
      reservedBalance: walletData.reservedBalance ?? 0,
    };
  }
);