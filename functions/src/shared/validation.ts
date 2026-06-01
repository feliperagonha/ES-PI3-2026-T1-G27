import {HttpsError} from "firebase-functions/v2/https";

export function normalizeString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

export function requireAuthUid(request: {auth?: {uid?: string}}): string {
  const uid = request.auth?.uid;

  if (!uid) {
    throw new HttpsError("unauthenticated", "Usuario nao autenticado.");
  }

  return uid;
}

export function requireStartupId(data: unknown): string {
  const payload = (data ?? {}) as {startupId?: unknown};
  const startupId = normalizeString(payload.startupId);

  if (!startupId) {
    throw new HttpsError("invalid-argument", "startupId obrigatorio.");
  }

  return startupId;
}

export function requireQuestionText(data: unknown): string {
  const payload = (data ?? {}) as {
    texto?: unknown;
    question?: unknown;
    resposta?: unknown;
  };
  const text = normalizeString(
    payload.texto ?? payload.question ?? payload.resposta
  );

  if (!text) {
    throw new HttpsError(
      "invalid-argument",
      "Digite o texto da pergunta ou resposta."
    );
  }

  if (text.length > 500) {
    throw new HttpsError(
      "invalid-argument",
      "Texto deve ter no maximo 500 caracteres."
    );
  }

  return text;
}

export function requireQuestionId(data: unknown): string {
  const payload = (data ?? {}) as {perguntaId?: unknown; questionId?: unknown};
  const questionId = normalizeString(payload.perguntaId ?? payload.questionId);

  if (!questionId) {
    throw new HttpsError("invalid-argument", "perguntaId obrigatorio.");
  }

  return questionId;
}
