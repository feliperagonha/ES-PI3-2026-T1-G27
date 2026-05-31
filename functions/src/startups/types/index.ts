export type Founder = {
  name: string;
  participation: number;
};

export type StartupDocument = {
  name: string;
  description: string;
  stage: string;
  sector: string;
  capitalInvested: number;
  totalTokens: number;
  tokensAvailable: number;
  initialPrice: number;
  currentPrice: number;
  totalInvested: number;
  status: string;
  isActive: boolean;
  founders: Founder[];
  mentors: string[];
  videoDemo: string;
  createdAt?: FirebaseFirestore.Timestamp;
  updatedAt?: FirebaseFirestore.Timestamp;
};

export type StartupListItem = {
  id: string;
  name: string;
  description: string;
  stage: string;
  sector: string;
  capitalInvested: number;
  totalTokens: number;
  tokensAvailable: number;
  initialPrice: number;
  currentPrice: number;
  totalInvested: number;
  status: string;
  isActive: boolean;
  founders: Founder[];
  mentors: string[];
  videoDemo: string;
};

export type ListStartupsData = {
  stage?: string;
  search?: string;
};

export type ListStartupsResponse = {
  success: boolean;
  count: number;
  data: StartupListItem[];
};
