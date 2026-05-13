import {HttpsError, onCall} from "firebase-functions/v2/https";
import {buyInvestorTokenTransaction} from "../repositories/buyInvestorTokenRepository";
import {validateBuyInvestorTokenData} from "../shared/validation";

export const buyInvestorToken = onCall(
  {region: "southamerica-east1"},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Logue para operar.");
    }

    const buyerId = request.auth.uid;

    const {offerId} = validateBuyInvestorTokenData(request.data);

    const result = await buyInvestorTokenTransaction({
      buyerId,
      offerId,
    });

    return {
      success: true,
      transactionId: result.transactionId,
      message: "Compra realizada com sucesso.",
    };
  }
);