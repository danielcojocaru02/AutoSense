import 'dart:async';
import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import './obd_protocol.dart';

class OBDService {
  BluetoothConnection? _connection;
  bool _isConnected = false;
  final _dataStreamController = StreamController<Map<String, String>>.broadcast();
  
  Stream<Map<String, String>> get dataStream => _dataStreamController.stream;

  Future<bool> connect(String address) async {
    try {
      _connection = await BluetoothConnection.toAddress(address);
      _isConnected = true;
      
      // Initialize ELM327
      await _sendCommand('ATZ'); // Reset
      await Future.delayed(const Duration(seconds: 1));
      await _sendCommand('ATE0'); // Echo off
      await _sendCommand('ATL0'); // Linefeeds off
      await _sendCommand('ATS0'); // Spaces off
      await _sendCommand('ATH0'); // Headers off
      await _sendCommand('ATSP0'); // Auto protocol

      _startReading();
      return true;
    } catch (e) {
      print('Failed to connect: $e');
      return false;
    }
  }

  Future<String?> _sendCommand(String command) async {
    try {
      _connection?.output.add(utf8.encode('$command\r'));
      await _connection?.output.allSent;
      await Future.delayed(const Duration(milliseconds: 100));
      return command;
    } catch (e) {
      print('Error sending command: $e');
      return null;
    }
  }

  void _startReading() async {
    if (_connection == null) return;

    _connection!.input!.listen((data) {
      String response = utf8.decode(data);
      print('Raw response: $response');
    });

    while (_isConnected) {
      try {
        Map<String, String> data = {};
        
        for (var entry in OBDProtocol.commands.entries) {
          final command = entry.value;
          final response = await _sendCommand(command.command);
          if (response != null) {
            final bytes = OBDProtocol.parseOBDResponse(response);
            final value = command.calculator(bytes);
            data[command.name] = value.toString();
          }
        }

        _dataStreamController.add(data);
      } catch (e) {
        print('Error reading OBD data: $e');
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  void disconnect() {
    _connection?.close();
    _isConnected = false;
    _dataStreamController.close();
  }
}

