//Arthur Sebastian Guarniz de Castro
//24795528

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
    admin.initializeApp();
}
const db = admin.firestore();

export const placeOrder = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Logue para operar.');
    }

    const uid = context.auth.uid;
    const { startupId, type, quantity, price } = data;

    const userRef = db.collection('users').doc(uid);

    try {
        await db.runTransaction(async (t) => {
            const userDoc = await t.get(userRef);
            const balance = userDoc.data()?.balance || 0;
            const totalCost = quantity * price;

            if (type === 'buy' && balance < totalCost) {
                throw new Error("Saldo insuficiente para esta compra.");
            }

            const orderRef = db.collection('orders').doc();
            t.set(orderRef, {
                userId: uid,
                startupId: startupId,
                type: type,
                quantity: quantity,
                price: price,
                status: 'open',
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });

            if (type === 'buy') {
                t.update(userRef, { balance: balance - totalCost });
            }
        });

        return { success: true, message: `Ordem de ${type} criada com sucesso!` };
    } catch (e: any) {
        throw new functions.https.HttpsError('failed-precondition', e.message);
    }
});