import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'services/fcm_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'pages/dashboard.dart';
import 'pages/welcome_page.dart';
import 'auth/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  //Initialisation des notifications
  await FCMService.initialize();

  runApp(const TrustCamApp());
}

class TrustCamApp extends StatelessWidget {
  const TrustCamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "TrustCam",
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Affichage d'un loader pendant le check de session
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            // L'utilisateur est déjà connecté → Dashboard
            return const Dashboard();
          } else {
            // Pas de session → WelcomePage
            return const WelcomePage();
          }
        },
      ),
    );
  }
}