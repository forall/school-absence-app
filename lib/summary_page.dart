import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'database_helper.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  List<Map<String, dynamic>> _monthlyAbsences = [];
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _loadMonthlyAbsences();
  }

  Future<void> _loadMonthlyAbsences() async {
    final absences = await DatabaseHelper.instance.getAbsencesForMonth(_selectedYear, _selectedMonth);
    setState(() {
      _monthlyAbsences = absences;
    });
  }

  Future<void> _sendMonthlySummary() async {
    final settings = await DatabaseHelper.instance.getSettings();
    if (settings.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please set up child name and school email first')),
        );
      }
      return;
    }

    final childName = settings['child_name'] as String;
    final schoolEmail = settings['school_email'] as String;
    final monthName = DateFormat('MMMM yyyy').format(DateTime(_selectedYear, _selectedMonth));

    String body = 'Dear School,\n\nHere is the monthly absence summary for \$childName in \$monthName:\n\n';

    if (_monthlyAbsences.isEmpty) {
      body += 'No absences recorded for this month.\n';
    } else {
      body += 'Absence dates:\n';
      for (var absence in _monthlyAbsences) {
        final date = DateTime.parse(absence['date'] as String);
        final formattedDate = DateFormat('EEEE, dd/MM/yyyy').format(date);
        body += '• \$formattedDate\n';
      }
      body += '\nTotal absences: \${_monthlyAbsences.length}\n';
    }

    body += '\nBest regards';

    final subject = 'Monthly Absence Summary - \$childName - \$monthName';

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: schoolEmail,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Summary'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.email),
            onPressed: _sendMonthlySummary,
          ),
        ],
      ),
      body: Column(
        children: [
          // Month/Year Selector
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<int>(
                    value: _selectedMonth,
                    isExpanded: true,
                    items: List.generate(12, (index) {
                      final month = index + 1;
                      return DropdownMenuItem(
                        value: month,
                        child: Text(DateFormat('MMMM').format(DateTime(2023, month))),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedMonth = value;
                        });
                        _loadMonthlyAbsences();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    isExpanded: true,
                    items: List.generate(5, (index) {
                      final year = DateTime.now().year - 2 + index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedYear = value;
                        });
                        _loadMonthlyAbsences();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Summary Stats
          Container(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Absences in \${DateFormat('MMMM yyyy').format(DateTime(_selectedYear, _selectedMonth))}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\${_monthlyAbsences.length}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: _monthlyAbsences.isEmpty ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _monthlyAbsences.length == 1 ? 'day' : 'days',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Absence List
          Expanded(
            child: _monthlyAbsences.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 64, color: Colors.green),
                        SizedBox(height: 16),
                        Text('No absences this month!', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _monthlyAbsences.length,
                    itemBuilder: (context, index) {
                      final absence = _monthlyAbsences[index];
                      final date = DateTime.parse(absence['date'] as String);
                      final formattedDate = DateFormat('EEEE, dd/MM/yyyy').format(date);

                      return ListTile(
                        leading: const Icon(Icons.event_busy, color: Colors.red),
                        title: Text(formattedDate),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await DatabaseHelper.instance.removeAbsence(date);
                            _loadMonthlyAbsences();
                          },
                        ),
                      );
                    },
                  ),
          ),
          // Send Summary Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _sendMonthlySummary,
              icon: const Icon(Icons.email),
              label: const Text('Send Monthly Summary'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
