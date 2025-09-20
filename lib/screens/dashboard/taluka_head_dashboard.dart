import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'taluka_head/homepage.dart' as homepage;
import 'taluka_head/posts_page.dart' as posts;
import 'taluka_head/profile_page.dart' as profile;

class TalukaHeadDashboard extends StatefulWidget {
  final String userEmail;
  const TalukaHeadDashboard({super.key, required this.userEmail});

  @override
  State<TalukaHeadDashboard> createState() => _TalukaHeadDashboardState();
}

class _TalukaHeadDashboardState extends State<TalukaHeadDashboard> {
  int _currentIndex = 0;
  String? _talukaHeadTaluka;
  bool _isLoadingUserData = true;

  // Configuration for backend URL
  static const String baseUrl = 'http://10.0.2.2:3000';

  @override
  void initState() {
    super.initState();
    _fetchTalukaHeadData();
  }

  Future<void> _fetchTalukaHeadData() async {
    try {
      print('Fetching taluka head data for email: ${widget.userEmail}');
      
      final userResponse = await http.get(
        Uri.parse('$baseUrl/api/users/email/${widget.userEmail}'),
      );

      print('User API response: ${userResponse.statusCode}');
      print('User API body: ${userResponse.body}');
      
      if (userResponse.statusCode == 200) {
        final userData = jsonDecode(userResponse.body);
        final userId = userData['data']['id'];
        print('User ID: $userId');

        // Then get taluka head data
        final talukaHeadResponse = await http.get(
          Uri.parse('$baseUrl/api/taluka-heads/user/$userId'),
        );

        print('Taluka Head API response: ${talukaHeadResponse.statusCode}');
        print('Taluka Head API body: ${talukaHeadResponse.body}');

        if (talukaHeadResponse.statusCode == 200) {
          final talukaHeadData = jsonDecode(talukaHeadResponse.body);
          setState(() {
            _talukaHeadTaluka = talukaHeadData['data']['taluka'];
            _isLoadingUserData = false;
          });
          print('Taluka set to: $_talukaHeadTaluka');
        } else {
          // Handle API error
          print('Taluka head API returned non-200 status');
          _handleLoadingError();
        }
      } else {
        // Handle API error
        print('User API returned non-200 status');
        _handleLoadingError();
      }
    } catch (error) {
      print('Error fetching taluka head data: $error');
      _handleLoadingError();
    }
  }

  void _handleLoadingError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to load dashboard data. Using default taluka.')),
    );
    setState(() {
      _talukaHeadTaluka = "Default Taluka";
      _isLoadingUserData = false;
    });
  }

  void _updateTaluka(String newTaluka) {
    setState(() {
      _talukaHeadTaluka = newTaluka;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isLoadingUserData
            ? const Text('Loading...')
            : Text('Taluka Head Dashboard - ${_talukaHeadTaluka ?? "Unknown"}'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoadingUserData
          ? const Center(child: CircularProgressIndicator())
          : _buildCurrentPage(),
      bottomNavigationBar: _isLoadingUserData
          ? null
          : BottomNavigationBar(
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

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return homepage.GroundWorkerRegistrationPage(
          talukaHeadTaluka: _talukaHeadTaluka,
          onTalukaUpdated: _updateTaluka,
        );
      case 1:
        return const posts.PostsPage();
      case 2:
        return profile.ProfilePage(
          userEmail: widget.userEmail,
          talukaHeadTaluka: _talukaHeadTaluka,
          onTalukaUpdated: _updateTaluka,
        );
      default:
        return const Center(child: Text('Page not found'));
    }
  }
}