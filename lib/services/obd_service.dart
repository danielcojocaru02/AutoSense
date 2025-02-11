import 'dart:async';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:obd/obd.dart';

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
        final data = await Future.wait([
          _obd!.getEngineRPM(),
          _obd!.getVehicleSpeed(),
          _obd!.getCoolantTemperature(),
          _obd!.getVoltageSensor(),
          _obd!.getIntakeManifoldPressure(), // For turbo pressure
          _obd!.getOilTemperature(),
        ]);

        _dataStreamController.add({
          'Engine RPM': '${data[0]} RPM',
          'Vehicle Speed': '${data[1]} km/h',
          'Coolant Temp': '${data[2]}°C',
          'Battery Voltage': '${data[3]} V',
          'Turbo Pressure': '${data[4]} kPa',
          'Oil Temperature': '${data[5]}°C',
        });
      } catch (e) {
        print('Error reading OBD data: $e');
      }
      await Future.delayed(Duration(seconds: 1));
    }
  }
}

