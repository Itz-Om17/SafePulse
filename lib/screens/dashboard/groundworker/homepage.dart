import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final List<Map<String, dynamic>> previousSubmissions;

  const HomePage({super.key, required this.previousSubmissions});

  @override
  Widget build(BuildContext context) {
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
          ...previousSubmissions.map((submission) => Card(
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