import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'sensor_preferences.dart';
import 'obd_protocol.dart';

class OBDService {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _obdCharacteristic;
  bool _isConnected = false;
  final _dataStreamController = StreamController<Map<String, String>>.broadcast();
  
  Stream<Map<String, String>> get dataStream => _dataStreamController.stream;

  // Connect to the selected device using Flutter Blue Plus
  Future<bool> connect(BluetoothDevice device) async {
    try {
      _device = device;

      // Check if already connected
      if (device.connectionState == BluetoothConnectionState.connected) {
        print('Already connected to device');
      } else {
        // Connect to the device
        await device.connect(autoConnect: false);
      }

      // Discover services and characteristics
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        // Look for a characteristic that looks like an OBD service
        // This will depend on your specific OBD adapter
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.properties.write && characteristic.properties.read) {
            _obdCharacteristic = characteristic;
            break;
          }
        }
        if (_obdCharacteristic != null) break;
      }

      if (_obdCharacteristic == null) {
        print('OBD-II characteristic not found');
        return false;
      }

      _isConnected = true;
      _startReading();
      return true;
    } catch (e) {
      print('Failed to connect: $e');
      return false;
    }
  }

  // Disconnect from the device
  void disconnect() {
    if (_device != null && _isConnected) {
      _device?.disconnect();
      _isConnected = false;
    }
    if (!_dataStreamController.isClosed) {
      _dataStreamController.close();
    }
  }

  // Start reading data from the OBD-II device
  void _startReading() async {
    if (!_dataStreamController.isClosed) {
      while (_isConnected) {
        try {
          final selectedSensors = await SensorPreferences.getSelectedSensors();
          final data = <String, String>{};

          for (final sensor in selectedSensors) {
            final command = OBDProtocol.commands[sensor];
            if (command != null) {
              final result = await _runCommand(command.command);
              final value = command.calculator(OBDProtocol.parseOBDResponse(result));
              data[SensorPreferences.allSensors[sensor]!] = value.toString();
            }
          }

          if (!_dataStreamController.isClosed) {
            _dataStreamController.add(data);
          }
        } catch (e) {
          print('Error reading OBD data: $e');
        }
        await Future.delayed(Duration(seconds: 1));
      }
    }
  }

  // Run a command over Bluetooth
  Future<String> _runCommand(String command) async {
    if (_obdCharacteristic == null) {
      return 'No OBD characteristic found';
    }

    try {
      // Send the command to the OBD-II device
      await _obdCharacteristic!.write(Uint8List.fromList(command.codeUnits));

      // Read the response
      List<int> response = await _obdCharacteristic!.read();
      return String.fromCharCodes(response);
    } catch (e) {
      print('Error running OBD command: $e');
      return 'Error';
    }
  }
}