// Arthur Sebastian Guarniz de Castro
// RA: 24795528

// Juliano Perusso
// RA: 24023434

import {HttpsError, onCall} from "firebase-functions/v2/https";
import {createOrder} from "../repositories/orderRepository";
import {validatePlaceOrderData} from "../shared/validation";
import {PlaceOrderResponse} from "../types";

export const placeOrder = onCall(
  {region: "southamerica-east1"},
  async (request): Promise<PlaceOrderResponse> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Logue para operar.");
    }

    const order = validatePlaceOrderData(request.data);
    const orderId = await createOrder(request.auth.uid, order);

    return {
      success: true,
      orderId,
      message: `Ordem de ${order.type} criada com sucesso!`,
    };
  }
);