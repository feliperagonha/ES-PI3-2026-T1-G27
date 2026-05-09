export function normalizeString(value: unknown): string | undefined {
  if (typeof value !== "string") {
    return undefined;
  }

  const trimmed = value.trim();

  return trimmed.length > 0 ? trimmed : undefined;
}

export function isValidEmail(email: string): boolean {
  const emailRegex = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

  return emailRegex.test(email);
}

export function isValidPassword(password: string): boolean {
  return password.length >= 6;
}

export function validateLoginData(data: unknown): {
  email: string;
  password: string;
} {
  if (!data || typeof data !== "object") {
    throw new Error("Dados de login inválidos.");
  }

  const payload = data as Record<string, unknown>;

  const email = normalizeString(payload.email);
  const password = normalizeString(payload.password);

  if (!email) {
    throw new Error("E-mail obrigatório.");
  }

  if (!isValidEmail(email)) {
    throw new Error("E-mail inválido.");
  }

  if (!password) {
    throw new Error("Senha obrigatória.");
  }

  if (!isValidPassword(password)) {
    throw new Error("A senha deve ter pelo menos 6 caracteres.");
  }

  return {
    email,
    password,
  };
}