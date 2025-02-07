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
  String? _selectedPower;

  List<String> _makes = [];
  List<String> _models = [];
  List<String> _years = [];
  List<String> _engines = ['2.0L I4', '2.5L I4', '3.0L V6', '3.5L V6', '5.0L V8'];
  List<String> _transmissions = ['6-Speed Manual','6-Speed Automatic', '8-Speed Automatic', 'CVT'];
  List<String> _powerOptions = ['150 hp', '200 hp', '250 hp', '300 hp', '350 hp'];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMakes();
  }

  Future<void> _loadMakes() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('https://vpic.nhtsa.dot.gov/api/vehicles/GetMakesForVehicleType/car?format=json'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _makes = List<String>.from(data['Results'].map((make) => make['MakeName']));
          _makes.sort();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load makes');
      }
    } catch (e) {
      print('Error loading makes: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load car makes. Please try again.');
    }
  }

  Future<void> _loadModels(String make) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('https://vpic.nhtsa.dot.gov/api/vehicles/GetModelsForMake/$make?format=json'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _models = List<String>.from(data['Results'].map((model) => model['Model_Name']));
          _models = _models.toSet().toList();
          _models.sort();
          _selectedModel = null;
          _selectedYear = null;
          _selectedEngine = null;
          _selectedTransmission = null;
          _selectedPower = null;
          _years = [];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load models');
      }
    } catch (e) {
      print('Error loading models: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load car models. Please try again.');
    }
  }

Future<void> _loadYears(String make, String model) async {
  setState(() {
    // Generate years from 1990 to current year
    final currentYear = DateTime.now().year;
    _years = List.generate(
      currentYear - 1990 + 1, 
      (index) => (currentYear - index).toString()
    );
    _years.sort((a, b) => int.parse(b).compareTo(int.parse(a)));
    _selectedYear = null;
    _isLoading = false;
  });
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
        _selectedTransmission != null &&
        _selectedPower != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MainScreen(
            carMake: _selectedMake!,
            carModel: _selectedModel!,
            carYear: _selectedYear!,
            carEngine: _selectedEngine!,
            carTransmission: _selectedTransmission!,
            carPower: _selectedPower!,
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
          : SingleChildScrollView(
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
                        _selectedModel = null;
                        _selectedYear = null;
                        _selectedEngine = null;
                        _selectedTransmission = null;
                        _selectedPower = null;
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
                              _selectedYear = null;
                              _selectedEngine = null;
                              _selectedTransmission = null;
                              _selectedPower = null;
                            });
                            if (value != null) _loadYears(_selectedMake!, value);
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
                              _selectedEngine = null;
                              _selectedTransmission = null;
                              _selectedPower = null;
                            });
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
                              _selectedTransmission = null;
                              _selectedPower = null;
                            });
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
                              _selectedPower = null;
                            });
                          },
                    decoration: const InputDecoration(labelText: 'Transmission'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedPower,
                    items: _powerOptions.map((power) => DropdownMenuItem(value: power, child: Text(power))).toList(),
                    onChanged: _selectedTransmission == null
                        ? null
                        : (value) {
                            setState(() {
                              _selectedPower = value;
                            });
                          },
                    decoration: const InputDecoration(labelText: 'Power'),
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
  final String carPower;

  const MainScreen({
    super.key,
    required this.carMake,
    required this.carModel,
    required this.carYear,
    required this.carEngine,
    required this.carTransmission,
    required this.carPower,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            DashboardScreen(
              carMake: widget.carMake,
              carModel: widget.carModel,
              carYear: widget.carYear,
              carEngine: widget.carEngine,
              carTransmission: widget.carTransmission,
              carPower: widget.carPower,
            ),
            const Center(child: Text('Diagnostics Screen')),
            const Center(child: Text('Navigation Screen')),
            const Center(child: Text('Settings Screen')),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF18181B),
        selectedItemColor: const Color(0xFFF97316),
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
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
  final String carPower;

  const DashboardScreen({
    super.key,
    required this.carMake,
    required this.carModel,
    required this.carYear,
    required this.carEngine,
    required this.carTransmission,
    required this.carPower,
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
                    '$carEngine, $carTransmission, $carPower',
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
          // Main content
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildCarImage(),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  _buildStatusCards(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarImage() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        image: const DecorationImage(
          image: NetworkImage('https://placeholder.com/400x240'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
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
          Icon(icon, color: const Color(0xFFF97316)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStatusCards() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatusCard(
            'Engine Status',
            Icons.speed,
            progress: 72,
          ),
          const SizedBox(height: 16),
          _buildStatusCard(
            'Location',
            Icons.location_on,
            subtitle: '123 Main Street, Boston, MA',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, IconData icon, {double? progress, String? subtitle}) {
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
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress / 100,
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