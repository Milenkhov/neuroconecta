import 'package:flutter/material.dart';
import '../screens/welcome_screen.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/detail_screen.dart';
import '../screens/form_screen.dart';
import '../screens/library_screen.dart';
import '../screens/favorites_screen.dart';

class Routes {
  static const welcome = '/welcome';
  static const login = '/login';
  static const home = '/home';
  static const detail = '/detail';
  static const form = '/form';
  static const library = '/library';
  static const favorites = '/favorites';

  static Map<String, WidgetBuilder> get map => {
        welcome: (_) => const WelcomeScreen(),
        login: (_) => const LoginScreen(),
        home: (_) => const HomeScreen(),
        detail: (_) => const DetailScreen(),
        form: (_) => const FormScreen(),
        library: (_) => const LibraryScreen(),
        favorites: (_) => const FavoritesScreen(),
      };
}