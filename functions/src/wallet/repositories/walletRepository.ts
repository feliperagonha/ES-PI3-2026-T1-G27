import {FieldValue} from "firebase-admin/firestore";
import {db} from "../shared/firebase";
import {WalletData} from "../types";

export async function addBalanceToWallet(
  uid: string,
  amount: number
): Promise<void> {
  await db.collection("wallets").doc(uid).set(
    {
      userId: uid,
      balance: FieldValue.increment(amount),
      reservedBalance: FieldValue.increment(0),
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    },
    {merge: true}
  );
}

export async function fetchOrCreateWallet(uid: string): Promise<WalletData> {
  const walletRef = db.collection("wallets").doc(uid);
  const walletSnap = await walletRef.get();

  if (!walletSnap.exists) {
    const wallet = {
      userId: uid,
      balance: 0,
      reservedBalance: 0,
    };

    await walletRef.set({
      ...wallet,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    return wallet;
  }

  const walletData = walletSnap.data() ?? {};

  return {
    userId: uid,
    balance: Number(walletData.balance ?? 0),
    reservedBalance: Number(walletData.reservedBalance ?? 0),
  };
}
