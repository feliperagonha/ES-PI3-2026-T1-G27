import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

export async function ensureWallet(uid: string): Promise<void> {
  const walletRef = db.collection("wallets").doc(uid);
  const walletSnap = await walletRef.get();

  if (!walletSnap.exists) {
    await walletRef.set({
      userId: uid,
      balance: 0,
      reservedBalance: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}
