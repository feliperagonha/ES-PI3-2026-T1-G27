//Arthur Sebastian Guarniz de Castro
//24795528

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

//Verifica se o Firebase já foi inicializado pelo seu colega
if (!admin.apps.length) {
    admin.initializeApp();
}
const db = admin.firestore();

export const addBalance = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Você precisa estar logado.');
    }

    const uid = context.auth.uid;
    const amount = data.amount;

    if (!amount || amount <= 0) {
        throw new functions.https.HttpsError('invalid-argument', 'Valor inválido.');
    }

    const userRef = db.collection('users').doc(uid);

    try {
        await db.runTransaction(async (t) => {
            const userDoc = await t.get(userRef);
            if (!userDoc.exists) throw new Error("Usuário não existe no Firestore.");

            const currentBalance = userDoc.data()?.balance || 0;
            t.update(userRef, { balance: currentBalance + amount });
        });
        return { success: true, message: `Saldo de R$ ${amount} adicionado!` };
    } catch (e: any) {
        throw new functions.https.HttpsError('internal', e.message);
    }
});