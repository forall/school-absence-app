import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_helper.dart';

class SummaryPage extends StatefulWidget {
  final List<DateTime> absences;

  SummaryPage({required this.absences});

  @override
  _SummaryPageState createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  final dbHelper = DatabaseHelper();
  List<DateTime> _allAbsences = [];
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final absences = await dbHelper.getAbsences();
    final count = await dbHelper.getAbsenceCount();
    setState(() {
      _allAbsences = absences;
      _totalCount = count;
    });
  }

  Map<String, List<DateTime>> _groupAbsencesByMonth() {
    Map<String, List<DateTime>> grouped = {};

    for (DateTime absence in _allAbsences) {
      String monthName = _getMonthName(absence.month);
      String displayKey = '\$monthName \${absence.year}';

      if (!grouped.containsKey(displayKey)) {
        grouped[displayKey] = [];
      }
      grouped[displayKey]!.add(absence);
    }

    // Sortuj daty w każdym miesiącu
    grouped.forEach((key, dates) {
      dates.sort((a, b) => b.compareTo(a)); // Od najnowszych
    });

    return grouped;
  }

  String _getMonthName(int month) {
    const months = [
      '', 'Styczeń', 'Luty', 'Marzec', 'Kwiecień', 'Maj', 'Czerwiec',
      'Lipiec', 'Sierpień', 'Wrzesień', 'Październik', 'Listopad', 'Grudzień'
    ];
    return months[month];
  }

  String _getDayName(int weekday) {
    const days = [
      '', 'Poniedziałek', 'Wtorek', 'Środa', 'Czwartek', 'Piątek', 'Sobota', 'Niedziela'
    ];
    return days[weekday];
  }

  Future<void> _deleteAbsence(DateTime date) async {
    final success = await dbHelper.deleteAbsence(date);
    if (success) {
      await _loadAllData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Usunięto nieobecność z \${DateFormat('dd.MM.yyyy').format(date)}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd podczas usuwania nieobecności'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedAbsences = _groupAbsencesByMonth();
    final now = DateTime.now();
    final currentMonthKey = '\${_getMonthName(now.month)} \${now.year}';
    final currentMonthCount = groupedAbsences[currentMonthKey]?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text("Podsumowanie nieobecności"),
      ),
      body: Column(
        children: [
          // Statystyki
          Container(
            width: double.infinity,
            margin: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            '\$_totalCount',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          Text(
                            'Łącznie',
                            style: TextStyle(color: Colors.blue.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            '\$currentMonthCount',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            'Ten miesiąc',
                            style: TextStyle(color: Colors.green.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista nieobecności
          Expanded(
            child: _allAbsences.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Brak nieobecności',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: groupedAbsences.keys.length,
                    itemBuilder: (context, index) {
                      String monthKey = groupedAbsences.keys.elementAt(index);
                      List<DateTime> monthAbsences = groupedAbsences[monthKey]!;

                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ExpansionTile(
                          title: Text(
                            monthKey,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Nieobecności: \${monthAbsences.length}'),
                          children: monthAbsences.map((date) {
                            return ListTile(
                              leading: Icon(Icons.event_busy, color: Colors.red),
                              title: Text(
                                DateFormat('dd.MM.yyyy').format(date),
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(_getDayName(date.weekday)),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _showDeleteDialog(date),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(DateTime date) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Usuń nieobecność'),
          content: Text('Czy na pewno chcesz usunąć nieobecność z dnia \${DateFormat('dd.MM.yyyy').format(date)}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Anuluj'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAbsence(date);
              },
              child: Text('Usuń', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}