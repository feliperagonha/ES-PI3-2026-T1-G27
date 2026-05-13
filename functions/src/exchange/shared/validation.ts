import {HttpsError} from "firebase-functions/v2/https";
import {
  OrderType,
  PlaceOrderData,
  BuyInvestorTokenData,
  CancelOrderData,
  ListOrdersData,
  BuyStartupTokenData,
} from "../types";

export function normalizeString(value: unknown): string | undefined {
  if (typeof value !== "string") {
    return undefined;
  }

  const trimmed = value.trim();

  return trimmed.length > 0 ? trimmed : undefined;
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