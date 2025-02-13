import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class Obd {
  final BluetoothConnection connection;

  Obd(this.connection);

  Future<String> runCommand(String command) async {
    try {
      connection.output.add(Uint8List.fromList(command.codeUnits));
      await connection.output.allSent;

      final completer = Completer<String>();
      connection.input!.listen((Uint8List data) {
        completer.complete(String.fromCharCodes(data));
      });

      return completer.future.timeout(Duration(seconds: 2), onTimeout: () {
        return 'Timeout';
      });
    } catch (e) {
      print('Error running OBD command: $e');
      return 'Error';
    }
  }
}

