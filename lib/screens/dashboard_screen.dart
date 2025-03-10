import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'car_storage.dart'; // Import the car storage file

class DashboardScreen extends StatefulWidget {
  final String? carMake;
  final String? carModel;
  final String? carYear;
  final String? carEngine;
  final String? carTransmission;
  final String? carPower;

  const DashboardScreen({
    super.key,
    this.carMake,
    this.carModel,
    this.carYear,
    this.carEngine,
    this.carTransmission,
    this.carPower,
  });

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime? _lastOilChange;
  int? _lastOilChangeMileage;
  int? _oilChangeInterval;
  int? _currentMileage;
  
  // Add car data properties
  String? _carMake;
  String? _carModel;
  String? _carYear;
  String? _carEngine;
  String? _carTransmission;
  String? _carPower;
  
  @override
  void initState() {
    super.initState();
    _loadSavedData();
    _loadCarData();
  }
  
  // Load car data from storage
  Future<void> _loadCarData() async {
    // First check if we have car data passed as parameters
    if (widget.carMake != null && widget.carModel != null) {
      setState(() {
        _carMake = widget.carMake;
        _carModel = widget.carModel;
        _carYear = widget.carYear;
        _carEngine = widget.carEngine;
        _carTransmission = widget.carTransmission;
        _carPower = widget.carPower;
      });
      
      // Save the car data that was passed in
      final car = Car(
        make: widget.carMake!,
        model: widget.carModel!,
        year: widget.carYear ?? '',
        engine: widget.carEngine ?? '',
        transmission: widget.carTransmission ?? '',
        power: widget.carPower ?? '',
      );
      await CarStorage.saveCar(car);
    } else {
      // If no car data was passed, try to load from storage
      final car = await CarStorage.loadCar();
      if (car != null) {
        setState(() {
          _carMake = car.make;
          _carModel = car.model;
          _carYear = car.year;
          _carEngine = car.engine;
          _carTransmission = car.transmission;
          _carPower = car.power;
        });
      }
    }
  }
  
  // Load data from SharedPreferences
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      // Load last oil change date
      final lastOilChangeMillis = prefs.getInt('lastOilChangeMillis');
      _lastOilChange = lastOilChangeMillis != null 
          ? DateTime.fromMillisecondsSinceEpoch(lastOilChangeMillis) 
          : null;
      
