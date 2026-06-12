import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static Future<bool> initialize() async {
    if (kIsWeb) return false;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
