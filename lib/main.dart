import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'db_helper.dart';
import 'summary_page.dart';
import 'settings_page.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(SchoolAbsenceApp());
}

class SchoolAbsenceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nieobecności Szkoła',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: AbsenceHomePage(),
    );
  }
}

class AbsenceHomePage extends StatefulWidget {
  @override
  _AbsenceHomePageState createState() => _AbsenceHomePageState();
}

class _AbsenceHomePageState extends State<AbsenceHomePage> {
  final dbHelper = DatabaseHelper();
  String childName = "Jan Kowalski";
  String schoolEmail = "szkola@example.com";
  List<DateTime> _recentAbsences = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadRecentAbsences();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      childName = prefs.getString('childName') ?? 'Jan Kowalski';
      schoolEmail = prefs.getString('schoolEmail') ?? 'szkola@example.com';
    });
  }

  Future<void> _loadRecentAbsences() async {
    final absences = await dbHelper.getAbsences();
    setState(() {
      _recentAbsences = absences.take(5).toList();
    });
  }

  Future<void> _quickAbsence(DateTime date) async {
    // Sprawdź czy już nie ma tej nieobecności
    final existingAbsences = await dbHelper.getAbsences();
    if (existingAbsences.any((d) => isSameDay(d, date))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ten dzień już jest oznaczony jako nieobecność'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Dodaj do bazy
    await dbHelper.insertAbsence(date);
    await _loadRecentAbsences();

    // Wyślij email
    _sendQuickEmail(date);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Zgłoszono nieobecność na \${DateFormat('dd.MM.yyyy').format(date)}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _sendQuickEmail(DateTime date) async {
    final String formattedDate = DateFormat('dd.MM.yyyy').format(date);
    final String dayName = _getDayName(date.weekday);

    final String subject = Uri.encodeComponent('Nieobecność - obiady');
    final String body = Uri.encodeComponent(
      'Dzień dobry,\n\nInformuję, że \$childName nie będzie obecny w szkole w dniu \$formattedDate (\$dayName).\n\nPozdrawiam'
    );

    final Uri emailUri = Uri.parse('mailto:\$schoolEmail?subject=\$subject&body=\$body');

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nie można otworzyć klienta poczty')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd: \$e')),
      );
    }
  }

  String _getDayName(int weekday) {
    const days = ['', 'poniedziałek', 'wtorek', 'środa', 'czwartek', 'piątek', 'sobota', 'niedziela'];
    return days[weekday];
  }

  void _openCalendar() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CalendarPage()),
    );
  }

  void _openSummary() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SummaryPage(absences: _recentAbsences)),
    );
  }

  void _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsPage()),
    );
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final tomorrow = now.add(Duration(days: 1));
    final dayAfterTomorrow = now.add(Duration(days: 2));

    return Scaffold(
      appBar: AppBar(
        title: Text('Nieobecności - Obiady'),
        actions: [
          IconButton(
            icon: Icon(Icons.assessment),
            onPressed: _openSummary,
            tooltip: 'Podsumowanie',
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: 'Ustawienia',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Informacje o dziecku
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.person, size: 48, color: Colors.blue),
                    SizedBox(height: 8),
                    Text(
                      childName,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Szkoła: \$schoolEmail',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Szybkie zgłaszanie
            Text(
              'Szybkie zgłaszanie nieobecności',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            // Dziś
            ElevatedButton.icon(
              onPressed: () => _quickAbsence(now),
              icon: Icon(Icons.today),
              label: Text('DZIŚ - \${DateFormat('dd.MM.yyyy').format(now)}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: Size(double.infinity, 56),
              ),
            ),

            SizedBox(height: 12),

            // Jutro
            ElevatedButton.icon(
              onPressed: () => _quickAbsence(tomorrow),
              icon: Icon(Icons.arrow_forward),
              label: Text('JUTRO - \${DateFormat('dd.MM.yyyy').format(tomorrow)}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: Size(double.infinity, 56),
              ),
            ),

            SizedBox(height: 12),

            // Pojutrze
            ElevatedButton.icon(
              onPressed: () => _quickAbsence(dayAfterTomorrow),
              icon: Icon(Icons.fast_forward),
              label: Text('POJUTRZE - \${DateFormat('dd.MM.yyyy').format(dayAfterTomorrow)}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: Size(double.infinity, 56),
              ),
            ),

            SizedBox(height: 24),

            // Kalendarz
            OutlinedButton.icon(
              onPressed: _openCalendar,
              icon: Icon(Icons.calendar_month),
              label: Text('OTWÓRZ KALENDARZ'),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
            ),

            SizedBox(height: 24),

            // Ostatnie nieobecności
            if (_recentAbsences.isNotEmpty) ...[
              Text(
                'Ostatnie nieobecności',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Card(
                child: Column(
                  children: _recentAbsences.take(3).map((date) {
                    return ListTile(
                      leading: Icon(Icons.event_busy, color: Colors.red),
                      title: Text(DateFormat('dd.MM.yyyy').format(date)),
                      subtitle: Text(_getDayName(date.weekday)),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<DateTime> _absences = [];
  final dbHelper = DatabaseHelper();
  String childName = "Jan Kowalski";
  String schoolEmail = "szkola@example.com";

  @override
  void initState() {
    super.initState();
    _loadAbsences();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      childName = prefs.getString('childName') ?? 'Jan Kowalski';
      schoolEmail = prefs.getString('schoolEmail') ?? 'szkola@example.com';
    });
  }

  Future<void> _loadAbsences() async {
    final absences = await dbHelper.getAbsences();
    setState(() {
      _absences = absences;
    });
  }

  void _markAbsence(DateTime day) async {
    if (_absences.any((d) => isSameDay(d, day))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ten dzień już jest oznaczony jako nieobecność')),
      );
      return;
    }

    await dbHelper.insertAbsence(day);
    await _loadAbsences();
    _sendEmail(day);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Dodano nieobecność na \${DateFormat('dd.MM.yyyy').format(day)}')),
    );
  }

  void _sendEmail(DateTime date) async {
    final String formattedDate = DateFormat('dd.MM.yyyy').format(date);
    final String dayName = _getDayName(date.weekday);

    final String subject = Uri.encodeComponent('Nieobecność - obiady');
    final String body = Uri.encodeComponent(
      'Dzień dobry,\n\nInformuję, że \$childName nie będzie obecny w szkole w dniu \$formattedDate (\$dayName).\n\nPozdrawiam'
    );

    final Uri emailUri = Uri.parse('mailto:\$schoolEmail?subject=\$subject&body=\$body');

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  String _getDayName(int weekday) {
    const days = ['', 'poniedziałek', 'wtorek', 'środa', 'czwartek', 'piątek', 'sobota', 'niedziela'];
    return days[weekday];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kalendarz nieobecności'),
      ),
      body: Column(
        children: [
          TableCalendar<DateTime>(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) =>
                _selectedDay != null && isSameDay(_selectedDay, day),
            eventLoader: (day) {
              return _absences.where((absence) => isSameDay(absence, day)).toList();
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _markAbsence(selectedDay);
            },
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) => setState(() {
              _calendarFormat = format;
            }),
            onPageChanged: (focusedDay) => setState(() {
              _focusedDay = focusedDay;
            }),
            calendarStyle: CalendarStyle(
              markersMaxCount: 1,
              markerDecoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Kliknij datę, aby zgłosić nieobecność\nCzerwone kropki = dni nieobecności",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}