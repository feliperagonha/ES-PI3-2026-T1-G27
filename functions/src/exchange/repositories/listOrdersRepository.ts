import {db} from "../shared/firebase";
import {ListOrdersData, OrderListItem} from "../types";

function timestampToIso(value: unknown): string | null {
  const possibleTimestamp = value as {toDate?: () => Date} | undefined;

  if (!possibleTimestamp?.toDate) {
    return null;
  }

  return possibleTimestamp.toDate().toISOString();
}

export async function listOrdersFromRepository(
  filters: ListOrdersData
): Promise<OrderListItem[]> {
  let query: FirebaseFirestore.Query = db.collection("over_the_counter");

  if (filters.onlyOpen !== false) {
    query = query.where("offerStatus", "==", "open");
  }

  if (filters.startupId) {
    query = query.where("startupId", "==", filters.startupId);
  }

  const snapshot = await query.limit(100).get();

  return snapshot.docs.map((doc) => {
    const data = doc.data();

    const quantidade = Number(data.quantidade ?? 0);
    const preco = Number(data.preco ?? 0);
    const totalValue = Number(data.totalValue ?? quantidade * preco);

    return {
      id: doc.id,

      startupId: data.startupId ?? "",
      startupName: data.startupName ?? "",
      sector: data.sector ?? "",
      stage: data.stage ?? "",

      vendedorId: data.vendedorId ?? "",
      vendedorNome: data.vendedorNome ?? "",

      type: data.type ?? "sell",
      quantidade,
      preco,
      totalValue,

      offerStatus: data.offerStatus ?? "open",

      criadoEm: timestampToIso(data.criadoEm),
      updatedAt: timestampToIso(data.updatedAt),
    };
  });
}