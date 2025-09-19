import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class NewReport extends StatefulWidget {
  final Map<String, double> dummyIoTData;
  
  const NewReport({super.key, required this.dummyIoTData});

  @override
  State<NewReport> createState() => _NewReportState();
}

class _NewReportState extends State<NewReport> {
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

  @override
  Widget build(BuildContext context) {
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
                        Text('${widget.dummyIoTData['turbidity']} NTU'),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _turbidity = widget.dummyIoTData['turbidity']!;
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
                        Text('${widget.dummyIoTData['phLevel']}'),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _phLevel = widget.dummyIoTData['phLevel']!;
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
                        Text('${widget.dummyIoTData['tdsLevel']} ppm'),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _tdsLevel = widget.dummyIoTData['tdsLevel']!;
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