import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main_screen.dart';


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