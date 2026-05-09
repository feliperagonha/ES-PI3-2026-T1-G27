import {FieldValue} from "firebase-admin/firestore";
import {HttpsError} from "firebase-functions/v2/https";
import {db} from "../shared/firebase";
import {PlaceOrderData} from "../types";

export async function createOrder(
  uid: string,
  order: PlaceOrderData
): Promise<string> {
  const {startupId, type, quantity, price} = order;

  const userRef = db.collection("users").doc(uid);
  const totalCost = quantity * price;

  let orderId = "";

  await db.runTransaction(async (transaction) => {
    const userDoc = await transaction.get(userRef);
    const balance = userDoc.data()?.balance ?? 0;

    if (type === "buy" && balance < totalCost) {
      throw new HttpsError(
        "failed-precondition",
        "Saldo insuficiente para esta compra."
      );
    }

    const orderRef = db.collection("orders").doc();
    orderId = orderRef.id;

    transaction.set(orderRef, {
      userId: uid,
      startupId,
      type,
      quantity,
      price,
      status: "open",
      createdAt: FieldValue.serverTimestamp(),
    });

    if (type === "buy") {
      transaction.update(userRef, {
        balance: balance - totalCost,
      });
    }
  });

  return orderId;
}