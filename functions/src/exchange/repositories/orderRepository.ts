import {FieldValue} from "firebase-admin/firestore";
import {HttpsError} from "firebase-functions/v2/https";
import {db} from "../shared/firebase";
import {PlaceOrderData} from "../types";

export async function createOrder(
  uid: string,
  order: PlaceOrderData
): Promise<string> {
  const {startupId, type, quantity, price} = order;

  const startupRef = db.collection("startups").doc(startupId);
  const walletRef = db.collection("wallets").doc(uid);
  const userRef = db.collection("users").doc(uid);

  const totalValue = quantity * price;

  let orderId = "";

  await db.runTransaction(async (transaction) => {
    const startupSnap = await transaction.get(startupRef);
    const walletSnap = await transaction.get(walletRef);
    const userSnap = await transaction.get(userRef);

    if (!startupSnap.exists) {
      throw new HttpsError("not-found", "Startup não encontrada.");
    }

    if (!walletSnap.exists) {
      throw new HttpsError("not-found", "Carteira do usuário não encontrada.");
    }

    const startup = startupSnap.data();
    const wallet = walletSnap.data();
    const user = userSnap.data();

    const balance = Number(wallet?.balance ?? 0);

    if (type === "buy" && balance < totalValue) {
      throw new HttpsError(
        "failed-precondition",
        "Saldo insuficiente para criar esta ordem de compra."
      );
    }

    const orderRef = db.collection("over_the_counter").doc();
    orderId = orderRef.id;

    transaction.set(orderRef, {
      startupId,
      startupName: startup?.name ?? "",
      sector: startup?.sector ?? "",
      stage: startup?.stage ?? "",

      vendedorId: uid,
      vendedorNome: user?.name ?? user?.fullName ?? "Investidor",

      type,
      quantidade: quantity,
      preco: price,
      totalValue,

      offerStatus: "open",

      criadoEm: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    if (type === "buy") {
      transaction.update(walletRef, {
        balance: FieldValue.increment(-totalValue),
        reservedBalance: FieldValue.increment(totalValue),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
  });

  return orderId;
}