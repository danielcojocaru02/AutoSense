class OBDCommand {
  final String command;
  final String name;
  final Function(String) calculator;

  OBDCommand(this.command, this.name, this.calculator);
}

class OBDProtocol {
  static final commands = {
    'ENGINE_RPM': OBDCommand('RPM', 'Engine RPM', (String data) {
      try {
        return double.parse(data).round();
      } catch (e) {
        print('Error parsing RPM data: $e');
        return 0;
      }
    }),

    'COOLANT_TEMP': OBDCommand('TEMP', 'Coolant Temperature', (String data) {
      try {
        return double.parse(data).round();
      } catch (e) {
        print('Error parsing coolant temperature data: $e');
        return 0;
      }
    }),

    'VEHICLE_SPEED': OBDCommand('SPEED', 'Vehicle Speed', (String data) {
      try {
        return double.parse(data).round();
      } catch (e) {
        print('Error parsing vehicle speed data: $e');
        return 0;
      }
    }),

    'INTAKE_PRESSURE': OBDCommand('INTAKE', 'Intake Pressure', (String data) {
      try {
        return double.parse(data).round();
      } catch (e) {
        print('Error parsing intake pressure data: $e');
        return 0;
      }
    }),

    'MAF_SENSOR': OBDCommand('MAF', 'MAF Sensor', (String data) {
      try {
        return double.parse(data);
      } catch (e) {
        print('Error parsing MAF sensor data: $e');
        return 0;
      }
    }),

    'O2_VOLTAGE': OBDCommand('O2', 'O2 Voltage', (String data) {
      try {
        return double.parse(data);
      } catch (e) {
        print('Error parsing O2 voltage data: $e');
        return 0;
      }
    }),
  };
}

