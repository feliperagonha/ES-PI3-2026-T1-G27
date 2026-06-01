export type QuestionVisibility = "publica" | "privada";

export type QuestionItem = {
  id: string;
  autorId: string;
  autorNome: string;
  texto: string;
  resposta: string | null;
  respondidoPorId: string | null;
  respondidoPorNome: string | null;
  status: string;
  criadoEm: string | null;
  respondidoEm: string | null;
};

export type ListPrivateQuestionsResult = {
  isInvestor: boolean;
  isFounder: boolean;
  data: QuestionItem[];
};

export type CreateQuestionParams = {
  startupId: string;
  uid: string;
  texto: string;
  visibility: QuestionVisibility;
};

export type AnswerQuestionParams = {
  startupId: string;
  questionId: string;
  uid: string;
  resposta: string;
  visibility: QuestionVisibility;
};
