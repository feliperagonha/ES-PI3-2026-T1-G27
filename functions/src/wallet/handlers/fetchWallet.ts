import {HttpsError, onCall} from "firebase-functions/v2/https";
import {FieldValue} from "firebase-admin/firestore";
import {db} from "../shared/firebase";

export const fetchWallet = onCall (
    {region: 'southamerica-east1'},
    
    async (request) => {
        if (!request.auth) {
            throw new HttpsError(
                'unauthenticated',
                'Usuário não logado.'
            );
        }

        const uid = request.auth.uid;
        const ref = db.collection('users').doc(uid);
        const snap = await ref.get();
        const docData = snap.data();
        return docData;
    }
)