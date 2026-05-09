//Juliano Perusso
//RA: 24023434

import {HttpsError, onCall} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import {createUserWithProfile} from "../repositories/authRepository";
import {validateRegisterUserData} from "../shared/validation";
import {RegisterUserResponse} from "../types";

export const registerUser = onCall(
  {region: "southamerica-east1"},
  async (request): Promise<RegisterUserResponse> => {
    let registerData;

    try {
      registerData = validateRegisterUserData(request.data);
    } catch (error) {
      throw new HttpsError(
        "invalid-argument",
        error instanceof Error ? error.message : "Dados inválidos."
      );
    }

    try {
      const uid = await createUserWithProfile(registerData);

      logger.info("Usuário cadastrado com sucesso.", {
        uid,
        email: registerData.email,
      });

      return {
        success: true,
        uid,
        message: "Cadastro realizado com sucesso.",
      };
    } catch (error) {
      logger.error("Erro ao cadastrar usuário.", error);

      const code = (error as {code?: string}).code;

      if (code === "auth/email-already-exists") {
        throw new HttpsError(
          "already-exists",
          "Este e-mail já está em uso."
        );
      }

      if (code === "auth/invalid-email") {
        throw new HttpsError(
          "invalid-argument",
          "E-mail inválido."
        );
      }

      if (code === "auth/weak-password") {
        throw new HttpsError(
          "invalid-argument",
          "Senha muito fraca."
        );
      }

      throw new HttpsError(
        "internal",
        "Erro interno ao cadastrar usuário."
      );
    }
  }
);