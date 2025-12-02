import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'src/app_theme.dart';
import 'src/routes.dart';
import 'src/state/auth_state.dart';
import 'src/services/capsula_repository.dart';
import 'src/state/capsulas_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    // Habilitar la persistencia sin conexión para Firestore
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  } catch (_) {}
  runApp(NeuroConectaApp());
}

class NeuroConectaApp extends StatelessWidget {
  const NeuroConectaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProvider(create: (_) => CapsulasState(CapsulaRepository())),
      ],
      child: MaterialApp(
        title: 'NeuroConecta',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        initialRoute: Routes.welcome,
        routes: Routes.map,
      ),
    );
  }
}
