import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options_prod.dart' as fprod;
import '../../firebase_options_qa.dart' as fqa;
import '../env.dart';
import '../pixel_config.dart';

Future<void> initFirebaseIfNeeded() async {
  if (Env.mode == AppMode.prod) {
    await Firebase.initializeApp(
      options: fprod.DefaultFirebaseOptions.currentPlatform,
    );
  }
  if (Env.mode == AppMode.qa) {
    await Firebase.initializeApp(
      options: fqa.DefaultFirebaseOptions.currentPlatform,
    );
  }
}
