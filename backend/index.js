//Arthur Sebastian Guarniz de Castro
//24795528

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

//1. FUNÇÃO: ADICIONAR SALDO (CARTEIRA SIMULADA)
exports.addBalance = functions.https.onCall(async (data, context) => {
    // Verificação de segurança: O usuário está logado?
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Você precisa estar logado.');
    }

    const uid = context.auth.uid; //ID do usuario logado vindo direto do Firebase
    const amount = data.amount;

    if (!amount || amount <= 0) {
        throw new functions.https.HttpsError('invalid-argument', 'Valor inválido.');
    }

    const userRef = db.collection('users').doc(uid);

    try {
        await db.runTransaction(async (t) => {
            const userDoc = await t.get(userRef);
            if (!userDoc.exists) throw new Error("Usuário não existe no Firestore.");
            
            const currentBalance = userDoc.data().balance || 0;
            t.update(userRef, { balance: currentBalance + amount });
        });
        return { success: true, message: `Saldo de R$ ${amount} adicionado!` };
    } catch (e) {
        throw new functions.https.HttpsError('internal', e.message);
    }
});

//2. FUNÇÃO: CRIAR ORDEM (COMPRA OU VENDA NO BALCÃO)
exports.placeOrder = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Logue para operar.');
    }

    const uid = context.auth.uid;
    const { startupId, type, quantity, price } = data; // buy ou sell

    const userRef = db.collection('users').doc(uid);

    try {
        await db.runTransaction(async (t) => {
            const userDoc = await t.get(userRef);
            const balance = userDoc.data().balance || 0;
            const totalCost = quantity * price;

            //REGRA DE NEGÓCIO: Se for COMPRA, tem que ter saldo!
            if (type === 'buy' && balance < totalCost) {
                throw new Error("Saldo insuficiente para esta compra.");
            }

            //REGRA DE NEGÓCIO: Se for VENDA, tem que ter os tokens!
            //Aqui o servidor verificaria na subcoleção 'portfolio' se ele tem a quantidade
            //Por enquanto, vamos permitir a criação da ordem e salvar no banco.

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

            //Se for compra, já podemos "bloquear" o saldo do usuário (opcional)
            if (type === 'buy') {
                t.update(userRef, { balance: balance - totalCost });
            }
        });

        return { success: true, message: `Ordem de ${type} criada com sucesso!` };
    } catch (e) {
        throw new functions.https.HttpsError('failed-precondition', e.message);
    }
});