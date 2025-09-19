import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Water Disease Monitoring',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const GroundWorkerDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GroundWorkerDashboard extends StatefulWidget {
  const GroundWorkerDashboard({super.key});

  @override
  State<GroundWorkerDashboard> createState() => _GroundWorkerDashboardState();
}

class _GroundWorkerDashboardState extends State<GroundWorkerDashboard> {
  int _currentIndex = 0;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Form data
  String _villageName = '';
  int _affectedPeople = 0;
  int _symptomaticPeople = 0;
  double _turbidity = 0.0;
  double _phLevel = 7.0;
  double _tdsLevel = 0.0;
  String _notes = '';
  DateTime _selectedDate = DateTime.now();
  
  // Dummy IoT data
  final Map<String, double> _dummyIoTData = {
    'turbidity': 8.5,
    'phLevel': 6.2,
    'tdsLevel': 450.0,
  };

  // Profile data
  final Map<String, String> _profileData = {
    'name': 'Rajesh Kumar',
    'email': 'rajesh.kumar@waterhealth.org',
    'phone': '+91 98765 43210',
    'region': 'Uttar Pradesh',
    'employeeId': 'WH-UP-0042'
  };

  final List<Map<String, dynamic>> _previousSubmissions = [
    {
      'village': 'Shivpur',
      'date': '2023-10-15',
      'affected': 12,
      'riskLevel': 'High'
    },
    {
      'village': 'Deviganj',
      'date': '2023-10-08',
      'affected': 5,
      'riskLevel': 'Moderate'
    },
    {
      'village': 'Ambetha',
      'date': '2023-10-01',
      'affected': 2,
      'riskLevel': 'Low'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Health Monitor'),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      body: _getCurrentScreen(),
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
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'New Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              onPressed: _submitForm,
              child: const Icon(Icons.cloud_upload),
            )
          : null,
    );
  }

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildDataForm();
      case 2:
        return _buildProfile();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Village Assessments',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.warning, color: Colors.orange),
                    title: Text('Next Assessment Due'),
                    subtitle: Text('Complete within 2 days'),
                  ),
                  LinearProgressIndicator(
                    value: 0.7,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                  ),
                  const SizedBox(height: 8),
                  const Text('3 of 5 villages completed'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Recent Submissions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._previousSubmissions.map((submission) => Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: Icon(
                Icons.water_damage,
                color: submission['riskLevel'] == 'High'
                    ? Colors.red
                    : submission['riskLevel'] == 'Moderate'
                    ? Colors.orange
                    : Colors.green,
              ),
              title: Text(submission['village']),
              subtitle: Text('${submission['date']} - ${submission['affected']} affected'),
              trailing: Chip(
                label: Text(
                  submission['riskLevel'],
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                backgroundColor: submission['riskLevel'] == 'High'
                    ? Colors.red
                    : submission['riskLevel'] == 'Moderate'
                    ? Colors.orange
                    : Colors.green,
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildDataForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Village Water Health Assessment',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Village Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter village name';
                }
                return null;
              },
              onSaved: (value) => _villageName = value!,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Affected People',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.sick),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a number';
                      }
                      return null;
                    },
                    onSaved: (value) => _affectedPeople = int.parse(value!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Symptomatic People',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.medical_services),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a number';
                      }
                      return null;
                    },
                    onSaved: (value) => _symptomaticPeople = int.parse(value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'IoT Water Quality Data',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Turbidity:'),
                        Text('${_dummyIoTData['turbidity']} NTU'),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _turbidity = _dummyIoTData['turbidity']!;
                            });
                          },
                          child: const Text('Use IoT Data'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('pH Level:'),
                        Text('${_dummyIoTData['phLevel']}'),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _phLevel = _dummyIoTData['phLevel']!;
                            });
                          },
                          child: const Text('Use IoT Data'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TDS Level:'),
                        Text('${_dummyIoTData['tdsLevel']} ppm'),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _tdsLevel = _dummyIoTData['tdsLevel']!;
                            });
                          },
                          child: const Text('Use IoT Data'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Turbidity (NTU)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.water),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: _turbidity == 0 ? '' : _turbidity.toString(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter turbidity value';
                      }
                      return null;
                    },
                    onChanged: (value) => _turbidity = double.tryParse(value) ?? 0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'pH Level',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.science),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: _phLevel == 7.0 ? '' : _phLevel.toString(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter pH value';
                      }
                      return null;
                    },
                    onChanged: (value) => _phLevel = double.tryParse(value) ?? 7.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'TDS Level (ppm)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.analytics),
              ),
              keyboardType: TextInputType.number,
              initialValue: _tdsLevel == 0 ? '' : _tdsLevel.toString(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter TDS value';
                }
                return null;
              },
              onChanged: (value) => _tdsLevel = double.tryParse(value) ?? 0,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Additional Notes',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              onSaved: (value) => _notes = value ?? '',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 16),
                Text('Date of Assessment: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}'),
                const Spacer(),
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: const Text('Select Date'),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage('https://randomuser.me/api/portraits/men/32.jpg'),
          ),
          const SizedBox(height: 16),
          Text(
            _profileData['name']!,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            _profileData['employeeId']!,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.email),
                    title: Text('Email'),
                    subtitle: Text('rajesh.kumar@waterhealth.org'),
                  ),
                  const Divider(),
                  const ListTile(
                    leading: Icon(Icons.phone),
                    title: Text('Phone'),
                    subtitle: Text('+91 98765 43210'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: const Text('Region'),
                    subtitle: Text(_profileData['region']!),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Account Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            children: [
              ElevatedButton(
                onPressed: () {},
                child: const Text('Edit Profile'),
              ),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Change Password'),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Logout'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      // Here you would typically send the data to your MongoDB database
      // For now, we'll just show a confirmation dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Data Submitted'),
            content: Text('Village: $_villageName\nAffected: $_affectedPeople\nTurbidity: $_turbidity NTU'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Reset form
                  _formKey.currentState!.reset();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
}