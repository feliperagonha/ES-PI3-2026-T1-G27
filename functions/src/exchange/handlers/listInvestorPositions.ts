import {HttpsError, onCall} from "firebase-functions/v2/https";
import {listInvestorPositionsFromRepository} from "../repositories/listInvestorPositionsRepository";
import {ListInvestorPositionsResponse} from "../types";

export const listInvestorPositions = onCall(
  {region: "southamerica-east1"},
  async (request): Promise<ListInvestorPositionsResponse> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Logue para operar.");
    }

    const uid = request.auth.uid;

    const positions = await listInvestorPositionsFromRepository(uid);

    return {
      success: true,
      count: positions.length,
      data: positions,
    };
  }
);