import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _hospitalNameController = TextEditingController();
  final _secretKeyController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedRole = "Villager"; // default role
  final AuthService _authService = AuthService();

  // Only roles that can self-register
  final List<String> _roles = [
    "District Collector",
    "Hospital",
    "Villager",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Signup")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),

            // Name (required for all)
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Full Name *",
                hintText: "Enter your full name",
              ),
            ),
            const SizedBox(height: 20),

            // Phone (required for all)
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Phone Number *",
                hintText: "Enter your phone number",
              ),
            ),
            const SizedBox(height: 20),

            // Email
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email *",
                hintText: "Enter your email address",
              ),
            ),
            const SizedBox(height: 20),

            // Password
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password *",
                hintText: "Enter a strong password",
              ),
            ),
            const SizedBox(height: 20),

            // Role Dropdown
            DropdownButtonFormField<String>(
              value: _selectedRole,
              items: _roles
                  .map((role) => DropdownMenuItem(
                        value: role,
                        child: Text(role),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedRole = value!),
              decoration: const InputDecoration(labelText: "Select Role"),
            ),
            const SizedBox(height: 20),

            // Role specific fields
            if (_selectedRole == "Hospital") ...[
              TextField(
                controller: _hospitalNameController,
                decoration: const InputDecoration(
                  labelText: "Hospital Name *",
                  hintText: "Enter hospital name",
                ),
              ),
            ] else if (_selectedRole == "District Collector") ...[
              TextField(
                controller: _secretKeyController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "District Collector Secret Key *",
                  hintText: "Enter the secret key provided",
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Note: Only authorized personnel should have this key",
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ],

            // Information about restricted roles
            if (_selectedRole == "Villager") ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Text(
                  "ℹ️ Note: Ground Workers, Taluka Heads, and Associates cannot register directly. They must be registered by their respective authorities.",
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ],

            const SizedBox(height: 30),

            // Signup Button
            ElevatedButton(
              onPressed: () async {
                // Validation
                if (_nameController.text.trim().isEmpty ||
                    _phoneController.text.trim().isEmpty ||
                    _emailController.text.trim().isEmpty ||
                    _passwordController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please fill all required fields")),
                  );
                  return;
                }

                // Hospital name validation
                if (_selectedRole == "Hospital" && 
                    _hospitalNameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Hospital name is required")),
                  );
                  return;
                }

                // Secret key check for District Collector
                if (_selectedRole == "District Collector" &&
                    _secretKeyController.text.trim() != "DC-MASTER-KEY-2025") {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Invalid District Collector Secret Key")),
                  );
                  return;
                }

                final user = await _authService.signUp(
                  _emailController.text.trim(),
                  _passwordController.text.trim(),
                  _selectedRole,
                  extraData: {
                    "name": _nameController.text.trim(),
                    "phone": _phoneController.text.trim(),
                    "hospitalName": _hospitalNameController.text.trim(),
                    "registeredBy": "self", // Self-registered
                    "registeredAt": DateTime.now().toIso8601String(),
                    "isActive": "true",
                  },
                );

                if (user != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("Account created successfully as $_selectedRole")),
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Registration failed. Please try again.")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                "Create Account",
                style: TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 20),

            // Information section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Registration Information:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text("• District Collector: Self-register with secret key"),
                  const Text("• Hospital: Self-register with hospital details"),
                  const Text("• Villager: Self-register freely"),
                  const SizedBox(height: 8),
                  const Text(
                    "Hierarchical Registration:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text("• Associates: Registered by District Collector"),
                  const Text("• Taluka Heads: Registered by Associates"),
                  const Text("• Ground Workers: Registered by Taluka Heads"),
                ],
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
    _hospitalNameController.dispose();
    _secretKeyController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}