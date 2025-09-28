import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DistrictCollectorDashboard extends StatefulWidget {
  const DistrictCollectorDashboard({super.key});

  @override
  State<DistrictCollectorDashboard> createState() => _DistrictCollectorDashboardState();
}

class _DistrictCollectorDashboardState extends State<DistrictCollectorDashboard> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const HomePage(),
    const PostsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('District Collector Dashboard'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.post_add),
            label: 'Posts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Home Page with Associate Registration
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
  late String? _selectedTaluka; // add at the top with other controllers
  late String? _selectedVillage; // with the other “late” vars
  List<String> _talukas = [];      // cached talukas
  bool _loadingTalukas = false;    // show spinner while downloading
  List<String> _villages = [];      // villages for selected taluka
  bool _loadingVillages = false;
  late String? _assignedVillage;   // village chosen for “assigned area”
  List<String> _assignedVillages = []; // villages for assigned-area dropdown
  bool _loadingAssignedVillages = false;
Future<List<String>> _talukasForDistrict() async {
  final prefs = await SharedPreferences.getInstance();
  final district = prefs.getString('userDistrict') ?? '';

  final url = Uri.parse(
      'https://raw.githubusercontent.com/pranshumaheshwari/indian-cities-and-villages/master/data.json');
  final resp = await http.get(url);
  if (resp.statusCode != 200) return [];

  final List<dynamic> data = jsonDecode(resp.body);
  final Set<String> talukas = {};

  for (final state in data) {
    for (final dist in state['districts'] ?? []) {
      if (dist['district'] == district) {
        for (final sub in dist['subDistricts'] ?? []) {
          talukas.add(sub['subDistrict']);
        }
      }
    }
  }
  return talukas.toList()..sort();
}
Future<void> _fetchAssignedVillages() async {
  if (_selectedTaluka == null) return;

  setState(() => _loadingAssignedVillages = true);

  try {
    final prefs = await SharedPreferences.getInstance();
    final district = prefs.getString('userDistrict') ?? '';

    final url = Uri.parse(
        'https://raw.githubusercontent.com/pranshumaheshwari/indian-cities-and-villages/master/data.json');
    final resp = await http.get(url);
    if (resp.statusCode != 200) return;

    final List<dynamic> data = jsonDecode(resp.body);
    final Set<String> villages = {};

    for (final state in data) {
      for (final dist in state['districts'] ?? []) {
        if (dist['district'] == district) {
          for (final sub in dist['subDistricts'] ?? []) {
            if (sub['subDistrict'] == _selectedTaluka) {
              for (final v in sub['villages'] ?? []) {
                villages.add(v);
              }
            }
          }
        }
      }
    }

    setState(() => _assignedVillages = villages.toList()..sort());
  } finally {
    setState(() => _loadingAssignedVillages = false);
  }
}
Future<void> _fetchVillages() async {
  if (_selectedTaluka == null) return; // nothing to do

  setState(() => _loadingVillages = true);

  try {
    final prefs = await SharedPreferences.getInstance();
    final district = prefs.getString('userDistrict') ?? '';

    final url = Uri.parse(
        'https://raw.githubusercontent.com/pranshumaheshwari/indian-cities-and-villages/master/data.json');
    final resp = await http.get(url);
    if (resp.statusCode != 200) return;

    final List<dynamic> data = jsonDecode(resp.body);
    final Set<String> villages = {};

    for (final state in data) {
      for (final dist in state['districts'] ?? []) {
        if (dist['district'] == district) {
          for (final sub in dist['subDistricts'] ?? []) {
            if (sub['subDistrict'] == _selectedTaluka) {
              for (final v in sub['villages'] ?? []) {
                villages.add(v);
              }
            }
          }
        }
      }
    }

    setState(() => _villages = villages.toList()..sort());
  } finally {
    setState(() => _loadingVillages = false);
  }
}
Future<void> _fetchTalukas() async {
  if (_talukas.isNotEmpty) return; // already cached

  setState(() => _loadingTalukas = true);

  try {
    final prefs = await SharedPreferences.getInstance();
    final district = prefs.getString('userDistrict') ?? '';

    final url = Uri.parse(
        'https://raw.githubusercontent.com/pranshumaheshwari/indian-cities-and-villages/master/data.json');
    final resp = await http.get(url);
    if (resp.statusCode != 200) return;

    final List<dynamic> data = jsonDecode(resp.body);
    final Set<String> talukas = {};

    for (final state in data) {
      for (final dist in state['districts'] ?? []) {
        if (dist['district'] == district) {
          for (final sub in dist['subDistricts'] ?? []) {
            talukas.add(sub['subDistrict']);
          }
        }
      }
    }

    setState(() => _talukas = talukas.toList()..sort());
  } finally {
    setState(() => _loadingTalukas = false);
  }
}
  // Configuration for backend URL
  static const String baseUrl = 'http://10.0.2.2:3000';
  @override
void initState() {
  super.initState();
  _selectedTaluka = null;
  _loadDistrict(); // ← pre-fill district
  _selectedVillage = null;
   _assignedVillage = null;
  _fetchTalukas();
}
  Future<void> _loadDistrict() async {
  final prefs = await SharedPreferences.getInstance();
  final district = prefs.getString('userDistrict') ?? '';
  _districtController.text = district;   // pre-fill
}
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Register Associates',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                  const Text(
                    'Upload a CSV or Excel file with associate details. The file should contain columns: name, email, phone, password, district, taluka, village, assigned_area, additional_info.',
                    style: TextStyle(color: Colors.grey),
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
                      onPressed: _uploadBulkAssociates,
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
               const SizedBox(height: 15),
