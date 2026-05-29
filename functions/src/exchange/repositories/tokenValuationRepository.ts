// Juliano Perusso
// RA: 24023434

import {db} from "../shared/firebase";
import {TokenValuationPoint, ValuationPeriod} from "../types";

type TransactionItem = {
  date: Date;
  price: number;
  volume: number;
};

type GroupedValuation = {
  totalValue: number;
  volume: number;
  fallbackPrice?: number;
  variationPercent?: number;
};

function getPeriodStart(period: ValuationPeriod): Date {
  const now = new Date();

  switch (period) {
    case "daily":
      return new Date(now.getFullYear(), now.getMonth(), now.getDate() - 1);
    case "weekly":
      return new Date(now.getFullYear(), now.getMonth(), now.getDate() - 7);
    case "monthly":
      return new Date(now.getFullYear(), now.getMonth() - 1, now.getDate());
    case "sixMonths":
      return new Date(now.getFullYear(), now.getMonth() - 6, now.getDate());
    case "ytd":
      return new Date(now.getFullYear(), 0, 1);
  }
}

function toDate(value: unknown): Date | null {
  const possibleTimestamp = value as {toDate?: () => Date} | undefined;

  if (!possibleTimestamp?.toDate) {
    return null;
  }

  return possibleTimestamp.toDate();
}

function toDateKey(date: Date): string {
  return date.toISOString().slice(0, 10);
}

async function buildHistoryFromPersistedValuations(
  startupId: string,
  period: ValuationPeriod
): Promise<TokenValuationPoint[]> {
  const start = getPeriodStart(period);
  const startKey = toDateKey(start);
  const snapshot = await db
    .collection("startups")
    .doc(startupId)
    .collection("valuation_history")
    .limit(500)
    .get();

  const grouped = new Map<string, GroupedValuation>();
  let lastPriceBeforeStart = 0;
  let lastDateBeforeStart = "";
  let lastVariationBeforeStart = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const date = typeof data.date === "string" ? data.date : doc.id;
    const price = Number(data.price ?? data.averagePrice ?? 0);
    const volume = Number(data.volume ?? 0);
    const persistedVariation = Number(data.variationPercent ?? 0);

    if (!/^\d{4}-\d{2}-\d{2}$/.test(date) || price <= 0) {
      continue;
    }

    if (date < startKey) {
      if (!lastDateBeforeStart || date > lastDateBeforeStart) {
        lastDateBeforeStart = date;
        lastPriceBeforeStart = price;
        lastVariationBeforeStart = persistedVariation;
      }
      continue;
    }

    grouped.set(date, {
      totalValue: price * volume,
      volume,
      fallbackPrice: price,
      variationPercent: persistedVariation,
    });
  }

  if (lastPriceBeforeStart > 0) {
    grouped.set(startKey, {
      totalValue: 0,
      volume: 0,
      fallbackPrice: lastPriceBeforeStart,
      variationPercent: lastVariationBeforeStart,
    });
  }

  const entries = Array.from(grouped.entries()).sort((a, b) =>
    a[0].localeCompare(b[0])
  );

  if (entries.length === 0) {
    return [];
  }

  const priceFromGroup = (item: GroupedValuation): number => {
    if (item.volume > 0) {
      return item.totalValue / item.volume;
    }

    return item.fallbackPrice ?? 0;
  };

  const firstPrice = priceFromGroup(entries[0][1]);

  return entries.map(([date, item]) => {
    const price = priceFromGroup(item);
    const variationPercent = item.variationPercent ?? (firstPrice > 0 ?
      ((price - firstPrice) / firstPrice) * 100 :
      0);

    return {
      date,
      price,
      variationPercent,
      volume: item.volume,
    };
  });
}

async function buildHistoryFromTransactions(
  startupId: string,
  period: ValuationPeriod
): Promise<TokenValuationPoint[]> {
  const start = getPeriodStart(period);
  const snapshot = await db
    .collection("transactions")
    .where("startupId", "==", startupId)
    .limit(500)
    .get();

  const transactions: TransactionItem[] = [];
  let lastPriceBeforeStart = 0;
  let lastDateBeforeStart: Date | null = null;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const date = toDate(data.criadoEm ?? data.createdAt);
    const price = Number(data.preco ?? data.price ?? 0);
    const volume = Number(data.quantidade ?? data.quantity ?? 0);

    if (!date || price <= 0 || volume <= 0) {
      continue;
    }

    if (date < start) {
      if (!lastDateBeforeStart || date > lastDateBeforeStart) {
        lastDateBeforeStart = date;
        lastPriceBeforeStart = price;
      }
      continue;
    }

    transactions.push({date, price, volume});
  }

  transactions.sort((a, b) => a.date.getTime() - b.date.getTime());

  const grouped = new Map<string, GroupedValuation>();

  if (lastPriceBeforeStart > 0) {
    grouped.set(toDateKey(start), {
      totalValue: 0,
      volume: 0,
      fallbackPrice: lastPriceBeforeStart,
    });
  }

  for (const transaction of transactions) {
    const key = toDateKey(transaction.date);
    const current = grouped.get(key) ?? {totalValue: 0, volume: 0};

    current.totalValue += transaction.price * transaction.volume;
    current.volume += transaction.volume;

    grouped.set(key, current);
  }

  const entries = Array.from(grouped.entries()).sort((a, b) =>
    a[0].localeCompare(b[0])
  );

  if (entries.length === 0) {
    const startupSnap = await db.collection("startups").doc(startupId).get();
    const startup = startupSnap.data();
    const fallbackPrice = Number(
      startup?.currentPrice ?? startup?.initialPrice ?? 0
    );

    if (fallbackPrice <= 0) {
      return [];
    }

    return [
      {
        date: toDateKey(start),
        price: fallbackPrice,
        variationPercent: 0,
        volume: 0,
      },
      {
        date: toDateKey(new Date()),
        price: fallbackPrice,
        variationPercent: 0,
        volume: 0,
      },
    ];
  }

  const priceFromGroup = (item: GroupedValuation): number => {
    if (item.volume > 0) {
      return item.totalValue / item.volume;
    }

    return item.fallbackPrice ?? 0;
  };

  const firstPrice = priceFromGroup(entries[0][1]);

  return entries.map(([date, item]) => {
    const price = priceFromGroup(item);
    const variationPercent = firstPrice > 0 ?
      ((price - firstPrice) / firstPrice) * 100 :
      0;

    return {
      date,
      price,
      variationPercent,
      volume: item.volume,
    };
  });
}

export async function getTokenValuationHistoryFromRepository(
  startupId: string,
  period: ValuationPeriod
): Promise<TokenValuationPoint[]> {
  const persistedHistory = await buildHistoryFromPersistedValuations(
    startupId,
    period
  );

  if (persistedHistory.length > 0) {
    return persistedHistory;
  }

  return buildHistoryFromTransactions(startupId, period);
}
