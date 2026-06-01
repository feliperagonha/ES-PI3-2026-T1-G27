import {QueryDocumentSnapshot} from "firebase-admin/firestore";
import {QuestionItem} from "../types";
import {normalizeString} from "./validation";

function toIsoString(value: unknown): string | null {
  const timestamp = value as {toDate?: () => Date} | undefined;

  if (!timestamp?.toDate) {
    return null;
  }

  return timestamp.toDate().toISOString();
}

export function toQuestionItem(doc: QueryDocumentSnapshot): QuestionItem {
  const data = doc.data();

  return {
    id: doc.id,
    autorId: normalizeString(data.autorId),
    autorNome: normalizeString(data.autorNome) || "Investidor",
    texto: normalizeString(data.texto),
    resposta: normalizeString(data.resposta) || null,
    respondidoPorId: normalizeString(data.respondidoPorId) || null,
    respondidoPorNome: normalizeString(data.respondidoPorNome) || null,
    status: normalizeString(data.status) || "pendente",
    criadoEm: toIsoString(data.criadoEm),
    respondidoEm: toIsoString(data.respondidoEm),
  };
}

export function sortQuestionsByCreatedAt(
  questions: QuestionItem[]
): QuestionItem[] {
  return questions.sort((a, b) =>
    (b.criadoEm ?? "").localeCompare(a.criadoEm ?? "")
  );
}
