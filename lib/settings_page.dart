import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _childNameController = TextEditingController();
  final _schoolEmailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _childNameController.text = prefs.getString('childName') ?? 'Jan Kowalski';
      _schoolEmailController.text = prefs.getString('schoolEmail') ?? 'szkola@example.com';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('childName', _childNameController.text.trim());
    await prefs.setString('schoolEmail', _schoolEmailController.text.trim());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ustawienia zostały zapisane'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pop();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Podaj adres email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}\$').hasMatch(value)) {
      return 'Podaj prawidłowy adres email';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Podaj imię i nazwisko dziecka';
    }
    if (value.trim().length < 3) {
      return 'Imię i nazwisko musi mieć co najmniej 3 znaki';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Ustawienia")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Ustawienia"),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Zapisz ustawienia',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dane dziecka',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _childNameController,
                        decoration: InputDecoration(
                          labelText: "Imię i nazwisko dziecka",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                          hintText: "np. Jan Kowalski",
                        ),
                        validator: _validateName,
                        textCapitalization: TextCapitalization.words,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dane szkoły',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _schoolEmailController,
                        decoration: InputDecoration(
                          labelText: "Adres email szkoły",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                          hintText: "np. szkola@example.com",
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: Icon(Icons.save),
                  label: Text('ZAPISZ USTAWIENIA'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                  ),
                ),
              ),

              SizedBox(height: 16),

              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Informacje',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Aplikacja automatycznie otworzy klienta poczty z gotową wiadomością\n'
                        '• Wystarczy kliknąć "Wyślij" w aplikacji pocztowej\n'
                        '• Wszystkie nieobecności są zapisywane lokalnie na telefonie',
                        style: TextStyle(fontSize: 14, color: Colors.blue.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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