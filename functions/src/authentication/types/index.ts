export type LoginRequestData = {
  email: string;
  password: string;
};

export type LoginResponseData = {
  success: boolean;
  token: string;
  message: string;
};

export type FirebaseSignInResponse = {
  localId: string;
  email: string;
  idToken: string;
  refreshToken: string;
  expiresIn: string;
};

export type AuthenticatedUser = {
  uid: string;
  email?: string;
};

// Cadastro de usuário
export type RegisterUserData = {
  name: string;
  email: string;
  password: string;
  cpf?: string;
  phone?: string;
};

export type RegisterUserResponse = {
  success: boolean;
  uid: string;
  message: string;
};