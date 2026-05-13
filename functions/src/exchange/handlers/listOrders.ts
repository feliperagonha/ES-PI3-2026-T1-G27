import {HttpsError, onCall} from "firebase-functions/v2/https";
import {listOrdersFromRepository} from "../repositories/listOrdersRepository";
import {validateListOrdersData} from "../shared/validation";
import {ListOrdersResponse} from "../types";

export const listOrders = onCall(
  {region: "southamerica-east1"},
  async (request): Promise<ListOrdersResponse> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Logue para operar.");
    }

    const filters = validateListOrdersData(request.data);

    const orders = await listOrdersFromRepository(filters);

    return {
      success: true,
      count: orders.length,
      data: orders,
    };
  }
);