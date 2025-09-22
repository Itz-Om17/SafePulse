import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

// Ground Worker Registration Page with Tasks Management
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
  final _taskTitleController = TextEditingController();
  final _taskDescriptionController = TextEditingController();
  final _taskDueDateController = TextEditingController();
  final _taskPriorityController = TextEditingController(text: 'Medium');

  bool _isLoading = false;
  bool _showManualRegistration = false;
  String? _selectedFile;
  List<dynamic> _groundWorkers = [];
  List<dynamic> _allTasks = [];
  bool _isLoadingWorkers = true;
  bool _isLoadingTasks = true;
  int _selectedTabIndex = 0;

  static const String baseUrl = 'http://10.0.2.2:3000';

  @override
  void initState() {
    super.initState();
    _updateTalukaField();
    _fetchGroundWorkers();
    _fetchAllTasks();
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

  Future<void> _fetchGroundWorkers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/ground-workers/taluka/${widget.talukaHeadTaluka}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        setState(() {
          _groundWorkers = data['data'] ?? [];
          _isLoadingWorkers = false;
        });
      }
    } catch (error) {
      setState(() {
        _isLoadingWorkers = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading ground workers: $error')),
      );
    }
  }

  Future<void> _fetchAllTasks() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/tasks/taluka/${widget.talukaHeadTaluka}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> tasks = jsonDecode(response.body);
        setState(() {
          _allTasks = tasks;
          _isLoadingTasks = false;
        });
      }
    } catch (error) {
      setState(() {
        _isLoadingTasks = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading tasks: $error')),
      );
    }
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/tasks/$taskId'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted successfully')),
        );
        _fetchAllTasks(); // Refresh tasks list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete task')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting task: $error')),
      );
    }
  }

  Widget _buildTasksOverview() {
    if (_isLoadingTasks) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allTasks.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.task_alt, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No tasks assigned yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Start by assigning tasks to your ground workers',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Task Statistics
    final pendingTasks = _allTasks.where((task) => task['status'] == 'Pending').length;
    final inProgressTasks = _allTasks.where((task) => task['status'] == 'In Progress').length;
    final completedTasks = _allTasks.where((task) => task['status'] == 'Completed').length;
    final highPriorityTasks = _allTasks.where((task) => task['priority'] == 'High').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Task Statistics Cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard('Total Tasks', _allTasks.length.toString(), Colors.blue),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard('Pending', pendingTasks.toString(), Colors.orange),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildStatCard('In Progress', inProgressTasks.toString(), Colors.purple),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard('Completed', completedTasks.toString(), Colors.green),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildStatCard('High Priority', highPriorityTasks.toString(), Colors.red),
            ),
            const SizedBox(width: 10),
            const Expanded(child: SizedBox()), // Empty space for alignment
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Recent Tasks List
        const Text(
          'All Tasks',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        
        ..._allTasks.map((task) => Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(task['status']),
              child: Icon(
                _getStatusIcon(task['status']),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              task['title'] ?? 'No Title',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assigned to: ${task['assignedToName'] ?? 'Unknown'}'),
                Text('Due: ${_formatDate(task['dueDate'])}'),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(task['description'] ?? 'No description'),
                    const SizedBox(height: 10),
                    Text(
                      'Assigned by: ${task['assignedBy'] ?? 'Unknown'}',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                    Text(
                      'Created: ${_formatDate(task['createdAt'])}',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _editTask(task),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit'),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => _confirmDeleteTask(task),
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text('Delete'),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'In Progress':
        return Colors.purple;
      case 'Completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'Pending':
        return Icons.schedule;
      case 'In Progress':
        return Icons.work;
      case 'Completed':
        return Icons.check_circle;
      default:
        return Icons.help;
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

  void _confirmDeleteTask(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTask(task['_id'] ?? task['id']);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editTask(Map<String, dynamic> task) {
    final _editTitleController = TextEditingController(text: task['title']);
    final _editDescriptionController = TextEditingController(text: task['description']);
    final _editDueDateController = TextEditingController(
      text: task['dueDate'] != null 
        ? DateTime.parse(task['dueDate']).toString().split(' ')[0]
        : ''
    );
    final _editPriorityController = TextEditingController(text: task['priority'] ?? 'Medium');
    final _editStatusController = TextEditingController(text: task['status'] ?? 'Pending');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Task'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _editTitleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _editDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _editDueDateController,
                decoration: const InputDecoration(
                  labelText: 'Due Date (YYYY-MM-DD)',
                  border: OutlineInputBorder(),
                ),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    _editDueDateController.text = 
                      "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                  }
                },
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _editPriorityController.text,
                items: ['Low', 'Medium', 'High']
                    .map((priority) => DropdownMenuItem(
                          value: priority,
                          child: Text(priority),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    _editPriorityController.text = value;
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _editStatusController.text,
                items: ['Pending', 'In Progress', 'Completed']
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    _editStatusController.text = value;
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _updateTask(
                task['_id'] ?? task['id'],
                title: _editTitleController.text,
                description: _editDescriptionController.text,
                dueDate: _editDueDateController.text,
                priority: _editPriorityController.text,
                status: _editStatusController.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateTask(String taskId, {
    String? title,
    String? description,
    String? dueDate,
    String? priority,
    String? status,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/tasks/$taskId'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          "title": title,
          "description": description,
          "dueDate": dueDate,
          "priority": priority,
          "status": status,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task updated successfully')),
        );
        _fetchAllTasks(); // Refresh tasks list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update task')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating task: $error')),
      );
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

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(
                icon: Icon(Icons.people),
                text: 'Ground Workers',
              ),
              Tab(
                icon: Icon(Icons.task_alt),
                text: 'Tasks Management',
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Ground Workers Tab
                _buildGroundWorkersTab(),
                // Tasks Management Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildTasksOverview(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroundWorkersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Existing Ground Workers Section
          Text(
            'Existing Ground Workers in ${_talukaController.text.isNotEmpty ? _talukaController.text : "Your Taluka"}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          
          _isLoadingWorkers
              ? const Center(child: CircularProgressIndicator())
              : _groundWorkers.isEmpty
                  ? const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No ground workers registered yet.'),
                      ),
                    )
                  : Column(
                      children: _groundWorkers.map((worker) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(worker['name'] ?? 'Unknown'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Assigned Area: ${worker['assignedArea'] ?? worker['assigned_area'] ?? 'Not assigned'}'),
                              Text('Village: ${worker['village'] ?? 'Unknown'}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _editGroundWorker(worker),
                                tooltip: 'Edit Ground Worker',
                              ),
                              IconButton(
                                icon: const Icon(Icons.task, size: 20),
                                onPressed: () => _assignTask(worker),
                                tooltip: 'Assign Task',
                              ),
                            ],
                          ),
                        ),
                      )).toList(),
                    ),
          
          const SizedBox(height: 30),
          const Divider(),
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
          
          // Manual Registration Toggle
          Row(
            children: [
              const Text(
                'Manual Registration',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _showManualRegistration ? Icons.expand_less : Icons.expand_more,
                ),
                onPressed: () {
                  setState(() {
                    _showManualRegistration = !_showManualRegistration;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 15),
          
          // Manual Registration Form (Collapsible)
          if (_showManualRegistration) _buildManualRegistrationForm(),
        ],
      ),
    );
  }

  Widget _buildManualRegistrationForm() {
    return Form(
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
    );
  }

  void _editGroundWorker(Map<String, dynamic> worker) {
    final _assignedAreaEditController = TextEditingController(text: worker['assignedArea'] ?? '');
    final _villageEditController = TextEditingController(text: worker['village'] ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Ground Worker'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _assignedAreaEditController,
                decoration: const InputDecoration(
                  labelText: 'Assigned Area',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _villageEditController,
                decoration: const InputDecoration(
                  labelText: 'Village',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Call your update API
              await _updateGroundWorker(
                worker['id'],
                assignedArea: _assignedAreaEditController.text,
                village: _villageEditController.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateGroundWorker(String id, {String? assignedArea, String? village}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/ground-workers/$id'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          "assignedArea": assignedArea,
          "village": village,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ground worker updated successfully')),
        );
        _fetchGroundWorkers(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update ground worker')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating ground worker: $error')),
      );
    }
  }

  void _assignTask(Map<String, dynamic> worker) {
    // Reset form values when opening the dialog
    _taskTitleController.clear();
    _taskDescriptionController.clear();
    _taskDueDateController.clear();
    _taskPriorityController.text = 'Medium';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Assign Task to ${worker['name']}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _taskTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Task Title *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _taskDescriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Task Description *',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _taskDueDateController,
                    decoration: const InputDecoration(
                      labelText: 'Due Date (YYYY-MM-DD) *',
                      border: OutlineInputBorder(),
                    ),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _taskDueDateController.text = 
                            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: _taskPriorityController.text,
                    items: ['Low', 'Medium', 'High']
                        .map((priority) => DropdownMenuItem(
                              value: priority,
                              child: Text(priority),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _taskPriorityController.text = value;
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Priority *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_taskTitleController.text.isEmpty ||
                      _taskDescriptionController.text.isEmpty ||
                      _taskDueDateController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please fill all required fields')),
                    );
                    return;
                  }

                  // Validate date format
                  final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}');
                  if (!dateRegex.hasMatch(_taskDueDateController.text)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please use YYYY-MM-DD date format')),
                    );
                    return;
                  }
                  
                  await _saveTask(worker);
                  Navigator.pop(context);
                },
                child: const Text('Assign Task'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveTask(Map<String, dynamic> worker) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First, get the current user's details
      final String userId = "current_user_id"; // Get this dynamically
      
      final userResponse = await http.get(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      String assignedByName = "Taluka Head";
      
      if (userResponse.statusCode == 200) {
        final userData = jsonDecode(userResponse.body);
        assignedByName = userData['name'] ?? "Taluka Head";
      }

      // Then create the task
      final response = await http.post(
        Uri.parse('$baseUrl/api/tasks'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          "title": _taskTitleController.text.trim(),
          "description": _taskDescriptionController.text.trim(),
          "assignedTo": worker['_id'] ?? worker['id'],
          "assignedToName": worker['name'] ?? 'Unknown Worker',
          "assignedBy": assignedByName, // Use the dynamically fetched name
          "dueDate": _taskDueDateController.text.trim(),
          "priority": _taskPriorityController.text.trim(),
          "taluka": _talukaController.text.trim(),
          "status": "Pending",
          "createdAt": DateTime.now().toIso8601String(),
          "updatedAt": DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task assigned successfully!')),
        );
        
        // Clear the form
        _taskTitleController.clear();
        _taskDescriptionController.clear();
        _taskDueDateController.clear();
        _taskPriorityController.text = 'Medium';
        
        // Refresh the tasks list
        _fetchAllTasks();
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorData['message'] ?? 'Failed to assign task')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error assigning task: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
          
          // Refresh the ground workers list
          _fetchGroundWorkers();
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
    _taskTitleController.dispose();
    _taskDescriptionController.dispose();
    _taskDueDateController.dispose();
    _taskPriorityController.dispose();
    super.dispose();
  }
}