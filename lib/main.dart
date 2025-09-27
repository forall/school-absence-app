import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'database_helper.dart';
import 'summary_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Absence App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _childNameController = TextEditingController();
  final TextEditingController _schoolEmailController = TextEditingController();
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  List<DateTime> _absenceDates = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAbsences();
  }

  Future<void> _loadSettings() async {
    final settings = await DatabaseHelper.instance.getSettings();
    if (settings.isNotEmpty) {
      setState(() {
        _childNameController.text = settings['child_name'] ?? '';
        _schoolEmailController.text = settings['school_email'] ?? '';
      });
    }
  }

  Future<void> _loadAbsences() async {
    final absences = await DatabaseHelper.instance.getAbsences();
    setState(() {
      _absenceDates = absences.map((absence) => DateTime.parse(absence['date'] as String)).toList();
    });
  }

  Future<void> _saveSettings() async {
    await DatabaseHelper.instance.saveSettings(
      _childNameController.text,
      _schoolEmailController.text,
    );
  }

  Future<void> _reportAbsence(DateTime date) async {
    if (_childNameController.text.isEmpty || _schoolEmailController.text.isEmpty) {
      _showSettingsDialog();
      return;
    }

    await DatabaseHelper.instance.addAbsence(date);
    await _loadAbsences();

    final formatter = DateFormat('dd/MM/yyyy');
    final dayFormatter = DateFormat('EEEE');
    final formattedDate = formatter.format(date);
    final dayName = dayFormatter.format(date);

    final subject = 'Absence Notification - \${_childNameController.text}';
    final body = 'Dear School,\n\nI am writing to inform you that my child, \${_childNameController.text}, will be absent from school on \$dayName, \$formattedDate.\n\nThank you for your understanding.\n\nBest regards';

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: _schoolEmailController.text,
      query: 'subject=\${Uri.encodeComponent(subject)}&body=\${Uri.encodeComponent(body)}',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app')),
        );
      }
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _childNameController,
                decoration: const InputDecoration(
                  labelText: 'Child Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _schoolEmailController,
                decoration: const InputDecoration(
                  labelText: 'School Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _saveSettings();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('School Absence App'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.summarize),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SummaryPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Report Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _reportAbsence(DateTime.now()),
              icon: const Icon(Icons.email),
              label: const Text('Report Today's Absence'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const Divider(),
          // Calendar
          Expanded(
            child: TableCalendar<DateTime>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: (day) {
                return _absenceDates.where((date) => isSameDay(date, day)).toList();
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
                markersMaxCount: 1,
                markerDecoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
          ),
          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _reportAbsence(_selectedDay),
                    child: Text('Report Absence for \${DateFormat('dd/MM').format(_selectedDay)}'),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    await DatabaseHelper.instance.removeAbsence(_selectedDay);
                    await _loadAbsences();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Remove'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _childNameController.dispose();
    _schoolEmailController.dispose();
    super.dispose();
  }
}
