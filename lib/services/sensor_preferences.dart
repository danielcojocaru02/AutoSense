import 'package:shared_preferences/shared_preferences.dart';

class SensorPreferences {
  static const String _keySensors = 'selected_sensors';

  static Future<List<String>> getSelectedSensors() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keySensors) ?? defaultSensors;
  }

  static Future<void> setSelectedSensors(List<String> sensors) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keySensors, sensors);
  }

  static const List<String> defaultSensors = [
    'ENGINE_RPM',
    'VEHICLE_SPEED',
    'COOLANT_TEMP',
    'INTAKE_PRESSURE',
  ];

  static const Map<String, String> allSensors = {
    'ENGINE_RPM': 'Engine RPM',
    'VEHICLE_SPEED': 'Vehicle Speed',
    'COOLANT_TEMP': 'Coolant Temperature',
    'INTAKE_PRESSURE': 'Intake Pressure',
    'MAF_SENSOR': 'MAF Sensor',
    'O2_VOLTAGE': 'O2 Voltage',
    'FUEL_LEVEL': 'Fuel Level',
    'THROTTLE_POS': 'Throttle Position',
    'ENGINE_LOAD': 'Engine Load',
    'TIMING_ADVANCE': 'Timing Advance',
    'FUEL_PRESSURE': 'Fuel Pressure',
    'BAROMETRIC_PRESSURE': 'Barometric Pressure',
    'AMBIENT_TEMP': 'Ambient Temperature',
    'OIL_TEMP': 'Oil Temperature',
    'FUEL_RATE': 'Fuel Rate',
    'FUEL_TYPE': 'Fuel Type',
    'ETHANOL_FUEL': 'Ethanol Fuel %',
    'CATALYST_TEMP': 'Catalyst Temperature',
    'CONTROL_MODULE_VOLTAGE': 'Control Module Voltage',
    'ABSOLUTE_LOAD': 'Absolute Load',
  };
}

