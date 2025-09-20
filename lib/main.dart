import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:safepulse/screens/dashboard/associate_dashboard.dart';
import 'package:safepulse/screens/dashboard/district_collector_dashboard.dart';
import 'package:safepulse/screens/dashboard/ground_worker_dashboard.dart';
import 'package:safepulse/screens/dashboard/groundworker/profile.dart';
import 'package:safepulse/screens/dashboard/hospital_dashboard.dart';
import 'package:safepulse/screens/dashboard/taluka_head_dashboard.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SafePulseApp());
}

class SafePulseApp extends StatelessWidget {
  const SafePulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafePulse',
      theme: ThemeData(primarySwatch: Colors.deepOrange),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/profile': (context) {
          // You'll need to pass userId and authToken as arguments
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return ProfileScreen(
            userId: args?['userId'] ?? '',
            authToken: args?['authToken'] ?? '',
          );
        },
        '/district-collector-dashboard': (context) => const DistrictCollectorDashboard(),
        '/associate-dashboard': (context) => const AssociateDashboard(),
        '/taluka-head-dashboard': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return TalukaHeadDashboard(userEmail: args?['userEmail'] ?? '');
        },
        '/ground-worker-dashboard': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return GroundWorkerDashboard(
            userId: args?['userId']?.toString() ?? '',
            authToken: args?['authToken'] ?? '',
          );
        },
        '/hospital-dashboard': (context) => const HospitalDashboard(),
      },
      // Fallback for unknown routes
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (context) => const LoginScreen());
      },
    );
  }
}