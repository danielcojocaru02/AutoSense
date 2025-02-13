import 'dart:async';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'obd.dart';
import 'sensor_preferences.dart';

class OBDService {
  BluetoothConnection? _connection;
  Obd? _obd;
  bool _isConnected = false;
  final _dataStreamController = StreamController<Map<String, String>>.broadcast();

  Stream<Map<String, String>> get dataStream => _dataStreamController.stream;

  Future<bool> connect(String address) async {
    try {
      _connection = await BluetoothConnection.toAddress(address);
      _obd = Obd(_connection!);
      _isConnected = true;
      _startReading();
      return true;
    } catch (e) {
      print('Failed to connect: $e');
      return false;
    }
  }

  void disconnect() {
    _connection?.close();
    _isConnected = false;
    _dataStreamController.close();
  }

  void _startReading() async {
    while (_isConnected) {
      try {
        final selectedSensors = await SensorPreferences.getSelectedSensors();
        final data = <String, String>{};

        for (final sensor in selectedSensors) {
          final command = OBDProtocol.commands[sensor];
          if (command != null) {
            final result = await _obd!.runCommand(command.command);
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

