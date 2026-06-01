import {onCall} from "firebase-functions/v2/https";
import {listPublicQuestionsFromRepository} from "../repositories/questionRepository";
import {requireStartupId} from "../shared/validation";

export const listPublicQuestions = onCall(
  {region: "southamerica-east1"},
  async (call) => {
    const startupId = requireStartupId(call.data);
    const data = await listPublicQuestionsFromRepository(startupId);

    return {
      success: true,
      data,
    };
  }
);
