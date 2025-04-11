// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'models/navigation_service.dart'; // Import NavigationService
import 'utils/routes.dart';
import 'views/screens/auth/splash_screen.dart'; // Import your SplashScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase initialization failed: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Community Time Bank',
      theme: ThemeData(primarySwatch: Colors.blue),
      // Attach the navigatorKey from NavigationService
      navigatorKey: NavigationService().navigatorKey,
      initialRoute: Routes.splash,
      onGenerateRoute: Routes.generateRoute,
    );
  }
}