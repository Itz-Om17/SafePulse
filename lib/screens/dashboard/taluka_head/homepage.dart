import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

// Ground Worker Registration Page
class GroundWorkerRegistrationPage extends StatefulWidget {
  final String? talukaHeadTaluka;
  final Function(String)? onTalukaUpdated;
  const GroundWorkerRegistrationPage({
    super.key,
    required this.talukaHeadTaluka,
    required this.onTalukaUpdated,
  });

  @override
  State<GroundWorkerRegistrationPage> createState() => _GroundWorkerRegistrationPageState();
}

class _GroundWorkerRegistrationPageState extends State<GroundWorkerRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _districtController = TextEditingController();
  final _talukaController = TextEditingController();
  final _villageController = TextEditingController();
  final _assignedAreaController = TextEditingController();
  final _additionalInfoController = TextEditingController();
  bool _isLoading = false;
  String? _selectedFile;

  static const String baseUrl = 'http://10.0.2.2:3000';

  @override
  void initState() {
    super.initState();
    _updateTalukaField();
  }

  @override
  void didUpdateWidget(covariant GroundWorkerRegistrationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateTalukaField();
  }

  void _updateTalukaField() {
    if (widget.talukaHeadTaluka != null && 
        widget.talukaHeadTaluka != _talukaController.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _talukaController.text = widget.talukaHeadTaluka!;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure taluka field is always synced during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.talukaHeadTaluka != null && 
          widget.talukaHeadTaluka != _talukaController.text) {
        _talukaController.text = widget.talukaHeadTaluka!;
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Register Ground Workers for ${_talukaController.text.isNotEmpty ? _talukaController.text : "Your Taluka"}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // CSV/Excel Upload Section
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bulk Registration (CSV/Excel)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Upload a CSV or Excel file with ground worker details for ${_talukaController.text.isNotEmpty ? _talukaController.text : "your taluka"}. The file should contain columns: name, email, phone, password, district, village, assigned_area, additional_info.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Select File'),
                      ),
                      const SizedBox(width: 10),
                      if (_selectedFile != null)
                        Expanded(
                          child: Text(
                            _selectedFile!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_selectedFile != null)
                    ElevatedButton(
                      onPressed: _uploadBulkGroundWorkers,
                      child: const Text('Process File'),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 20),
          
          // Manual Registration Section
          const Text(
            'Manual Registration',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          Form(
            key: _formKey,
            child: Column(
              children: [
                // Basic Information
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Basic Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password *',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                
                // Location Information
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Location Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _districtController,
                  decoration: const InputDecoration(
                    labelText: 'District',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _talukaController,
                  decoration: InputDecoration(
                    labelText: 'Taluka *',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  readOnly: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Taluka is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _villageController,
                  decoration: const InputDecoration(
                    labelText: 'Village *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a village';
                    }
                    return null;
                  },
                ),
                
                // Additional Information
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Additional Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _assignedAreaController,
                  decoration: const InputDecoration(
                    labelText: 'Assigned Area',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _additionalInfoController,
                  decoration: const InputDecoration(
                    labelText: 'Additional Information',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _registerGroundWorker,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Register Ground Worker'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting file: $e')),
      );
    }
  }

  Future<void> _uploadBulkGroundWorkers() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bulk registration will use taluka: ${_talukaController.text}')),
    );
  }

  Future<void> _registerGroundWorker() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await http.post(
          Uri.parse('$baseUrl/api/ground-workers/register'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode({
            "name": _nameController.text.trim(),
            "email": _emailController.text.trim(),
            "phone": _phoneController.text.trim(),
            "password": _passwordController.text.trim(),
            "registeredBy": "Taluka Head",
            "district": _districtController.text.trim(),
            "taluka": _talukaController.text.trim(),
            "village": _villageController.text.trim(),
            "assignedArea": _assignedAreaController.text.trim(),
            "additionalInfo": _additionalInfoController.text.trim(),
          }),
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ground Worker registered successfully!')),
          );
          // Clear form
          _nameController.clear();
          _emailController.clear();
          _phoneController.clear();
          _passwordController.clear();
          _districtController.clear();
          _villageController.clear();
          _assignedAreaController.clear();
          _additionalInfoController.clear();
        } else {
          final errorData = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorData['message'] ?? 'Registration failed')),
          );
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${error.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _districtController.dispose();
    _talukaController.dispose();
    _villageController.dispose();
    _assignedAreaController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }
}