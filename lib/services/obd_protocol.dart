class OBDCommand {
  final String pid;
  final String mode;
  final String name;
  final Function(List<int>) calculator;

  OBDCommand(this.mode, this.pid, this.name, this.calculator);

  String get command => mode + pid + '\r';
}

class OBDProtocol {
  static final commands = {
    'ENGINE_RPM': OBDCommand('01', '0C', 'Engine RPM', (List<int> data) {
      if (data.length < 2) return 0;
      return ((256 * data[0] + data[1]) / 4).round();
    }),
    'VEHICLE_SPEED': OBDCommand('01', '0D', 'Vehicle Speed', (List<int> data) {
      if (data.isEmpty) return 0;
      return data[0];
    }),
    'COOLANT_TEMP': OBDCommand('01', '05', 'Coolant Temperature', (List<int> data) {
      if (data.isEmpty) return 0;
      return data[0] - 40;
    }),
    'INTAKE_PRESSURE': OBDCommand('01', '0B', 'Intake Pressure', (List<int> data) {
      if (data.isEmpty) return 0;
      return data[0];
    }),
    'MAF_SENSOR': OBDCommand('01', '10', 'MAF Sensor', (List<int> data) {
      if (data.length < 2) return 0;
      return ((256 * data[0] + data[1]) / 100).round();
    }),
    'O2_VOLTAGE': OBDCommand('01', '14', 'O2 Voltage', (List<int> data) {
      if (data.isEmpty) return 0;
      return data[0] / 200;
    }),
  };

  static List<int> parseOBDResponse(String response) {
    try {
      // Remove spaces and line endings
      response = response.replaceAll(RegExp(r'[\r\n\s]'), '');
      
      // Remove echo of the command if present (everything before the ':')
      if (response.contains(':')) {
        response = response.split(':')[1];
      }

      // Convert hex string to bytes
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

