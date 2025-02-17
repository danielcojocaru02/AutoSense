import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class Obd {
  final BluetoothCharacteristic obdCharacteristic;
  
  Obd(this.obdCharacteristic);
  
  Future<String> runCommand(String command) async {
    try {
      // Convert the command string to a byte array and write it to the characteristic
      await obdCharacteristic.write(Uint8List.fromList(command.codeUnits));
      
      // Wait for the response from the OBD-II device
      List<int> response = await obdCharacteristic.read();
      return String.fromCharCodes(response);
    } catch (e) {
      print('Error running OBD command: $e');
      return 'Error';
    }
  }
}