TextFormField(
  controller: _districtController,
  decoration: const InputDecoration(
    labelText: 'District',
    border: OutlineInputBorder(),
  ),
  readOnly: true, // non-editable
),
const SizedBox(height: 15),
_loadingTalukas
    ? const LinearProgressIndicator() // tiny progress bar
    : DropdownButtonFormField<String>(
        value: _selectedTaluka,
        decoration: const InputDecoration(
          labelText: 'Taluka *',
          border: OutlineInputBorder(),
        ),
        items: _talukas
            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
            .toList(),
        onChanged: (val) {
  setState(() {
    _selectedTaluka = val;
    _selectedVillage = null; // reset village
    _villages.clear();
    _assignedVillage = null;
    _assignedVillages.clear();
  });
  _fetchVillages(); // ← new
  _fetchAssignedVillages();
},
        validator: (val) =>
            val == null ? 'Please choose a taluka' : null,
      ),
                const SizedBox(height: 15),
_loadingVillages
    ? const LinearProgressIndicator()
    : DropdownButtonFormField<String>(
        value: _selectedVillage,
        decoration: const InputDecoration(
          labelText: 'Village *',
          border: OutlineInputBorder(),
        ),
        items: _villages
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (val) => setState(() => _selectedVillage = val),
        validator: (val) =>
            val == null ? 'Please choose a village' : null,
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
                const SizedBox(height: 15),
_loadingAssignedVillages
    ? const LinearProgressIndicator()
    : DropdownButtonFormField<String>(
        value: _assignedVillage,
        decoration: const InputDecoration(
          labelText: 'Assigned Village *',
          border: OutlineInputBorder(),
        ),
        items: _assignedVillages
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (val) => setState(() => _assignedVillage = val),
        validator: (val) =>
            val == null ? 'Please choose an assigned village' : null,
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
                  onPressed: _isLoading ? null : _registerAssociate,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Register Associate'),
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

  Future<void> _uploadBulkAssociates() async {
    // Implement CSV/Excel processing and bulk registration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bulk registration feature will be implemented here')),
    );
  }

  Future<void> _registerAssociate() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await http.post(
          Uri.parse('$baseUrl/api/associates/register'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode({
            "name": _nameController.text.trim(),
            "email": _emailController.text.trim(),
            "phone": _phoneController.text.trim(),
            "password": _passwordController.text.trim(),
            "registeredBy": "District Collector", // You might want to use the actual user ID
            "district": _districtController.text.trim(),
            "taluka": _selectedTaluka,
            "village": _selectedVillage ?? '',
            "assignedArea": _assignedVillage ?? '',
            "additionalInfo": _additionalInfoController.text.trim(),
          }),
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Associate registered successfully!')),
          );
          // Clear form
           _nameController.clear();
          _emailController.clear();
          _phoneController.clear();
          _passwordController.clear();
          _assignedAreaController.clear();
          _additionalInfoController.clear();
          // clear dropdown selections
          setState(() {
            _selectedTaluka = null;
            _selectedVillage = null;
            _assignedVillage = null;
            _villages.clear();
            _assignedVillages.clear();
            });
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
    _additionalInfoController.dispose();
    super.dispose();
  }
}

// Posts Page
class PostsPage extends StatelessWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Posts Management',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// Profile Page
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;
  late final TextEditingController _districtController;
  @override
  void initState() {
    _districtController = TextEditingController(); // ← must create it
    super.initState();
    // Load user data (you would fetch this from your backend)
    _loadDistrict();
  }
  Future<void> _loadDistrict() async {
  final prefs = await SharedPreferences.getInstance();
  final district = prefs.getString('userDistrict') ?? '';
  final state    = prefs.getString('userState')    ?? '';   // add this line
  _districtController.text = district;   // pre-fill
}
  void _loadUserData() {
    // Mock data - replace with actual API call
    _nameController.text = 'District Collector Name';
    _emailController.text = 'collector@district.gov';
    _phoneController.text = '1234567890';
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Navigate to login screen and remove all previous routes
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue,
            child: Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            enabled: _isEditing,
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            enabled: _isEditing,
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone',
              border: OutlineInputBorder(),
            ),
            enabled: _isEditing,
          ),
          const SizedBox(height: 15),
TextFormField(
  controller: _districtController,
  decoration: const InputDecoration(
    labelText: 'District',
    border: OutlineInputBorder(),
  ),
  readOnly: true, // non-editable
),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (!_isEditing)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  child: const Text('Edit Profile'),
                ),
              if (_isEditing)
                ElevatedButton(
                  onPressed: () {
                    // Save changes
                    _saveProfile();
                    setState(() {
                      _isEditing = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated successfully!')),
                    );
                  },
                  child: const Text('Save Changes'),
                ),
              if (_isEditing)
                TextButton(
                  onPressed: () {
                    // Cancel editing
                    _loadUserData(); // Reload original data
                    setState(() {
                      _isEditing = false;
                    });
                  },
                  child: const Text('Cancel'),
                ),
            ],
          ),
          const SizedBox(height: 30),
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveProfile() {
    // Implement API call to update profile
    print('Saving profile: ${_nameController.text}, ${_emailController.text}, ${_phoneController.text}');
    // You would make an HTTP PUT request to your backend here
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _districtController.dispose(); // ← add this
    super.dispose();
  }
}