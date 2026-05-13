import {FieldValue} from "firebase-admin/firestore";
import {HttpsError} from "firebase-functions/v2/https";
import {db} from "../shared/firebase";

export async function cancelOrderFromRepository(
  uid: string,
  offerId: string
): Promise<void> {
  const offerRef = db.collection("over_the_counter").doc(offerId);

  await db.runTransaction(async (transaction) => {
    const offerSnap = await transaction.get(offerRef);

    if (!offerSnap.exists) {
      throw new HttpsError("not-found", "Oferta não encontrada.");
    }

    const offer = offerSnap.data();

    if (!offer) {
      throw new HttpsError("not-found", "Dados da oferta não encontrados.");
    }

    if (offer.vendedorId !== uid) {
      throw new HttpsError(
        "permission-denied",
        "Você só pode cancelar suas próprias ofertas."
      );
    }

    const offerStatus = offer.offerStatus ?? "open";

    if (offerStatus !== "open") {
      throw new HttpsError(
        "failed-precondition",
        "Somente ofertas abertas podem ser canceladas."
      );
    }

    const walletRef = db.collection("wallets").doc(uid);

    if (offer.type === "buy") {
      const quantidade = Number(offer.quantidade ?? 0);
      const preco = Number(offer.preco ?? 0);
      const totalValue = Number(offer.totalValue ?? quantidade * preco);

      if (totalValue > 0) {
        transaction.update(walletRef, {
          balance: FieldValue.increment(totalValue),
          reservedBalance: FieldValue.increment(-totalValue),
          updatedAt: FieldValue.serverTimestamp(),
        });
      }
    }

    transaction.update(offerRef, {
      offerStatus: "cancelled",
      canceladoEm: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
}