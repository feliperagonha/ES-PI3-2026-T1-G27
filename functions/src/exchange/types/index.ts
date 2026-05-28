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

export type BuyInvestorTokenData = {
  offerId: string;
  quantity?: number;
};

export type BuyInvestorTokenParams = {
  buyerId: string;
  offerId: string;
  quantity?: number;
};

export type BuyInvestorTokenResult = {
  transactionId: string;
};

export type BuyInvestorTokenResponse = {
  success: boolean;
  transactionId: string;
  message: string;
};

export type ListOrdersData = {
  startupId?: string;
  onlyOpen?: boolean;
};

export type OrderListItem = {
  id: string;

  startupId: string;
  startupName: string;
  sector?: string;
  stage?: string;

  vendedorId: string;
  vendedorNome: string;

  type: OrderType;
  quantidade: number;
  preco: number;
  totalValue: number;

  offerStatus: string;

  criadoEm?: string | null;
  updatedAt?: string | null;
};

export type ListOrdersResponse = {
  success: boolean;
  count: number;
  data: OrderListItem[];
};

export type CancelOrderData = {
  offerId: string;
};

export type CancelOrderResponse = {
  success: boolean;
  message: string;
};

export type InvestorPositionItem = {
  startupId: string;
  startupName: string;
  quantity: number;
  reservedQuantity: number;
  availableQuantity: number;
  averagePrice: number;
  currentPrice: number;
  totalInvested: number;
  currentValue: number;
};

export type ListInvestorPositionsResponse = {
  success: boolean;
  count: number;
  data: InvestorPositionItem[];
};

export type BuyStartupTokenData = {
  startupId: string;
  quantity: number;
};

export type BuyStartupTokenResponse = {
  success: boolean;
  transactionId: string;
  message: string;
};

export type BuyStartupTokenParams = {
  buyerId: string;
  startupId: string;
  quantity: number;
};

export type BuyStartupTokenResult = {
  transactionId: string;
};

export type ValuationPeriod =
  | "daily"
  | "weekly"
  | "monthly"
  | "sixMonths"
  | "ytd";

export type GetTokenValuationHistoryData = {
  startupId: string;
  period: ValuationPeriod;
};

export type TokenValuationPoint = {
  date: string;
  price: number;
  variationPercent: number;
  volume: number;
};

export type GetTokenValuationHistoryResponse = {
  success: boolean;
  startupId: string;
  period: ValuationPeriod;
  data: TokenValuationPoint[];
};
