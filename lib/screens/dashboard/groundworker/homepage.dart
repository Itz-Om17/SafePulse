import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HomePage extends StatefulWidget {
  final List<Map<String, dynamic>> previousSubmissions;

  const HomePage({super.key, required this.previousSubmissions});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  
  String? _currentUserName;
  List<dynamic> _assignedTasks = [];
  bool _isLoadingTasks = true;
  String? _currentUserId;
  static const String baseUrl = 'http://10.0.2.2:3000';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndTasks();
  }

Future<void> _loadCurrentUserAndTasks() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    _currentUserId   = prefs.getString('userId');
    _currentUserName = prefs.getString('userName'); // ← add this
  });
  print('🎯 READ FROM PREFS: $_currentUserName');     // quick check
  if (_currentUserName != null) {
    await _fetchAssignedTasks();
  } else {
    setState(() => _isLoadingTasks = false);          // empty state
  }
}
  Future<void> _fetchAssignedTasks() async {
    try {
        print(_currentUserName);
      final response = await http.get(
        Uri.parse('$baseUrl/api/tasks/worker/$_currentUserName'),
      );
      print('📣 STATUS: ${response.statusCode}');
      print('📣 BODY  : ${response.body}');


      if (response.statusCode == 200) {
        final tasks = jsonDecode(response.body);
        setState(() {
          _assignedTasks = tasks is List ? tasks : [];
          _isLoadingTasks = false;
        });
      } else {
        setState(() {
          _isLoadingTasks = false;
        });
      }
    } catch (error) {
      setState(() {
        _isLoadingTasks = false;
      });
      print('Error loading tasks: $error');
    }
  }

  Future<void> _updateTaskStatus(String taskId, String newStatus) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/tasks/$taskId/status'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task status updated to $newStatus')),
        );
        _fetchAssignedTasks(); // Refresh the list
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating task: $error')),
      );
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'No date';
    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  bool _isOverdue(String? dueDate) {
    if (dueDate == null) return false;
    try {
      return DateTime.parse(dueDate).isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final isOverdue = _isOverdue(task['dueDate']) && task['status'] != 'Completed';
    
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task['title'] ?? 'No Title',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'OVERDUE',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task['description'] ?? 'No description',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(task['priority']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    task['priority'] ?? 'Medium',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(task['status']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    task['status'] ?? 'Pending',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Due: ${_formatDate(task['dueDate'])}',
                  style: TextStyle(
                    color: isOverdue ? Colors.red : Colors.grey,
                    fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  'Assigned by: ${task['assignedBy'] ?? 'Taluka Head'}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (task['status'] != 'Completed')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: task['status'] == 'In Progress' 
                          ? null 
                          : () => _updateTaskStatus(task['_id'] ?? task['id'], 'In Progress'),
                      child: const Text('Start Task'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateTaskStatus(task['_id'] ?? task['id'], 'Completed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Mark Complete', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksSection() {
    if (_isLoadingTasks) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_assignedTasks.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.task_alt, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No Tasks Assigned',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'You currently have no tasks assigned to you.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    // Separate tasks by status for better organization
    final pendingTasks = _assignedTasks.where((t) => t['status'] == 'Pending').toList();
    final inProgressTasks = _assignedTasks.where((t) => t['status'] == 'In Progress').toList();
    final completedTasks = _assignedTasks.where((t) => t['status'] == 'Completed').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pending Tasks
        if (pendingTasks.isNotEmpty) ...[
          const Text(
            'Pending Tasks',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...pendingTasks.map((task) => _buildTaskCard(task)).toList(),
          const SizedBox(height: 16),
        ],

        // In Progress Tasks
        if (inProgressTasks.isNotEmpty) ...[
          const Text(
            'In Progress',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...inProgressTasks.map((task) => _buildTaskCard(task)).toList(),
          const SizedBox(height: 16),
        ],

        // Completed Tasks
        if (completedTasks.isNotEmpty) ...[
          const Text(
            'Completed Tasks',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...completedTasks.map((task) => _buildTaskCard(task)).toList(),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You have ${_assignedTasks.where((t) => t['status'] != 'Completed').length} active tasks',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: _assignedTasks.isEmpty ? 0 : 
                        _assignedTasks.where((t) => t['status'] == 'Completed').length / _assignedTasks.length,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Tasks Section
          const Text(
            'Your Assigned Tasks',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _buildTasksSection(),

          const SizedBox(height: 20),

          // Previous Submissions Section (existing code)
          const Text(
            'Recent Assessments',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...widget.previousSubmissions.map((submission) => Card(
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
}