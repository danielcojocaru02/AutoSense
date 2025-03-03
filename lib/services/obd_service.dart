import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'sensor_preferences.dart';
import 'obd_protocol.dart';

class OBDService {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _readCharacteristic;
  bool _isConnected = false;
  final _dataStreamController = StreamController<Map<String, String>>.broadcast();
  
  Stream<Map<String, String>> get dataStream => _dataStreamController.stream;

  Future<bool> connect(BluetoothDevice device) async {
    try {
      _device = device;
      await device.connect(autoConnect: false);
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            _writeCharacteristic = characteristic;
          }
          if (characteristic.properties.read || characteristic.properties.notify) {
            _readCharacteristic = characteristic;
          }
          if (_writeCharacteristic != null && _readCharacteristic != null) {
            break;
          }
        }
        if (_writeCharacteristic != null && _readCharacteristic != null) break;
      }

      if (_writeCharacteristic == null || _readCharacteristic == null) {
        print('MM32I073 characteristics not found');
        return false;
      }

      _isConnected = true;
      await _initializeDevice();
      _startReading();
      return true;
    } catch (e) {
      print('Failed to connect: $e');
      return false;
    }
  }

  Future<void> _initializeDevice() async {
    print('Initializing MM32I073 device...');
    // Add any necessary initialization commands for the MM32I073
    await _sendCommand('INIT');
    print('MM32I073 device initialized');
  }

  Future<String> _sendCommand(String command) async {
    if (_writeCharacteristic == null || _readCharacteristic == null) {
      print('MM32I073 characteristics not found');
      return 'MM32I073 characteristics not found';
    }

    try {
      print('Sending command: $command');
      await _writeCharacteristic!.write(Uint8List.fromList(command.codeUnits));
      await Future.delayed(Duration(milliseconds: 100));

      List<int> response = await _readCharacteristic!.read();
      String responseStr = String.fromCharCodes(response).trim();
      print('Received response: $responseStr');

      return responseStr;
    } catch (e) {
      print('Error running MM32I073 command: $e');
      return 'Error';
    }
  }

  void _startReading() async {
    if (!_dataStreamController.isClosed) {
      while (_isConnected) {
        try {
          final selectedSensors = await SensorPreferences.getSelectedSensors();
          final data = <String, String>{};

          for (final sensor in selectedSensors) {
            final command = OBDProtocol.commands[sensor];
            if (command != null) {
              print('Requesting ${command.name}');
              final result = await _sendCommand(command.command);
              print('Raw result for ${command.name}: $result');
              if (result != 'Error') {
                final value = command.calculator(result);
                data[SensorPreferences.allSensors[sensor]!] = value.toString();
                print('Calculated value for ${command.name}: $value');
              } else {
                data[SensorPreferences.allSensors[sensor]!] = 'N/A';
              }
            }
          }

          if (!_dataStreamController.isClosed) {
            _dataStreamController.add(data);
          }
        } catch (e) {
          print('Error reading MM32I073 data: $e');
        }
        await Future.delayed(Duration(milliseconds: 100));
      }
    }
  }
  

  void disconnect() {
    if (_device != null && _isConnected) {
      _device?.disconnect();
      _isConnected = false;
    }
    if (!_dataStreamController.isClosed) {
      _dataStreamController.close();
    }
  }
}

