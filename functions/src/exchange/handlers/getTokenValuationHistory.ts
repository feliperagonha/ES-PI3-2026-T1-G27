// Juliano Perusso
// RA: 24023434

import {HttpsError, onCall} from "firebase-functions/v2/https";
import {getTokenValuationHistoryFromRepository} from "../repositories/tokenValuationRepository";
import {validateGetTokenValuationHistoryData} from "../shared/validation";
import {GetTokenValuationHistoryResponse} from "../types";

export const getTokenValuationHistory = onCall(
  {region: "southamerica-east1"},
  async (request): Promise<GetTokenValuationHistoryResponse> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Logue para operar.");
    }

    const data = validateGetTokenValuationHistoryData(request.data);
    const history = await getTokenValuationHistoryFromRepository(
      data.startupId,
      data.period
    );

    return {
      success: true,
      startupId: data.startupId,
      period: data.period,
      data: history,
    };
  }
);
