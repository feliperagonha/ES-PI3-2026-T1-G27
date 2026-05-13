import {FieldValue} from "firebase-admin/firestore";
import {HttpsError} from "firebase-functions/v2/https";
import {db} from "../shared/firebase";
import {BuyStartupTokenParams, BuyStartupTokenResult} from "../types";

export async function buyStartupTokenTransaction(
  params: BuyStartupTokenParams
): Promise<BuyStartupTokenResult> {
  const {buyerId, startupId, quantity} = params;

  const startupRef = db.collection("startups").doc(startupId);
  const walletRef = db.collection("wallets").doc(buyerId);
  const transactionRef = db.collection("transactions").doc();

  await db.runTransaction(async (transaction) => {
    const startupSnap = await transaction.get(startupRef);
    const walletSnap = await transaction.get(walletRef);

    if (!startupSnap.exists) {
      throw new HttpsError("not-found", "Startup não encontrada.");
    }

    if (!walletSnap.exists) {
      throw new HttpsError("not-found", "Carteira do usuário não encontrada.");
    }

    const startup = startupSnap.data();
    const wallet = walletSnap.data();

    if (!startup) {
      throw new HttpsError("not-found", "Dados da startup não encontrados.");
    }

    if (startup.isActive !== true) {
      throw new HttpsError(
        "failed-precondition",
        "Esta startup não está disponível para investimento."
      );
    }

    const startupName = startup.name as string | undefined;
    const sector = startup.sector as string | undefined;
    const stage = startup.stage as string | undefined;

    const currentPrice = Number(startup.currentPrice ?? 0);
    const tokensAvailable = Number(startup.tokensAvailable ?? 0);
    const balance = Number(wallet?.balance ?? 0);

    if (!startupName) {
      throw new HttpsError(
        "failed-precondition",
        "Startup sem nome cadastrado."
      );
    }

    if (currentPrice <= 0) {
      throw new HttpsError(
        "failed-precondition",
        "Preço atual da startup inválido."
      );
    }

    if (tokensAvailable < quantity) {
      throw new HttpsError(
        "failed-precondition",
        "Tokens disponíveis insuficientes."
      );
    }

    const totalValue = quantity * currentPrice;

    if (balance < totalValue) {
      throw new HttpsError(
        "failed-precondition",
        "Saldo insuficiente para comprar tokens."
      );
    }

    transaction.update(walletRef, {
      balance: FieldValue.increment(-totalValue),
      updatedAt: FieldValue.serverTimestamp(),
    });

    transaction.update(startupRef, {
      tokensAvailable: FieldValue.increment(-quantity),
      totalInvested: FieldValue.increment(totalValue),
      updatedAt: FieldValue.serverTimestamp(),
    });

    transaction.set(transactionRef, {
      type: "buy_startup_token",

      startupId,
      startupName,
      sector: sector ?? "",
      stage: stage ?? "",

      compradorId: buyerId,
      vendedorId: null,

      quantidade: quantity,
      preco: currentPrice,
      totalValue,

      criadoEm: FieldValue.serverTimestamp(),
    });
  });

  return {
    transactionId: transactionRef.id,
  };
}