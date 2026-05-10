// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDgmEz9KocUPoQZyeR7c008vBo2IyNFxVY',
    appId: '1:404028315665:android:46bd1d84f35c85993b39b0',
    messagingSenderId: '404028315665',
    projectId: 'projeto-integrador-g27',
    storageBucket: 'projeto-integrador-g27.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyApZIY2SBOtZK8SOemzgGn2UzQOuEsnCfE',
    appId: '1:404028315665:ios:9c06c93f7ff991a23b39b0',
    messagingSenderId: '404028315665',
    projectId: 'projeto-integrador-g27',
    storageBucket: 'projeto-integrador-g27.firebasestorage.app',
    iosBundleId: 'com.example.projetoIntegrador3G27',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDgmEz9KocUPoQZyeR7c008vBo2IyNFxVY',
    appId: '1:404028315665:web:1ea146701008eff33b39b0',
    messagingSenderId: '404028315665',
    projectId: 'projeto-integrador-g27',
    authDomain: 'projeto-integrador-g27.firebaseapp.com',
    storageBucket: 'projeto-integrador-g27.firebasestorage.app',
  );
}