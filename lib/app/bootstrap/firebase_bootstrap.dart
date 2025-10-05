import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options_prod.dart' as fprod;
import '../../firebase_options_qa.dart' as fqa;
import '../env.dart';
import '../pixel_config.dart';

Future<void> initFirebaseIfNeeded() async {
  if (Env.mode == AppMode.dev) {
    return;
  }

  if (Firebase.apps.isNotEmpty) {
    return;
  }

  switch (Env.mode) {
    case AppMode.qa:
      await Firebase.initializeApp(
        options: fqa.DefaultFirebaseOptions.currentPlatform,
      );
      break;
    case AppMode.prod:
      await Firebase.initializeApp(
        options: fprod.DefaultFirebaseOptions.currentPlatform,
      );
      break;
    case AppMode.dev:
      break;
  }
}
