import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'obd.dart';
import 'sensor_preferences.dart';

class OBDService {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _obdCharacteristic;
  bool _isConnected = false;
  final _dataStreamController = StreamController<Map<String, String>>.broadcast();

  Stream<Map<String, String>> get dataStream => _dataStreamController.stream;

  // Start scanning for devices
  Future<void> startScan() async {
    // Updated for flutter_blue_plus
    FlutterBluePlus.startScan(timeout: Duration(seconds: 10));
    FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult scanResult in results) {
        if (scanResult.device.platformName == 'YourDeviceName') {  // Match the device name
          await connect(scanResult.device);
          FlutterBluePlus.stopScan(); // Stop scanning once the device is found
        }
      }
    });
  }

  // Connect to the selected device using Flutter Blue Plus
  Future<bool> connect(BluetoothDevice device) async {
    try {
      _device = device;

      // Connect to the device
      await _device?.connect();

      // Discover services and characteristics
      List<BluetoothService> services = await _device!.discoverServices();
      for (BluetoothService service in services) {
        // Find the OBD-II characteristic (this depends on your device)
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == 'YOUR_CHARACTERISTIC_UUID') {
            _obdCharacteristic = characteristic;
            break;
          }
        }
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
    _device?.disconnect();
    _isConnected = false;
    _dataStreamController.close();
  }

  // Start reading data from the OBD-II device
  void _startReading() async {
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

        _dataStreamController.add(data);
      } catch (e) {
        print('Error reading OBD data: $e');
      }
      await Future.delayed(Duration(seconds: 1));
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

class OBDProtocol {
  static final Map<String, OBDCommand> commands = {
    'ENGINE_RPM': OBDCommand('01', '0C', 'Engine RPM', (List<int> data) {
      if (data.length < 2) return 0;
      return ((256 * data[0] + data[1]) / 4).round();
    }),
    'VEHICLE_SPEED': OBDCommand('01', '0D', 'Vehicle Speed', (List<int> data) {
      if (data.isEmpty) return 0;
      return data[0];
    }),
    // Add more commands here
  };

  // Parse OBD-II response
  static List<int> parseOBDResponse(String response) {
    try {
      response = response.replaceAll(RegExp(r'[\r\n\s]'), '');
      if (response.contains(':')) {
        response = response.split(':')[1];
      }
      List<int> bytes = [];
      for (int i = 0; i < response.length; i += 2) {
        if (i + 2 <= response.length) {
          String hex = response.substring(i, i + 2);
          bytes.add(int.parse(hex, radix: 16));
        }
      }
      return bytes;
    } catch (e) {
      print('Error parsing OBD response: $e');
      return [];
    }
  }
}

class OBDCommand {
  final String mode;
  final String pid;
  final String name;
  final Function(List<int>) calculator;

  OBDCommand(this.mode, this.pid, this.name, this.calculator);

  String get command => '$mode$pid\r';
}