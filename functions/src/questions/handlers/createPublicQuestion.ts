import {onCall} from "firebase-functions/v2/https";
import {createQuestionFromRepository} from "../repositories/questionRepository";
import {
  requireAuthUid,
  requireQuestionText,
  requireStartupId,
} from "../shared/validation";

export const createPublicQuestion = onCall(
  {region: "southamerica-east1"},
  async (call) => {
    const uid = requireAuthUid(call);
    const startupId = requireStartupId(call.data);
    const texto = requireQuestionText(call.data);
    const perguntaId = await createQuestionFromRepository({
      startupId,
      uid,
      texto,
      visibility: "publica",
    });

    return {
      success: true,
      perguntaId,
      message: "Pergunta publica enviada com sucesso.",
    };
  }
);
