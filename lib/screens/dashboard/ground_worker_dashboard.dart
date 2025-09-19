import 'package:flutter/material.dart';
import 'groundworker/homepage.dart';
import 'groundworker/new_report.dart';
import 'groundworker/profile.dart';

class GroundWorkerDashboard extends StatefulWidget {
  const GroundWorkerDashboard({super.key});

  @override
  State<GroundWorkerDashboard> createState() => _GroundWorkerDashboardState();
}

class _GroundWorkerDashboardState extends State<GroundWorkerDashboard> {
  int _currentIndex = 0;
  
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
              onPressed: () {
                // You'll need to pass a function to submit the form
                // This might require some refactoring to expose the form submission method
              },
              child: const Icon(Icons.cloud_upload),
            )
          : null,
    );
  }

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return HomePage(previousSubmissions: _previousSubmissions);
      case 1:
        return NewReport(dummyIoTData: _dummyIoTData);
      case 2:
        return ProfileScreen(profileData: _profileData);
      default:
        return HomePage(previousSubmissions: _previousSubmissions);
    }
  }
}