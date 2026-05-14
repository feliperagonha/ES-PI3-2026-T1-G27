import {
  OrderType,
  PlaceOrderData,
  BuyInvestorTokenData,
  CancelOrderData,
  ListOrdersData,
  BuyStartupTokenData,
} from "../types";
import {DocumentSnapshot} from "firebase-admin/firestore";
import {HttpsError} from "firebase-functions/v2/https";

export function normalizeString(value: unknown): string | undefined {
  if (typeof value !== "string") {
    return undefined;
  }

  const trimmed = value.trim();

  return trimmed.length > 0 ? trimmed : undefined;
}

export function validateCreateOrderEntities(params: {
  startupSnap: DocumentSnapshot;
  walletSnap: DocumentSnapshot;
  startupId: string;
}): void {
  const {startupSnap, walletSnap, startupId} = params;

  if (!startupSnap.exists) {
    throw new HttpsError(
      "not-found",
      `Startup não encontrada para o ID: ${startupId}`
    );
  }

  if (!walletSnap.exists) {
    throw new HttpsError(
      "not-found",
      "Carteira do usuário não encontrada."
    );
  }
}

export function validateBuyOrderBalance(params: {
  balance: number;
  totalValue: number;
}): void {
  const {balance, totalValue} = params;

  if (balance < totalValue) {
    throw new HttpsError(
      "failed-precondition",
      "Saldo insuficiente para criar esta ordem de compra."
    );
  }
}

export function validateSellOrderTokens(params: {
  totalTokens: number;
  reservedQuantity: number;
  requestedQuantity: number;
}): void {
  const {totalTokens, reservedQuantity, requestedQuantity} = params;

  const availableQuantity = totalTokens - reservedQuantity;

  if (availableQuantity < requestedQuantity) {
    throw new HttpsError(
      "failed-precondition",
      `Tokens disponíveis insuficientes. Disponível: ${availableQuantity}.`
    );
  }
}

export function validatePlaceOrderData(data: unknown): PlaceOrderData {
  if (!data || typeof data !== "object") {
    throw new HttpsError(
      "invalid-argument",
      "Dados da ordem inválidos."
    );
  }

  const payload = data as Record<string, unknown>;

  const startupId = normalizeString(payload.startupId);
  const type = normalizeString(payload.type);
  const quantity = payload.quantity;
  const price = payload.price;

  if (!startupId) {
    throw new HttpsError(
      "invalid-argument",
      "startupId obrigatório."
    );
  }

  if (type !== "buy" && type !== "sell") {
    throw new HttpsError(
      "invalid-argument",
      "Tipo de ordem inválido. Use buy ou sell."
    );
  }

  if (typeof quantity !== "number" || quantity <= 0) {
    throw new HttpsError(
      "invalid-argument",
      "Quantidade inválida."
    );
  }

  if (typeof price !== "number" || price <= 0) {
    throw new HttpsError(
      "invalid-argument",
      "Preço inválido."
    );
  }

  return {
    startupId,
    type: type as OrderType,
    quantity,
    price,
  };
}

export function validateBuyInvestorTokenData(
  data: unknown
): BuyInvestorTokenData {
  if (!data || typeof data !== "object") {
    throw new HttpsError(
      "invalid-argument",
      "Dados da compra inválidos."
    );
  }

  const payload = data as Record<string, unknown>;

  const offerId = normalizeString(payload.offerId);

  if (!offerId) {
    throw new HttpsError(
      "invalid-argument",
      "offerId obrigatório."
    );
  }

  return {
    offerId,
  };
}

export function validateCancelOrderData(data: unknown): CancelOrderData {
  if (!data || typeof data !== "object") {
    throw new HttpsError(
      "invalid-argument",
      "Dados do cancelamento inválidos."
    );
  }

  const payload = data as Record<string, unknown>;

  const offerId = normalizeString(payload.offerId);

  if (!offerId) {
    throw new HttpsError(
      "invalid-argument",
      "offerId obrigatório."
    );
  }

  return {
    offerId,
  };
}

export function validateListOrdersData(data: unknown): ListOrdersData {
  if (!data || typeof data !== "object") {
    return {
      onlyOpen: true,
    };
  }

  const payload = data as Record<string, unknown>;

  const startupId = normalizeString(payload.startupId);

  const onlyOpen =
    typeof payload.onlyOpen === "boolean" ? payload.onlyOpen : true;

  return {
    startupId,
    onlyOpen,
  };
}
export function validateBuyStartupTokenData(
  data: unknown
): BuyStartupTokenData {
  if (!data || typeof data !== "object") {
    throw new HttpsError(
      "invalid-argument",
      "Dados da compra inválidos."
    );
  }

  const payload = data as Record<string, unknown>;

  const startupId = normalizeString(payload.startupId);
  const quantity = payload.quantity;

  if (!startupId) {
    throw new HttpsError(
      "invalid-argument",
      "startupId obrigatório."
    );
  }

  if (typeof quantity !== "number" || quantity <= 0) {
    throw new HttpsError(
      "invalid-argument",
      "Quantidade inválida."
    );
  }

  return {
    startupId,
    quantity,
  };
}