      // Load mileage data
      _lastOilChangeMileage = prefs.getInt('lastOilChangeMileage');
      _oilChangeInterval = prefs.getInt('oilChangeInterval');
      _currentMileage = prefs.getInt('currentMileage');
    });
  }
  
  // Save data to SharedPreferences
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save last oil change date
    if (_lastOilChange != null) {
      await prefs.setInt('lastOilChangeMillis', _lastOilChange!.millisecondsSinceEpoch);
    }
    
    // Save mileage data
    if (_lastOilChangeMileage != null) {
      await prefs.setInt('lastOilChangeMileage', _lastOilChangeMileage!);
    }
    
    if (_oilChangeInterval != null) {
      await prefs.setInt('oilChangeInterval', _oilChangeInterval!);
    }
    
    if (_currentMileage != null) {
      await prefs.setInt('currentMileage', _currentMileage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18181B),
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFF18181B),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCarInfoCard(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Maintenance Info',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            _buildMaintenanceInputs(),
            const SizedBox(height: 24),
            if (_lastOilChange != null &&
                _oilChangeInterval != null &&
                _currentMileage != null)
              _buildMaintenanceStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildCarInfoCard() {
    // Use the stored car data instead of widget parameters
    final carMake = _carMake ?? widget.carMake;
    final carModel = _carModel ?? widget.carModel;
    final carYear = _carYear ?? widget.carYear;
    final carEngine = _carEngine ?? widget.carEngine;
    final carTransmission = _carTransmission ?? widget.carTransmission;
    final carPower = _carPower ?? widget.carPower;
    
    // If no car data is available, show a placeholder
    if (carMake == null || carModel == null) {
      return Container(
        margin: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFF3A3A3C),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No car information available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
            ),
          ),
        ),
      );
    }
    
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3A3A3C), Color(0xFF2C2C2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${carYear ?? ''} ${carMake ?? ''} ${carModel ?? ''}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Engine', carEngine),
            _buildInfoRow('Transmission', carTransmission),
            _buildInfoRow('Power', carPower),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value ?? 'Not specified',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceInputs() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      color: const Color(0xFF2C2C2E),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDatePicker(
              label: 'Last Oil Change',
              value: _lastOilChange,
              onChanged: (date) {
                setState(() => _lastOilChange = date);
                _saveData(); // Save when value changes
              },
            ),
            const SizedBox(height: 16),
            _buildNumberInput(
              label: 'Last Oil Change Mileage',
              value: _lastOilChangeMileage,
              onChanged: (value) {
                setState(() => _lastOilChangeMileage = value);
                _saveData(); // Save when value changes
              },
            ),
            const SizedBox(height: 16),
            _buildNumberInput(
              label: 'Oil Change Interval (miles)',
              value: _oilChangeInterval,
              onChanged: (value) {
                setState(() => _oilChangeInterval = value);
                _saveData(); // Save when value changes
              },
            ),
            const SizedBox(height: 16),
            _buildNumberInput(
              label: 'Current Mileage',
              value: _currentMileage,
              onChanged: (value) {
                setState(() => _currentMileage = value);
                _saveData(); // Save when value changes
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        TextButton(
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: Color(0xFFF97316),
                      onPrimary: Colors.white,
                      surface: Color(0xFF27272A),
                      onSurface: Colors.white,
                    ),
                    dialogBackgroundColor: const Color(0xFF18181B),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              onChanged(date);
            }
          },
          child: Text(
            value != null
                ? DateFormat('MMM d, yyyy').format(value)
                : 'Select Date',
            style: const TextStyle(color: Color(0xFFF97316)),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberInput({
    required String label,
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    // Create a controller with the initial value
    final controller = TextEditingController(text: value?.toString() ?? '');
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        SizedBox(
          width: 100,
          child: Focus(
            // Wrap TextField with Focus widget to help maintain focus
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFF97316)),
                ),
              ),
              // Use onSubmitted instead of onChanged to avoid losing focus while typing
              onSubmitted: (text) {
                final value = int.tryParse(text);
                onChanged(value);
              },
              // Add this to save when focus is lost
              onEditingComplete: () {
                final value = int.tryParse(controller.text);
                onChanged(value);
                FocusScope.of(context).nextFocus();
              },
              textInputAction: TextInputAction.next,
            ),
            onFocusChange: (hasFocus) {
              // Only update the value when the field loses focus
              if (!hasFocus) {
                final value = int.tryParse(controller.text);
                onChanged(value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceStatus() {
    if (_lastOilChange == null || _oilChangeInterval == null || _currentMileage == null) {
      return const SizedBox(); // Avoid showing incomplete info
    }

    // User inputs
    int lastOilChangeMileage = _lastOilChangeMileage ?? 0;
    int oilChangeInterval = _oilChangeInterval ?? 0;
    int currentMileage = _currentMileage ?? 0;

    // Next oil change mileage
    int nextOilChangeMileage = lastOilChangeMileage + oilChangeInterval;
    int milesUntilNextChange = nextOilChangeMileage - currentMileage;

    // Next oil change date (1 year after last oil change)
    DateTime nextOilChangeDate = _lastOilChange!.add(const Duration(days: 365));
    int daysUntilNextChange = nextOilChangeDate.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.all(16.0),
      color: const Color(0xFF2C2C2E),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Maintenance Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildStatusRow('Last Oil Change Mileage', '$lastOilChangeMileage miles'),
            _buildStatusRow('Next Oil Change Mileage', '$nextOilChangeMileage miles'),
            _buildStatusRow('Miles Until Next Change', '$milesUntilNextChange miles'),
            _buildStatusRow('Next Oil Change Date', DateFormat('MMM d, yyyy').format(nextOilChangeDate)),
            _buildStatusRow('Days Until Next Change', '$daysUntilNextChange days'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}