import {FieldValue} from "firebase-admin/firestore";
import {auth, db} from "../shared/firebase";
import {RegisterUserData} from "../types";

export async function createUserWithProfile(
  data: RegisterUserData
): Promise<string> {
  const userRecord = await auth.createUser({
    email: data.email,
    password: data.password,
    displayName: data.name,
  });

  const uid = userRecord.uid;

  try {
    await db.collection("users").doc(uid).set({
      name: data.name,
      email: data.email,
      cpf: data.cpf ?? null,
      phone: data.phone ?? null,
      balance: 0,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    return uid;
  } catch (error) {
    await auth.deleteUser(uid);
    throw error;
  }
}