// Arthur Sebastian Guarniz de Castro
// RA: 24795528

// Juliano Perusso
// RA: 24023434

import {FieldValue} from "firebase-admin/firestore";
import {db} from "../shared/firebase";
import {PlaceOrderData} from "../types";
import {
  validateCreateOrderEntities,
  validateBuyOrderBalance,
  validateSellOrderTokens,
} from "../shared/validation";

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

    validateCreateOrderEntities({
      startupSnap,
      walletSnap,
      startupId,
    });

    const startup = startupSnap.data();
    const wallet = walletSnap.data();
    const user = userSnap.data();

    const balance = Number(wallet?.balance ?? 0);

    if (type === "buy") {
      validateBuyOrderBalance({
        balance,
        totalValue,
      });
    }

    if (type === "sell") {
      const transactionsSnapshot = await db
        .collection("transactions")
        .limit(500)
        .get();

      let totalTokens = 0;

      for (const doc of transactionsSnapshot.docs) {
        const data = doc.data();

        if (data.startupId !== startupId) {
          continue;
        }

        const quantidade = Number(data.quantidade ?? data.quantity ?? 0);

        if (quantidade <= 0) {
          continue;
        }

        if (data.compradorId === uid || data.buyerId === uid) {
          totalTokens += quantidade;
        }

        if (data.vendedorId === uid || data.sellerId === uid) {
          totalTokens -= quantidade;
        }
      }

      const openSellOffersSnapshot = await db
        .collection("over_the_counter")
        .where("vendedorId", "==", uid)
        .where("startupId", "==", startupId)
        .where("type", "==", "sell")
        .where("offerStatus", "==", "open")
        .get();

      let reservedQuantity = 0;

      for (const doc of openSellOffersSnapshot.docs) {
        const data = doc.data();
        reservedQuantity += Number(data.quantidade ?? 0);
      }

      validateSellOrderTokens({
        totalTokens,
        reservedQuantity,
        requestedQuantity: quantity,
      });
    }

    const orderRef = db.collection("over_the_counter").doc();
    orderId = orderRef.id;

    transaction.set(orderRef, {
      startupId,
      startupName: startup?.name ?? "",
      sector: startup?.sector ?? "",
      stage: startup?.stage ?? "",

      vendedorId: type === "sell" ? uid : null,
      vendedorNome: user?.name ?? user?.fullName ?? "Investidor",

      compradorId: type === "buy" ? uid : null,

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