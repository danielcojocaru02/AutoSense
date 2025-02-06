import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'AutoSense',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF09090B),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF97316),
          secondary: Color(0xFFF97316),
        ),
      ),
      home: const AddCarScreen(),
    );
  }
}

class AddCarScreen extends StatefulWidget {
  const AddCarScreen({super.key});

  @override
  State<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  String? _selectedMake;
  String? _selectedModel;
  String? _selectedYear;
  String? _selectedEngine;
  String? _selectedTransmission;

  List<String> _makes = [];
  List<String> _models = [];
  List<String> _years = [];
  List<String> _engines = [];
  List<String> _transmissions = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMakes();
  }

  Future<void> _loadMakes() async {
    setState(() => _isLoading = true);
    try {
      // In a real app, you'd fetch this data from an API
      // For this example, we'll use a simulated API call
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _makes = ['Toyota', 'Honda', 'Ford', 'BMW', 'Mercedes'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load car makes. Please try again.');
    }
  }

  Future<void> _loadModels(String make) async {
    setState(() => _isLoading = true);
    try {
      // Simulated API call
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _models = ['Model 1', 'Model 2', 'Model 3'];
        _selectedModel = null;
        _selectedYear = null;
        _selectedEngine = null;
        _selectedTransmission = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load car models. Please try again.');
    }
  }

  Future<void> _loadYears(String model) async {
    setState(() => _isLoading = true);
    try {
      // Simulated API call
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _years = ['2020', '2021', '2022', '2023'];
        _selectedYear = null;
        _selectedEngine = null;
        _selectedTransmission = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load car years. Please try again.');
    }
  }

  Future<void> _loadEngines(String year) async {
    setState(() => _isLoading = true);
    try {
      // Simulated API call
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _engines = ['1.5L 4-cylinder', '2.0L 4-cylinder', '3.0L V6'];
        _selectedEngine = null;
        _selectedTransmission = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load engine options. Please try again.');
    }
  }

  Future<void> _loadTransmissions(String engine) async {
    setState(() => _isLoading = true);
    try {
      // Simulated API call
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _transmissions = ['6-speed Manual', '8-speed Automatic', 'CVT'];
        _selectedTransmission = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load transmission options. Please try again.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _submitForm() {
    if (_selectedMake != null &&
        _selectedModel != null &&
        _selectedYear != null &&
        _selectedEngine != null &&
        _selectedTransmission != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MainScreen(
            carMake: _selectedMake!,
            carModel: _selectedModel!,
            carYear: _selectedYear!,
            carEngine: _selectedEngine!,
            carTransmission: _selectedTransmission!,
          ),
        ),
      );
    } else {
      _showErrorSnackBar('Please complete all selections');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Your Car'),
        backgroundColor: const Color(0xFF18181B),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedMake,
                    items: _makes.map((make) => DropdownMenuItem(value: make, child: Text(make))).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMake = value;
                      });
                      if (value != null) _loadModels(value);
                    },
                    decoration: const InputDecoration(labelText: 'Car Make'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedModel,
                    items: _models.map((model) => DropdownMenuItem(value: model, child: Text(model))).toList(),
                    onChanged: _selectedMake == null
                        ? null
                        : (value) {
                            setState(() {
                              _selectedModel = value;
                            });
                            if (value != null) _loadYears(value);
                          },
                    decoration: const InputDecoration(labelText: 'Car Model'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedYear,
                    items: _years.map((year) => DropdownMenuItem(value: year, child: Text(year))).toList(),
                    onChanged: _selectedModel == null
                        ? null
                        : (value) {
                            setState(() {
                              _selectedYear = value;
                            });
                            if (value != null) _loadEngines(value);
                          },
                    decoration: const InputDecoration(labelText: 'Car Year'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedEngine,
                    items: _engines.map((engine) => DropdownMenuItem(value: engine, child: Text(engine))).toList(),
                    onChanged: _selectedYear == null
                        ? null
                        : (value) {
                            setState(() {
                              _selectedEngine = value;
                            });
                            if (value != null) _loadTransmissions(value);
                          },
                    decoration: const InputDecoration(labelText: 'Engine'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedTransmission,
                    items: _transmissions.map((transmission) => DropdownMenuItem(value: transmission, child: Text(transmission))).toList(),
                    onChanged: _selectedEngine == null
                        ? null
                        : (value) {
                            setState(() {
                              _selectedTransmission = value;
                            });
                          },
                    decoration: const InputDecoration(labelText: 'Transmission'),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text('Add Car'),
                  ),
                ],
              ),
            ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final String carMake;
  final String carModel;
  final String carYear;
  final String carEngine;
  final String carTransmission;

  const MainScreen({
    super.key,
    required this.carMake,
    required this.carModel,
    required this.carYear,
    required this.carEngine,
    required this.carTransmission,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      DashboardScreen(
        carMake: widget.carMake,
        carModel: widget.carModel,
        carYear: widget.carYear,
        carEngine: widget.carEngine,
        carTransmission: widget.carTransmission,
      ),
      const DiagnosticsScreen(),
      const NavigationScreen(),
      const SettingsScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF18181B),
        selectedItemColor: const Color(0xFFF97316),
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.speed), label: 'Diagnostics'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Navigation'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final String carMake;
  final String carModel;
  final String carYear;
  final String carEngine;
  final String carTransmission;

  const DashboardScreen({
    super.key,
    required this.carMake,
    required this.carModel,
    required this.carYear,
    required this.carEngine,
    required this.carTransmission,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$carMake $carModel $carYear',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$carEngine, $carTransmission',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Icon(Icons.notifications_outlined, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 24),

          // Main Card
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Car Image Section
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      image: DecorationImage(
                        image: NetworkImage('https://placeholder.com/400x240'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick Actions Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildQuickActionButton(Icons.directions_car, 'Status'),
                        _buildQuickActionButton(Icons.thermostat, 'Climate'),
                        _buildQuickActionButton(Icons.power_settings_new, 'Power'),
                        _buildQuickActionButton(Icons.settings, 'Settings'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Status Cards
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildStatusCard(
                          'Engine Status',
                          Icons.speed,
                          72,
                          showProgress: true,
                        ),
                        const SizedBox(height: 16),
                        _buildStatusCard(
                          'Location',
                          Icons.location_on,
                          null,
                          subtitle: '123 Main Street, Boston, MA',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(IconData icon, String label) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF27272A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color(0xFFF97316),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, IconData icon, double? progress, {String? subtitle, bool showProgress = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF27272A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFFF97316)),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
          if (showProgress) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress! / 100,
              backgroundColor: Colors.grey[800],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF97316)),
            ),
          ],
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}

class DiagnosticsScreen extends StatelessWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Diagnostics Screen'),
    );
  }
}

class NavigationScreen extends StatelessWidget {
  const NavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Navigation Screen'),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Settings Screen'),
    );
  }
}