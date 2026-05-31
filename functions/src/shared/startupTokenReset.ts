// Juliano Perusso
// RA: 24023434

import {
  DocumentData,
  FieldValue,
  Timestamp,
} from "firebase-admin/firestore";

const TOKEN_RESET_DELAY_DAYS = 5;
const TOKEN_RESET_DELAY_MS = TOKEN_RESET_DELAY_DAYS * 24 * 60 * 60 * 1000;

export type StartupTokenResetEvaluation = {
  tokensAvailable: number;
  resetQuantity: number;
  shouldReset: boolean;
  shouldMarkSoldOut: boolean;
  soldOutAt?: Timestamp;
  nextTokenResetAt?: Timestamp;
};

function toMillis(value: unknown): number | null {
  if (!value) {
    return null;
  }

  if (value instanceof Date) {
    return value.getTime();
  }

  if (value instanceof Timestamp) {
    return value.toMillis();
  }

  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }

  if (
    typeof value === "object" &&
    "toMillis" in value &&
    typeof value.toMillis === "function"
  ) {
    return Number(value.toMillis());
  }

  if (
    typeof value === "object" &&
    "toDate" in value &&
    typeof value.toDate === "function"
  ) {
    return Number(value.toDate().getTime());
  }

  return null;
}

function toPositiveInteger(value: unknown): number {
  const numberValue = Number(value ?? 0);
  if (!Number.isFinite(numberValue) || numberValue <= 0) {
    return 0;
  }

  return Math.floor(numberValue);
}

export function getStartupResetQuantity(startup: DocumentData): number {
  return toPositiveInteger(
    startup.initialTokensAvailable ??
      startup.defaultTokensAvailable ??
      startup.totalTokens
  );
}

export function evaluateStartupTokenReset(
  startup: DocumentData,
  now = new Date()
): StartupTokenResetEvaluation {
  const nowMs = now.getTime();
  const currentTokensAvailable = toPositiveInteger(startup.tokensAvailable);
  const resetQuantity = getStartupResetQuantity(startup);

  if (currentTokensAvailable > 0 || resetQuantity <= 0) {
    return {
      tokensAvailable: currentTokensAvailable,
      resetQuantity,
      shouldReset: false,
      shouldMarkSoldOut: false,
    };
  }

  const soldOutMs =
    toMillis(startup.soldOutAt) ?? toMillis(startup.lastTradeAt) ?? nowMs;
  const nextResetMs =
    toMillis(startup.nextTokenResetAt) ?? soldOutMs + TOKEN_RESET_DELAY_MS;

  if (nowMs >= nextResetMs) {
    return {
      tokensAvailable: resetQuantity,
      resetQuantity,
      shouldReset: true,
      shouldMarkSoldOut: false,
    };
  }

  return {
    tokensAvailable: 0,
    resetQuantity,
    shouldReset: false,
    shouldMarkSoldOut:
      toMillis(startup.soldOutAt) === null ||
      toMillis(startup.nextTokenResetAt) === null,
    soldOutAt: Timestamp.fromMillis(soldOutMs),
    nextTokenResetAt: Timestamp.fromMillis(nextResetMs),
  };
}

export function buildExpiredTokenResetUpdate(
  evaluation: StartupTokenResetEvaluation
): DocumentData {
  return {
    tokensAvailable: evaluation.resetQuantity,
    soldOutAt: FieldValue.delete(),
    nextTokenResetAt: FieldValue.delete(),
    tokenResetStatus: "available",
    lastTokenResetAt: FieldValue.serverTimestamp(),
    tokenResetCount: FieldValue.increment(1),
    updatedAt: FieldValue.serverTimestamp(),
  };
}

export function buildSoldOutTokenUpdate(now = new Date()): DocumentData {
  return {
    tokensAvailable: 0,
    soldOutAt: FieldValue.serverTimestamp(),
    nextTokenResetAt: Timestamp.fromMillis(now.getTime() + TOKEN_RESET_DELAY_MS),
    tokenResetStatus: "waiting_reset",
  };
}

export function buildPendingSoldOutMarkerUpdate(
  evaluation: StartupTokenResetEvaluation
): DocumentData {
  const update: DocumentData = {
    tokenResetStatus: "waiting_reset",
    updatedAt: FieldValue.serverTimestamp(),
  };

  if (evaluation.soldOutAt) {
    update.soldOutAt = evaluation.soldOutAt;
  }

  if (evaluation.nextTokenResetAt) {
    update.nextTokenResetAt = evaluation.nextTokenResetAt;
  }

  return update;
}
