import {FieldValue} from "firebase-admin/firestore";
import {HttpsError} from "firebase-functions/v2/https";
import {db} from "../shared/firebase";
import {BuyInvestorTokenParams, BuyInvestorTokenResult} from "../types";

export async function buyInvestorTokenTransaction(
  params: BuyInvestorTokenParams
): Promise<BuyInvestorTokenResult> {
  const {buyerId, offerId} = params;

  const offerRef = db.collection("over_the_counter").doc(offerId);
  const buyerWalletRef = db.collection("wallets").doc(buyerId);
  const transactionRef = db.collection("transactions").doc();

  await db.runTransaction(async (transaction) => {
    const offerSnap = await transaction.get(offerRef);

    if (!offerSnap.exists) {
      throw new HttpsError("not-found", "Oferta não encontrada.");
    }

    const offer = offerSnap.data();

    if (!offer) {
      throw new HttpsError("not-found", "Dados da oferta não encontrados.");
    }

    const sellerId = offer.vendedorId as string | undefined;
    const sellerName = offer.vendedorNome as string | undefined;

    const startupId = offer.startupId as string | undefined;
    const startupName = offer.startupName as string | undefined;
    const sector = offer.sector as string | undefined;
    const stage = offer.stage as string | undefined;

    const quantidade = Number(offer.quantidade ?? 0);
    const preco = Number(offer.preco ?? 0);
    const totalValue = Number(offer.totalValue ?? quantidade * preco);

    const offerStatus = offer.offerStatus ?? "open";
    const type = offer.type ?? "sell";

    if (offerStatus !== "open") {
      throw new HttpsError(
        "failed-precondition",
        "Esta oferta não está mais aberta."
      );
    }

    if (type !== "sell") {
      throw new HttpsError(
        "failed-precondition",
        "Esta oferta não é uma oferta de venda."
      );
    }

    if (!sellerId) {
      throw new HttpsError(
        "failed-precondition",
        "Oferta sem vendedor definido."
      );
    }

    if (sellerId === buyerId) {
      throw new HttpsError(
        "failed-precondition",
        "Você não pode comprar sua própria oferta."
      );
    }

    if (!startupId || !startupName) {
      throw new HttpsError(
        "failed-precondition",
        "Oferta sem dados da startup."
      );
    }

    if (quantidade <= 0 || preco <= 0) {
      throw new HttpsError(
        "failed-precondition",
        "Oferta possui quantidade ou preço inválido."
      );
    }

    const sellerWalletRef = db.collection("wallets").doc(sellerId);

    const buyerWalletSnap = await transaction.get(buyerWalletRef);
    const sellerWalletSnap = await transaction.get(sellerWalletRef);

    if (!buyerWalletSnap.exists) {
      throw new HttpsError(
        "not-found",
        "Carteira do comprador não encontrada."
      );
    }

    if (!sellerWalletSnap.exists) {
      throw new HttpsError(
        "not-found",
        "Carteira do vendedor não encontrada."
      );
    }

    const buyerBalance = Number(buyerWalletSnap.data()?.balance ?? 0);

    if (buyerBalance < totalValue) {
      throw new HttpsError(
        "failed-precondition",
        "Saldo insuficiente para comprar esta oferta."
      );
    }

    transaction.update(buyerWalletRef, {
      balance: FieldValue.increment(-totalValue),
      updatedAt: FieldValue.serverTimestamp(),
    });

    transaction.update(sellerWalletRef, {
      balance: FieldValue.increment(totalValue),
      updatedAt: FieldValue.serverTimestamp(),
    });

    transaction.update(offerRef, {
      offerStatus: "executed",
      compradorId: buyerId,
      executadoEm: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    transaction.set(transactionRef, {
      type: "buy_investor_token",

      offerId,

      startupId,
      startupName,
      sector: sector ?? "",
      stage: stage ?? "",

      compradorId: buyerId,
      vendedorId: sellerId,
      vendedorNome: sellerName ?? "",

      quantidade,
      preco,
      totalValue,

      criadoEm: FieldValue.serverTimestamp(),
    });
  });

  return {
    transactionId: transactionRef.id,
  };
}