import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../dashboard/district_collector_dashboard.dart';
import '../dashboard/associate_dashboard.dart';
import '../dashboard/taluka_head_dashboard.dart';
import '../dashboard/ground_worker_dashboard.dart';
import '../dashboard/hospital_dashboard.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _connectionStatus = false;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Configuration for backend URL - CHANGE THIS BASED ON YOUR ENVIRONMENT
  static const String baseUrl = 'http://10.0.2.2:3000'; // For Android emulator
  // static const String baseUrl = 'http://localhost:3000'; // For iOS simulator
  // static const String baseUrl = 'http://192.168.1.100:3000'; // For physical device

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkConnection();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _checkConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      setState(() {
        _connectionStatus = response.statusCode == 200;
      });
    } catch (e) {
      setState(() {
        _connectionStatus = false;
      });
    }
  }

  // Function to login user
  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Prepare login data
    Map<String, dynamic> loginData = {
      "email": _emailController.text.trim(),
      "password": _passwordController.text.trim(),
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(loginData),
      );

      if (response.statusCode == 200) {
        // Login successful
        final responseData = jsonDecode(response.body);
        final userData = responseData['data'];
        
        // Navigate to appropriate dashboard based on role
        Widget nextScreen;
        switch (userData['role']) {
          case "District Collector":
            nextScreen = const DistrictCollectorDashboard();
            break;
          case "Associate":
            nextScreen = const AssociateDashboard();
            break;
          case "Ground Worker":
            nextScreen = GroundWorkerDashboard(userId: userData['id'].toString(),
  authToken: userData['token'],
);
            break;
          case "Hospital":
            nextScreen = const HospitalDashboard();
            break;
          case "Taluka Head":
            nextScreen = TalukaHeadDashboard(userEmail: userData['email']);
            break;
          default:
            nextScreen = Scaffold(
              appBar: AppBar(title: const Text("Error")),
              body: const Center(child: Text("No role assigned or invalid role")),
            );
        }

if (mounted) {
  switch (userData['role']) {
    case "District Collector":
      Navigator.pushReplacementNamed(context, '/district-collector-dashboard');
      break;
    case "Associate":
      Navigator.pushReplacementNamed(context, '/associate-dashboard');
      break;
    case "Ground Worker":
      Navigator.pushReplacementNamed(
        context, 
        '/ground-worker-dashboard',
        arguments: {
          'userId': userData['id'].toString(),
          'authToken': userData['token'],
        },
      );
      break;
    case "Hospital":
      Navigator.pushReplacementNamed(context, '/hospital-dashboard');
      break;
    case "Taluka Head":
      Navigator.pushReplacementNamed(
        context,
        '/taluka-head-dashboard',
        arguments: {
          'userEmail': userData['email'],
        },
      );
      break;
    default:
      // Show error screen using MaterialPageRoute since we don't have a named route for this
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Scaffold(
          appBar: AppBar(title: const Text("Error")),
          body: const Center(child: Text("No role assigned or invalid role")),
        )),
      );
  }
}
      } else {
        // Login failed
        final errorData = jsonDecode(response.body);
        _showErrorSnackBar(errorData['message'] ?? "Login failed");
      }
    } catch (error) {
      _showErrorSnackBar("Connection error. Please check your internet connection.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Test connection function
  Future<void> _testConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      if (response.statusCode == 200) {
        setState(() {
          _connectionStatus = true;
        });
        _showSuccessSnackBar('Connected to backend successfully!');
      } else {
        setState(() {
          _connectionStatus = false;
        });
        _showErrorSnackBar('Backend responded with status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _connectionStatus = false;
      });
      _showErrorSnackBar('Connection failed: Unable to reach server');
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primaryColor.withOpacity(0.8),
              theme.primaryColor.withOpacity(0.6),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: size.height * 0.05),
                      
                      // Logo and Title Section
                      _buildHeaderSection(),
                      
                      SizedBox(height: size.height * 0.06),
                      
                      // Connection Status Card
                      _buildConnectionStatusCard(),
                      
                      const SizedBox(height: 32),
                      
                      // Login Form Card
                      _buildLoginFormCard(),
                      
                      const SizedBox(height: 24),
                      
                      // Sign Up Link
                      _buildSignUpLink(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.admin_panel_settings,
            size: 50,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Welcome Back!",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Sign in to your account",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionStatusCard() {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _connectionStatus ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Backend Status",
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _connectionStatus ? "Connected" : "Disconnected",
                    style: TextStyle(
                      fontSize: 12,
                      color: _connectionStatus ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _testConnection,
              icon: const Icon(Icons.refresh),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
              tooltip: 'Test connection',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginFormCard() {
    return Card(
      elevation: 12,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email Field
            TextFormField(
              controller: _emailController,
              validator: _validateEmail,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email Address",
                hintText: "Enter your email",
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Password Field
            TextFormField(
              controller: _passwordController,
              validator: _validatePassword,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: "Password",
                hintText: "Enter your password",
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Login Button
            ElevatedButton(
              onPressed: _isLoading ? null : _loginUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      "Sign In",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return TextButton(
      onPressed: _isLoading
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SignupScreen()),
              );
            },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: RichText(
        text: TextSpan(
          text: "Don't have an account? ",
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
          children: [
            TextSpan(
              text: "Sign Up",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}