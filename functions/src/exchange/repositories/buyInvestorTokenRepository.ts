import {FieldValue} from "firebase-admin/firestore";
import {HttpsError} from "firebase-functions/v2/https";
import {db} from "../shared/firebase";
import {BuyInvestorTokenParams, BuyInvestorTokenResult} from "../types";
import {persistTokenValuation} from "./persistTokenValuation";

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
      throw new HttpsError("not-found", "Oferta nao encontrada.");
    }

    const offer = offerSnap.data();

    if (!offer) {
      throw new HttpsError("not-found", "Dados da oferta nao encontrados.");
    }

    const sellerId = offer.vendedorId as string | undefined;
    const sellerName = offer.vendedorNome as string | undefined;

    const startupId = offer.startupId as string | undefined;
    const startupName = offer.startupName as string | undefined;
    const sector = offer.sector as string | undefined;
    const stage = offer.stage as string | undefined;

    const quantidade = Number(offer.quantidade ?? 0);
    const preco = Number(offer.preco ?? 0);
    const requestedQuantity = params.quantity ?? quantidade;
    const totalValue = requestedQuantity * preco;

    const offerStatus = offer.offerStatus ?? "open";
    const type = offer.type ?? "sell";

    if (offerStatus !== "open") {
      throw new HttpsError(
        "failed-precondition",
        "Esta oferta nao esta mais aberta."
      );
    }

    if (type !== "sell") {
      throw new HttpsError(
        "failed-precondition",
        "Esta oferta nao e uma oferta de venda."
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
        "Voce nao pode comprar sua propria oferta."
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
        "Oferta possui quantidade ou preco invalido."
      );
    }

    if (requestedQuantity <= 0 || requestedQuantity > quantidade) {
      throw new HttpsError(
        "failed-precondition",
        `Quantidade indisponivel. Disponivel: ${quantidade}.`
      );
    }

    const sellerWalletRef = db.collection("wallets").doc(sellerId);
    const startupRef = db.collection("startups").doc(startupId);

    const buyerWalletSnap = await transaction.get(buyerWalletRef);
    const sellerWalletSnap = await transaction.get(sellerWalletRef);
    const startupSnap = await transaction.get(startupRef);

    if (!buyerWalletSnap.exists) {
      throw new HttpsError(
        "not-found",
        "Carteira do comprador nao encontrada."
      );
    }

    if (!sellerWalletSnap.exists) {
      throw new HttpsError(
        "not-found",
        "Carteira do vendedor nao encontrada."
      );
    }

    if (!startupSnap.exists) {
      throw new HttpsError("not-found", "Startup nao encontrada.");
    }

    const buyerBalance = Number(buyerWalletSnap.data()?.balance ?? 0);
    const startup = startupSnap.data();

    if (buyerBalance < totalValue) {
      throw new HttpsError(
        "failed-precondition",
        "Saldo insuficiente para comprar esta oferta."
      );
    }

    const valuation = await persistTokenValuation(transaction, {
      startupId,
      startupRef,
      startup: startup ?? {},
      startupName,
      sector: sector ?? "",
      stage: stage ?? "",
      quantity: requestedQuantity,
      price: preco,
    });

    transaction.update(buyerWalletRef, {
      balance: FieldValue.increment(-totalValue),
      updatedAt: FieldValue.serverTimestamp(),
    });

    transaction.update(sellerWalletRef, {
      balance: FieldValue.increment(totalValue),
      updatedAt: FieldValue.serverTimestamp(),
    });

    transaction.update(startupRef, {
      currentPrice: valuation.currentPrice,
      lastValuationDate: valuation.date,
      lastVariationPercent: valuation.variationPercent,
      lastTradePrice: preco,
      lastTradeAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    const remainingQuantity = quantidade - requestedQuantity;

    if (remainingQuantity > 0) {
      transaction.update(offerRef, {
        quantidade: remainingQuantity,
        totalValue: remainingQuantity * preco,
        lastCompradorId: buyerId,
        lastPurchaseQuantity: requestedQuantity,
        lastPurchaseValue: totalValue,
        updatedAt: FieldValue.serverTimestamp(),
      });
    } else {
      transaction.update(offerRef, {
        quantidade: 0,
        totalValue: 0,
        offerStatus: "executed",
        compradorId: buyerId,
        executadoEm: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

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

      quantidade: requestedQuantity,
      preco,
      totalValue,

      criadoEm: FieldValue.serverTimestamp(),
    });
  });

  return {
    transactionId: transactionRef.id,
  };
}
