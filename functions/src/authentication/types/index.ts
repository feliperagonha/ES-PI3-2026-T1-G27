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