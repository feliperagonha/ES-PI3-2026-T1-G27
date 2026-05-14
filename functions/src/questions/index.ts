import { onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

export const createPrivateQuestion = onCall(async (request) => {
  const uid = request.auth?.uid;

  if (!uid) {
    throw new Error("Usuário não autenticado.");
  }

  const { startupId, question } = request.data;

  if (!startupId || !question) {
    throw new Error("Dados inválidos.");
  }

  const orderSnapshot = await db
    .collection("orders")
    .where("userId", "==", uid)
    .where("startupId", "==", startupId)
    .where("type", "==", "buy")
    .get();

  if (orderSnapshot.empty) {
    throw new Error("Você não é investidor desta startup.");
  }

  await db.collection("private_questions").add({
    userId: uid,
    startupId,
    question,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    success: true,
    message: "Pergunta enviada com sucesso",
  };
});