import {ListStartupsData} from "../types";

export function normalizeString(value: unknown): string | undefined {
  if (typeof value !== "string") {
    return undefined;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

export function validateListStartupsData(data: unknown): ListStartupsData {
  if (!data || typeof data !== "object") {
    return {};
  }

  const payload = data as Record<string, unknown>;

  return {
    stage: normalizeString(payload.stage)?.toLowerCase(),
    search: normalizeString(payload.search)?.toLowerCase(),
  };
}