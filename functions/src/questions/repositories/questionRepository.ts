import {HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {
  AnswerQuestionParams,
  CreateQuestionParams,
  ListPrivateQuestionsResult,
  QuestionItem,
  QuestionVisibility,
} from "../types";
import {sortQuestionsByCreatedAt, toQuestionItem} from "../shared/mapper";
import {normalizeString} from "../shared/validation";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

async function getStartup(
  startupId: string
): Promise<admin.firestore.DocumentData> {
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

async function getDisplayName(
  uid: string,
  defaultName: string
): Promise<string> {
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

function questionsCollection(
  startupId: string,
  visibility: QuestionVisibility
) {
  const collectionName = visibility === "publica" ?
    "perguntas_publicas" :
    "perguntas_privadas";

  return db.collection("startups").doc(startupId).collection(collectionName);
}

export async function listPublicQuestionsFromRepository(
  startupId: string
): Promise<QuestionItem[]> {
  await getStartup(startupId);

  const snapshot = await questionsCollection(startupId, "publica").get();
  return sortQuestionsByCreatedAt(snapshot.docs.map(toQuestionItem));
}

export async function createQuestionFromRepository(
  params: CreateQuestionParams
): Promise<string> {
  await getStartup(params.startupId);

  if (
    params.visibility === "privada" &&
    !(await isInvestor(params.startupId, params.uid))
  ) {
    throw new HttpsError(
      "permission-denied",
      "Apenas investidores desta startup podem enviar perguntas privadas."
    );
  }

  const autorNome = await getDisplayName(
    params.uid,
    params.visibility === "publica" ? "Usuario" : "Investidor"
  );
  const questionRef = questionsCollection(
    params.startupId,
    params.visibility
  ).doc();

  await questionRef.set({
    autorId: params.uid,
    autorNome,
    texto: params.texto,
    resposta: null,
    respondidoPorId: null,
    respondidoPorNome: null,
    status: "pendente",
    criadoEm: admin.firestore.FieldValue.serverTimestamp(),
    respondidoEm: null,
  });

  return questionRef.id;
}

export async function answerQuestionFromRepository(
  params: AnswerQuestionParams
): Promise<void> {
  if (!(await isFounder(params.startupId, params.uid))) {
    throw new HttpsError(
      "permission-denied",
      "Apenas socios desta startup podem responder perguntas."
    );
  }

  const questionRef = questionsCollection(
    params.startupId,
    params.visibility
  ).doc(params.questionId);
  const questionSnap = await questionRef.get();

  if (!questionSnap.exists) {
    throw new HttpsError("not-found", "Pergunta nao encontrada.");
  }

  const respondidoPorNome = await getDisplayName(params.uid, "Socio");

  await questionRef.update({
    resposta: params.resposta,
    respondidoPorId: params.uid,
    respondidoPorNome,
    status: "respondida",
    respondidoEm: admin.firestore.FieldValue.serverTimestamp(),
  });
}

export async function listPrivateQuestionsFromRepository(
  startupId: string,
  uid: string
): Promise<ListPrivateQuestionsResult> {
  const [founder, investor] = await Promise.all([
    isFounder(startupId, uid),
    isInvestor(startupId, uid),
  ]);

  if (!founder && !investor) {
    return {
      isInvestor: false,
      isFounder: false,
      data: [],
    };
  }

  const collection = questionsCollection(startupId, "privada");
  const snapshot = founder ?
    await collection.get() :
    await collection.where("autorId", "==", uid).get();

  return {
    isInvestor: investor,
    isFounder: founder,
    data: sortQuestionsByCreatedAt(snapshot.docs.map(toQuestionItem)),
  };
}
