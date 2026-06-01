import {onCall} from "firebase-functions/v2/https";
import {listPrivateQuestionsFromRepository} from "../repositories/questionRepository";
import {requireAuthUid, requireStartupId} from "../shared/validation";

export const listPrivateQuestions = onCall(
  {region: "southamerica-east1"},
  async (call) => {
    const uid = requireAuthUid(call);
    const startupId = requireStartupId(call.data);
    const result = await listPrivateQuestionsFromRepository(startupId, uid);

    return {
      success: true,
      isInvestor: result.isInvestor,
      isFounder: result.isFounder,
      data: result.data,
    };
  }
);
