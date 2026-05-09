//Juliano Perusso
//RA:24023434

export type OrderType = "buy" | "sell";

export type PlaceOrderData = {
  startupId: string;
  type: OrderType;
  quantity: number;
  price: number;
};

export type PlaceOrderResponse = {
  success: boolean;
  orderId: string;
  message: string;
};