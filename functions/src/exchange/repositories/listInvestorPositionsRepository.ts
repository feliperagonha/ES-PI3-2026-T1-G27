import {db} from "../shared/firebase";
import {InvestorPositionItem} from "../types";

export async function listInvestorPositionsFromRepository(
  uid: string
): Promise<InvestorPositionItem[]> {
  const transactionsSnapshot = await db
    .collection("transactions")
    .limit(500)
    .get();

  const positions = new Map<string, {
    startupId: string;
    startupName: string;
    quantity: number;
    totalInvested: number;
  }>();

  for (const doc of transactionsSnapshot.docs) {
    const data = doc.data();

    const startupId = data.startupId as string | undefined;
    const startupName = data.startupName as string | undefined;
    const quantidade = Number(data.quantidade ?? data.quantity ?? 0);
    const totalValue = Number(data.totalValue ?? 0);

    if (!startupId || !startupName || quantidade <= 0) {
      continue;
    }

    const current = positions.get(startupId) ?? {
      startupId,
      startupName,
      quantity: 0,
      totalInvested: 0,
    };

    if (data.compradorId === uid || data.buyerId === uid) {
      current.quantity += quantidade;
      current.totalInvested += totalValue;
    }

    if (data.vendedorId === uid || data.sellerId === uid) {
      current.quantity -= quantidade;
    }

    positions.set(startupId, current);
  }

  const openSellOffersSnapshot = await db
    .collection("over_the_counter")
    .where("vendedorId", "==", uid)
    .where("type", "==", "sell")
    .where("offerStatus", "==", "open")
    .get();

  const reservedByStartup = new Map<string, number>();

  for (const doc of openSellOffersSnapshot.docs) {
    const data = doc.data();

    const startupId = data.startupId as string | undefined;
    const quantidade = Number(data.quantidade ?? 0);

    if (!startupId || quantidade <= 0) {
      continue;
    }

    reservedByStartup.set(
      startupId,
      (reservedByStartup.get(startupId) ?? 0) + quantidade
    );
  }

  const result: InvestorPositionItem[] = [];

  for (const position of positions.values()) {
    if (position.quantity <= 0) {
      continue;
    }

    const startupSnap = await db
      .collection("startups")
      .doc(position.startupId)
      .get();

    const startup = startupSnap.data();

    const currentPrice = Number(startup?.currentPrice ?? 0);
    const reservedQuantity = reservedByStartup.get(position.startupId) ?? 0;
    const availableQuantity = position.quantity - reservedQuantity;

    const averagePrice =
      position.quantity > 0
        ? position.totalInvested / position.quantity
        : 0;

    result.push({
      startupId: position.startupId,
      startupName: position.startupName,
      quantity: position.quantity,
      reservedQuantity,
      availableQuantity,
      averagePrice,
      currentPrice,
      totalInvested: position.totalInvested,
      currentValue: position.quantity * currentPrice,
    });
  }

  return result.sort((a, b) =>
    a.startupName.localeCompare(b.startupName, "pt-BR")
  );
}