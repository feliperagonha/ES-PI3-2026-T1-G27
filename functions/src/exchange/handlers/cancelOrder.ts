import {HttpsError, onCall} from "firebase-functions/v2/https";
import {cancelOrderFromRepository} from "../repositories/cancelOrderRepository";
import {validateCancelOrderData} from "../shared/validation";
import {CancelOrderResponse} from "../types";

export const cancelOrder = onCall(
  {region: "southamerica-east1"},
  async (request): Promise<CancelOrderResponse> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Logue para operar.");
    }

    const uid = request.auth.uid;
    const {offerId} = validateCancelOrderData(request.data);

    await cancelOrderFromRepository(uid, offerId);

    return {
      success: true,
      message: "Oferta cancelada com sucesso.",
    };
  }
);