//Juliano Perusso
//RA: 24023434

import {HttpsError} from "firebase-functions/v2/https";
import {OrderType, PlaceOrderData} from "../types";

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