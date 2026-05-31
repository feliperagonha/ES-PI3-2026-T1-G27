// Felipe Ragonha
// RA: 24023900

import {HttpsError, onCall} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

type PrivateQuestionItem = {
  id: string;
  autorId: string;
  autorNome: string;
  texto: string;
  resposta: string | null;
  respondidoPorId: string | null;
  respondidoPorNome: string | null;
  status: string;
  criadoEm: string | null;
  respondidoEm: string | null;
};

function requireAuthUid(request: {auth?: {uid?: string}}): string {
  const uid = request.auth?.uid;

  if (!uid) {
    throw new HttpsError("unauthenticated", "Usuario nao autenticado.");
  }

  return uid;
}

function normalizeString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function requireStartupId(data: unknown): string {
  const payload = (data ?? {}) as {startupId?: unknown};
  const startupId = normalizeString(payload.startupId);

  if (!startupId) {
    throw new HttpsError("invalid-argument", "startupId obrigatorio.");
  }

  return startupId;
}

function requireText(data: unknown): string {
  const payload = (data ?? {}) as {
    texto?: unknown;
    question?: unknown;
    resposta?: unknown;
  };
  const text = normalizeString(
    payload.texto ?? payload.question ?? payload.resposta
  );

  if (!text) {
    throw new HttpsError("invalid-argument", "Texto obrigatorio.");
  }

  if (text.length > 500) {
    throw new HttpsError(
      "invalid-argument",
      "Texto deve ter no maximo 500 caracteres."
    );
  }

  return text;
}

function requireQuestionId(data: unknown): string {
  const payload = (data ?? {}) as {perguntaId?: unknown; questionId?: unknown};
  const questionId = normalizeString(payload.perguntaId ?? payload.questionId);

  if (!questionId) {
    throw new HttpsError("invalid-argument", "perguntaId obrigatorio.");
  }

  return questionId;
}

function toIsoString(value: unknown): string | null {
  const timestamp = value as {toDate?: () => Date} | undefined;

  if (!timestamp?.toDate) {
    return null;
  }

  return timestamp.toDate().toISOString();
}

function toQuestionItem(
  doc: admin.firestore.QueryDocumentSnapshot
): PrivateQuestionItem {
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

async function getStartup(startupId: string): Promise<admin.firestore.DocumentData> {
  const startupSnap = await db.collection("startups").doc(startupId).get();

  if (!startupSnap.exists) {
    throw new HttpsError("not-found", "Startup nao encontrada.");
  }

  return startupSnap.data() ?? {};
}

async function isFounder(startupId: string, uid: string): Promise<boolean> {
  const startup = await getStartup(startupId);
  const founderUids = startup.founderUids;

  return Array.isArray(founderUids) && founderUids.includes(uid);
}

async function getInvestorTokenBalance(
  startupId: string,
  uid: string
): Promise<number> {
  const snapshot = await db
    .collection("transactions")
    .where("startupId", "==", startupId)
    .limit(500)
    .get();

  let balance = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const quantity = Number(data.quantidade ?? data.quantity ?? 0);

    if (quantity <= 0) {
      continue;
    }

    if (data.compradorId === uid || data.buyerId === uid) {
      balance += quantity;
    }

    if (data.vendedorId === uid || data.sellerId === uid) {
      balance -= quantity;
    }
  }

  return balance;
}

async function isInvestor(startupId: string, uid: string): Promise<boolean> {
  return (await getInvestorTokenBalance(startupId, uid)) > 0;
}

async function getDisplayName(uid: string, defaultName: string): Promise<string> {
  const [userRecord, userDoc] = await Promise.all([
    admin.auth().getUser(uid),
    db.collection("users").doc(uid).get(),
  ]);

  const userData = userDoc.data() ?? {};
  return (
    normalizeString(userData.name) ||
    normalizeString(userData.fullName) ||
    normalizeString(userRecord.displayName) ||
    normalizeString(userRecord.email) ||
    defaultName
  );
}

function privateQuestionsCollection(startupId: string) {
  return db
    .collection("startups")
    .doc(startupId)
    .collection("perguntas_privadas");
}

export const listPrivateQuestions = onCall(
  {region: "southamerica-east1"},
  async (request) => {
    const uid = requireAuthUid(request);
    const startupId = requireStartupId(request.data);

    const [founder, investor] = await Promise.all([
      isFounder(startupId, uid),
      isInvestor(startupId, uid),
    ]);

    if (!founder && !investor) {
      return {
        success: true,
        isInvestor: false,
        isFounder: false,
        data: [],
      };
    }

    const collection = privateQuestionsCollection(startupId);
    const snapshot = founder ?
      await collection.get() :
      await collection.where("autorId", "==", uid).get();

    const data = snapshot.docs
      .map(toQuestionItem)
      .sort((a, b) => (b.criadoEm ?? "").localeCompare(a.criadoEm ?? ""));

    return {
      success: true,
      isInvestor: investor,
      isFounder: founder,
      data,
    };
  }
);

export const createPrivateQuestion = onCall(
  {region: "southamerica-east1"},
  async (request) => {
    const uid = requireAuthUid(request);
    const startupId = requireStartupId(request.data);
    const texto = requireText(request.data);

    if (!(await isInvestor(startupId, uid))) {
      throw new HttpsError(
        "permission-denied",
        "Apenas investidores desta startup podem enviar perguntas privadas."
      );
    }

    const autorNome = await getDisplayName(uid, "Investidor");
    const questionRef = privateQuestionsCollection(startupId).doc();

    await questionRef.set({
      autorId: uid,
      autorNome,
      texto,
      resposta: null,
      respondidoPorId: null,
      respondidoPorNome: null,
      status: "pendente",
      criadoEm: admin.firestore.FieldValue.serverTimestamp(),
      respondidoEm: null,
    });

    return {
      success: true,
      perguntaId: questionRef.id,
      message: "Pergunta enviada com sucesso.",
    };
  }
);

export const answerPrivateQuestion = onCall(
  {region: "southamerica-east1"},
  async (request) => {
    const uid = requireAuthUid(request);
    const startupId = requireStartupId(request.data);
    const perguntaId = requireQuestionId(request.data);
    const resposta = requireText(request.data);

    if (!(await isFounder(startupId, uid))) {
      throw new HttpsError(
        "permission-denied",
        "Apenas socios desta startup podem responder perguntas."
      );
    }

    const questionRef = privateQuestionsCollection(startupId).doc(perguntaId);
    const questionSnap = await questionRef.get();

    if (!questionSnap.exists) {
      throw new HttpsError("not-found", "Pergunta nao encontrada.");
    }

    const respondidoPorNome = await getDisplayName(uid, "Socio");

    await questionRef.update({
      resposta,
      respondidoPorId: uid,
      respondidoPorNome,
      status: "respondida",
      respondidoEm: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      message: "Resposta enviada com sucesso.",
    };
  }
);
