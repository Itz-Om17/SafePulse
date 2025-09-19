import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _hospitalNameController = TextEditingController();
  final _secretKeyController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedRole = "Villager";
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureSecretKey = true;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Only roles that can self-register
  final List<String> _roles = [
    "District Collector",
    "Hospital",
    "Villager",
  ];

  final Map<String, IconData> _roleIcons = {
    "District Collector": Icons.account_balance,
    "Hospital": Icons.local_hospital,
    "Villager": Icons.person,
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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

  // Function to register user
  Future<void> _registerUser() async {
    setState(() {
      _isLoading = true;
    });

    // Prepare data
    Map<String, dynamic> userData = {
      "name": _nameController.text.trim(),
      "phone": _phoneController.text.trim(),
      "email": _emailController.text.trim(),
      "password": _passwordController.text.trim(),
      "role": _selectedRole,
      "hospitalName": _hospitalNameController.text.trim(),
      "secretKey": _secretKeyController.text.trim(),
      "registeredBy": "self",
      "registeredAt": DateTime.now().toIso8601String(),
      "isActive": "true",
    };

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/auth/register'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(userData),
      );

      if (response.statusCode == 201) {
        _showSuccessSnackBar("Account created successfully as $_selectedRole");
        Navigator.pop(context);
      } else {
        final errorData = jsonDecode(response.body);
        _showErrorSnackBar(errorData['message'] ?? "Registration failed");
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
        margin: const EdgeInsets.all(16),
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
        margin: const EdgeInsets.all(16),
      ),
    );
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

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    if (value.length < 10) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
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
                      // Header Section
                      _buildHeaderSection(),
                      
                      const SizedBox(height: 32),
                      
                      // Main Form Card
                      _buildMainFormCard(),
                      
                      const SizedBox(height: 24),
                      
                      // Information Cards
                      _buildInformationCards(),
                      
                      const SizedBox(height: 24),
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
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: 80,
          height: 80,
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
            Icons.person_add,
            size: 40,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Create Account",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Join our community today",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildMainFormCard() {
    return Card(
      elevation: 12,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Role Selection First
            Text(
              "Select Your Role",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            _buildRoleSelector(),
            
            const SizedBox(height: 24),
            
            // Basic Information
            Text(
              "Basic Information",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            
            // Name Field
            _buildTextFormField(
              controller: _nameController,
              label: "Full Name",
              hint: "Enter your full name",
              icon: Icons.person_outline,
              validator: (value) => _validateRequired(value, "full name"),
            ),
            
            const SizedBox(height: 16),
            
            // Phone Field
            _buildTextFormField(
              controller: _phoneController,
              label: "Phone Number",
              hint: "Enter your phone number",
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: _validatePhone,
            ),
            
            const SizedBox(height: 16),
            
            // Email Field
            _buildTextFormField(
              controller: _emailController,
              label: "Email Address",
              hint: "Enter your email address",
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            
            const SizedBox(height: 16),
            
            // Password Field
            _buildTextFormField(
              controller: _passwordController,
              label: "Password",
              hint: "Enter a strong password",
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              validator: _validatePassword,
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            
            // Role-specific fields
            _buildRoleSpecificFields(),
            
            const SizedBox(height: 32),
            
            // Create Account Button
            _buildCreateAccountButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: _roles.map((role) {
          final isSelected = _selectedRole == role;
          return InkWell(
            onTap: () => setState(() => _selectedRole = role),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _roleIcons[role] ?? Icons.person,
                    color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      role,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                      ),
                    ),
                  ),
                  Radio<String>(
                    value: role,
                    groupValue: _selectedRole,
                    onChanged: (value) => setState(() => _selectedRole = value!),
                    activeColor: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRoleSpecificFields() {
    if (_selectedRole == "Hospital") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            "Hospital Information",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _hospitalNameController,
            label: "Hospital Name",
            hint: "Enter hospital name",
            icon: Icons.local_hospital_outlined,
            validator: (value) => _validateRequired(value, "hospital name"),
          ),
        ],
      );
    } else if (_selectedRole == "District Collector") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            "Authorization Required",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _secretKeyController,
            label: "District Collector Secret Key",
            hint: "Enter the secret key provided",
            icon: Icons.security_outlined,
            obscureText: _obscureSecretKey,
            validator: (value) => _validateRequired(value, "secret key"),
            suffixIcon: IconButton(
              icon: Icon(_obscureSecretKey ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscureSecretKey = !_obscureSecretKey),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_outlined, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Only authorized personnel should have this key",
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
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
    );
  }

  Widget _buildCreateAccountButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleCreateAccount,
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
              "Create Account",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  void _handleCreateAccount() async {
    if (!_formKey.currentState!.validate()) return;

    // Hospital name validation
    if (_selectedRole == "Hospital" && _hospitalNameController.text.trim().isEmpty) {
      _showErrorSnackBar("Hospital name is required");
      return;
    }

    // Secret key check for District Collector
    if (_selectedRole == "District Collector" &&
        _secretKeyController.text.trim() != "DC-MASTER-KEY-2025") {
      _showErrorSnackBar("Invalid District Collector Secret Key");
      return;
    }

    await _registerUser();
  }

  Widget _buildInformationCards() {
    return Column(
      children: [
        if (_selectedRole == "Villager") _buildRestrictedRolesCard(),
        const SizedBox(height: 16),
        _buildRegistrationInfoCard(),
      ],
    );
  }

  Widget _buildRestrictedRolesCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Important Note",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Ground Workers, Taluka Heads, and Associates cannot register directly. They must be registered by their respective authorities.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Text(
                  "Registration Information",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoItem("District Collector", "Self-register with secret key", Icons.account_balance),
            _buildInfoItem("Hospital", "Self-register with hospital details", Icons.local_hospital),
            _buildInfoItem("Villager", "Self-register freely", Icons.person),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              "Hierarchical Registration:",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            _buildHierarchyItem("Associates", "Registered by District Collector"),
            _buildHierarchyItem("Taluka Heads", "Registered by Associates"),
            _buildHierarchyItem("Ground Workers", "Registered by Taluka Heads"),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String role, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            "$role: ",
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          ),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHierarchyItem(String role, String registeredBy) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(Icons.arrow_right, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            "$role: ",
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          ),
          Expanded(
            child: Text(
              registeredBy,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ),
        ],
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
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}