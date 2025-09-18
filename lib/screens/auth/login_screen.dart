import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../dashboard/higher_authority_dashboard.dart';
import '../dashboard/associate_dashboard.dart';
import '../dashboard/ground_worker_dashboard.dart';
import '../dashboard/hospital_dashboard.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final user = await _authService.login(
                  _emailController.text,
                  _passwordController.text,
                );

                if (user != null && mounted) {
                  final role = await _authService.getUserRole(user.uid);
                  Widget nextScreen;

                  switch (role) {
                    case "District Collector":
                      nextScreen = const DistrictCollectorDashboard();
                      break;
                    case "Associate":
                      nextScreen = const AssociateDashboard();
                      break;
                    case "Ground Worker":
                      nextScreen = const GroundWorkerDashboard();
                      break;
                    case "Hospital":
                      nextScreen = const HospitalDashboard();
                      break;
                    default:
                      nextScreen = const Scaffold(
                        body: Center(child: Text("No role assigned")),
                      );
                  }

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => nextScreen),
                  );
                }
              },
              child: const Text("Login"),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SignupScreen()));
              },
              child: const Text("Don’t have an account? Sign up"),
            )
          ],
        ),
      ),
    );
  }
}
