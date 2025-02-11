import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestPermissions() async {
    // Request Bluetooth permissions
    if (await Permission.bluetooth.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted &&
        await Permission.bluetoothScan.request().isGranted) {
      
      // Request location permissions (needed for Bluetooth scanning on some devices)
      if (await Permission.locationWhenInUse.request().isGranted) {
        // Enable Bluetooth if it's not already enabled
        if (!(await FlutterBluetoothSerial.instance.isEnabled ?? false)) {
          await FlutterBluetoothSerial.instance.requestEnable();
        }
        return true;
      }
    }
    return false;
  }
}

