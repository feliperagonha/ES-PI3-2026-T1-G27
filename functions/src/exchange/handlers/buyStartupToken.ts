import {HttpsError, onCall} from "firebase-functions/v2/https";
import {buyStartupTokenTransaction} from "../repositories/buyStartupTokenRepository";
import {validateBuyStartupTokenData} from "../shared/validation";
import {BuyStartupTokenResponse} from "../types";

export const buyStartupToken = onCall(
  {region: "southamerica-east1"},
  async (request): Promise<BuyStartupTokenResponse> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Logue para operar.");
    }

    const buyerId = request.auth.uid;

    const data = validateBuyStartupTokenData(request.data);

    const result = await buyStartupTokenTransaction({
      buyerId,
      startupId: data.startupId,
      quantity: data.quantity,
    });

    return {
      success: true,
      transactionId: result.transactionId,
      message: "Compra de tokens realizada com sucesso.",
    };
  }
);