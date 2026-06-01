import {onCall} from "firebase-functions/v2/https";
import {answerQuestionFromRepository} from "../repositories/questionRepository";
import {
  requireAuthUid,
  requireQuestionId,
  requireQuestionText,
  requireStartupId,
} from "../shared/validation";

export const answerPublicQuestion = onCall(
  {region: "southamerica-east1"},
  async (call) => {
    const uid = requireAuthUid(call);
    const startupId = requireStartupId(call.data);
    const questionId = requireQuestionId(call.data);
    const resposta = requireQuestionText(call.data);

    await answerQuestionFromRepository({
      startupId,
      questionId,
      uid,
      resposta,
      visibility: "publica",
    });

    return {
      success: true,
      message: "Resposta enviada com sucesso.",
    };
  }
);
