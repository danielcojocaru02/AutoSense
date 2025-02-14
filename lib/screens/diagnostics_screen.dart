import 'package:flutter/material.dart';
import 'dart:async';
import '../services/obd_service.dart';
import '../services/sensor_preferences.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({Key? key}) : super(key: key);

  @override
  _DiagnosticsScreenState createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  bool _isConnected = false;
  String _connectionStatus = 'Disconnected';
  Map<String, String> _diagnosticData = {};
  List<String> _selectedSensors = [];
  final OBDService _obdService = OBDService();

  @override
  void initState() {
    super.initState();
    _loadSelectedSensors();
  }

  Future<void> _loadSelectedSensors() async {
    final sensors = await SensorPreferences.getSelectedSensors();
    setState(() {
      _selectedSensors = List<String>.from(sensors);
    });
  }

  Future<void> _connectToOBD() async {
    // TODO: Implement actual OBD-II Bluetooth connection logic
    // For example: bool success = await _obdService.connect('00:00:00:00:00:00');
    bool success = true; // Placeholder for actual connection
    setState(() {
      _isConnected = success;
      _connectionStatus = success ? 'Connected' : 'Connection failed';
    });
    if (success) {
      _startListeningToOBDData();
    }
  }

  void _startListeningToOBDData() {
    _obdService.dataStream.listen((data) {
      setState(() {
        _diagnosticData = data;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18181B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Diagnostics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildConnectionStatus(),
              const SizedBox(height: 20),
              _buildConnectButton(),
              const SizedBox(height: 20),
              _buildSensorSelectionButton(),
              const SizedBox(height: 20),
              Expanded(child: _buildDiagnosticInfo()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF27272A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
            color: _isConnected ? const Color(0xFFF97316) : Colors.grey,
          ),
          const SizedBox(width: 16),
          Text(
            _connectionStatus,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectButton() {
    return ElevatedButton(
      onPressed: _isConnected ? null : _connectToOBD,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF97316),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Center(
        child: Text(
          _isConnected ? 'Connected' : 'Connect to OBD-II',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSensorSelectionButton() {
    return ElevatedButton(
      onPressed: _showSensorSelectionDialog,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF27272A),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Center(
        child: Text(
          'Select Sensors',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDiagnosticInfo() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _diagnosticData.length,
      itemBuilder: (context, index) {
        String key = _diagnosticData.keys.elementAt(index);
        String value = _diagnosticData[key] ?? '';
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF27272A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                key,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

 void _showSensorSelectionDialog() {
  List<String> tempSelectedSensors = List<String>.from(_selectedSensors);

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Select Sensors'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          tempSelectedSensors = SensorPreferences.allSensors.keys.toList();
                        });
                      },
                      child: Text('Select All'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          tempSelectedSensors.clear();
                        });
                      },
                      child: Text('Deselect All'),
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: SensorPreferences.allSensors.entries.map((entry) {
                        return CheckboxListTile(
                          title: Text(entry.value),
                          value: tempSelectedSensors.contains(entry.key),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                tempSelectedSensors.add(entry.key);
                              } else {
                                tempSelectedSensors.remove(entry.key);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Save'),
            onPressed: () {
              setState(() {
                _selectedSensors = tempSelectedSensors;
              });
              SensorPreferences.setSelectedSensors(_selectedSensors);
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
}

