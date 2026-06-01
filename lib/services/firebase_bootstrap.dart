import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static Future<bool> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return true;
    } on FirebaseException {
      return false;
    } on UnsupportedError {
      return false;
    }
  }
}
