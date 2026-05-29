import {
  DocumentData,
  DocumentReference,
  FieldValue,
  Transaction,
} from "firebase-admin/firestore";

type PersistTokenValuationParams = {
  startupId: string;
  startupRef: DocumentReference<DocumentData>;
  startup: DocumentData;
  startupName: string;
  sector: string;
  stage: string;
  quantity: number;
  price: number;
};

export type PersistedTokenValuation = {
  date: string;
  currentPrice: number;
  variationPercent: number;
  volume: number;
};

function toDateKey(date: Date): string {
  return date.toISOString().slice(0, 10);
}

export async function persistTokenValuation(
  transaction: Transaction,
  params: PersistTokenValuationParams
): Promise<PersistedTokenValuation> {
  const tradedAt = new Date();
  const date = toDateKey(tradedAt);
  const valuationRef = params.startupRef
    .collection("valuation_history")
    .doc(date);
  const valuationSnap = await transaction.get(valuationRef);
  const valuation = valuationSnap.data() ?? {};

  const previousVolume = Number(valuation.volume ?? 0);
  const previousTotalValue = Number(valuation.totalValueTraded ?? 0);

  const tradeValue = params.quantity * params.price;
  const volume = previousVolume + params.quantity;
  const totalValueTraded = previousTotalValue + tradeValue;
  const averagePrice = volume > 0 ? totalValueTraded / volume : params.price;
  const initialPrice = Number(params.startup.initialPrice ?? params.price);
  const variationPercent =
    initialPrice > 0 ? ((averagePrice - initialPrice) / initialPrice) * 100 : 0;

  transaction.set(
    valuationRef,
    {
      startupId: params.startupId,
      startupName: params.startupName,
      sector: params.sector,
      stage: params.stage,
      date,
      price: averagePrice,
      averagePrice,
      variationPercent,
      volume,
      totalValueTraded,
      transactionCount: Number(valuation.transactionCount ?? 0) + 1,
      lastTradePrice: params.price,
      lastTradeQuantity: params.quantity,
      lastTradeValue: tradeValue,
      lastTradeAt: FieldValue.serverTimestamp(),
      createdAt: valuationSnap.exists ?
        valuation.createdAt ?? FieldValue.serverTimestamp() :
        FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    },
    {merge: true}
  );

  return {
    date,
    currentPrice: averagePrice,
    variationPercent,
    volume,
  };
}
