import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'sensor_preferences.dart';
import 'obd_adapter.dart';
import 'obd_protocol.dart';

class OBDService {
  OBDAdapter? _adapter;
  final _dataStreamController = StreamController<Map<String, String>>.broadcast();
  Timer? _refreshTimer;
  bool _isInitializing = false;
  
  Stream<Map<String, String>> get dataStream => _dataStreamController.stream;

  Future<bool> connect(BluetoothDevice device) async {
    _adapter = OBDAdapter(device);
    bool connected = await _adapter!.connect();
    
    if (connected) {
      // Send a dummy message to indicate we're initializing
      Map<String, String> initMessage = {
        'Status': 'Initializing OBD adapter...'
      };
      _dataStreamController.add(initMessage);
      
      // Set initializing flag
      _isInitializing = true;
      
      // Wait a bit for the adapter to initialize fully
      await Future.delayed(const Duration(seconds: 3));
      
      // Start refreshing data
      _startRefreshingData();
    }
    
    return connected;
  }

  void _startRefreshingData() {
    // Cancel any existing timer
    _refreshTimer?.cancel();
    
    // Start a new timer
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_adapter == null || !_adapter!.isConnected) {
        timer.cancel();
        return;
      }
      
      await _refreshSensorData();
    });
  }

  Future<void> _refreshSensorData() async {
    try {
      final selectedSensors = await SensorPreferences.getSelectedSensors();
      Map<String, String> newValues = {};
      
      // If we're still initializing, show a message
      if (_isInitializing) {
        newValues['Status'] = 'Initializing OBD adapter...';
        _isInitializing = false; // Clear the flag after first refresh
      }
      
      // Try to get a simple sensor value first to test communication
      if (selectedSensors.isNotEmpty) {
        String testSensor = selectedSensors.first;
        dynamic testValue = await _adapter!.getSensorValue(testSensor);
        
        // If we got a valid response, proceed with all sensors
        if (testValue != 'N/A' && testValue != 'Error' && testValue != 'Timeout') {
          for (String sensorKey in selectedSensors) {
            if (OBDProtocol.commands.containsKey(sensorKey)) {
              dynamic value = await _adapter!.getSensorValue(sensorKey);
              
              // Format the value for display
              String displayValue;
              if (value is num) {
                displayValue = value.toStringAsFixed(1);
                
                // Add units based on sensor type
                if (sensorKey == 'ENGINE_RPM') {
                  displayValue += ' RPM';
                } else if (sensorKey == 'VEHICLE_SPEED') {
                  displayValue += ' km/h';
                } else if (sensorKey == 'COOLANT_TEMP' || sensorKey == 'AMBIENT_TEMP' || sensorKey == 'OIL_TEMP' || sensorKey == 'CATALYST_TEMP') {
                  displayValue += ' °C';
                } else if (sensorKey == 'INTAKE_PRESSURE' || sensorKey == 'BAROMETRIC_PRESSURE' || sensorKey == 'FUEL_PRESSURE') {
                  displayValue += ' kPa';
                } else if (sensorKey == 'FUEL_LEVEL' || sensorKey == 'THROTTLE_POS' || sensorKey == 'ENGINE_LOAD' || sensorKey == 'ABSOLUTE_LOAD' || sensorKey == 'ETHANOL_FUEL') {
                  displayValue += ' %';
                } else if (sensorKey == 'TIMING_ADVANCE') {
                  displayValue += ' °';
                } else if (sensorKey == 'FUEL_RATE') {
                  displayValue += ' L/h';
                } else if (sensorKey == 'CONTROL_MODULE_VOLTAGE') {
                  displayValue += ' V';
                } else if (sensorKey == 'MAF_SENSOR') {
                  displayValue += ' g/s';
                } else if (sensorKey == 'O2_VOLTAGE') {
                  displayValue += ' V';
                }
              } else {
                displayValue = value.toString();
              }
              
              // Use the display name from SensorPreferences
              String displayName = SensorPreferences.allSensors[sensorKey] ?? sensorKey;
              newValues[displayName] = displayValue;
            }
          }
        } else {
          // If test sensor failed, show a message
          newValues['Status'] = 'Waiting for vehicle data...';
        }
      }
      
      if (!_dataStreamController.isClosed) {
        _dataStreamController.add(newValues);
      }
    } catch (e) {
      print('Error refreshing sensor data: $e');
      
      // Send an error message
      if (!_dataStreamController.isClosed) {
        _dataStreamController.add({'Error': 'Failed to read sensor data: $e'});
      }
    }
  }

  void disconnect() {
    _refreshTimer?.cancel();
    _adapter?.disconnect();
    if (!_dataStreamController.isClosed) {
      _dataStreamController.close();
    }
  }

  bool get isConnected => _adapter?.isConnected ?? false;
  bool get isStandardOBD => _adapter?.isStandardOBD ?? false;
}

