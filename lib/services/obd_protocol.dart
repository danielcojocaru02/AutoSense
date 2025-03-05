class OBDCommand {
  final String command;
  final String name;
  final Function(String) calculator;

  OBDCommand(this.command, this.name, this.calculator);
}

class OBDProtocol {
  // OBD-II PIDs (Parameter IDs)
  static const PID_ENGINE_LOAD = 0x04;
  static const PID_ENGINE_COOLANT_TEMP = 0x05;
  static const PID_FUEL_PRESSURE = 0x0A;
  static const PID_INTAKE_MANIFOLD_PRESSURE = 0x0B;
  static const PID_ENGINE_RPM = 0x0C;
  static const PID_VEHICLE_SPEED = 0x0D;
  static const PID_TIMING_ADVANCE = 0x0E;
  static const PID_INTAKE_AIR_TEMP = 0x0F;
  static const PID_MAF_RATE = 0x10;
  static const PID_THROTTLE_POS = 0x11;
  static const PID_O2_VOLTAGE = 0x14;
  static const PID_FUEL_LEVEL = 0x2F;
  static const PID_BAROMETRIC_PRESSURE = 0x33;
  static const PID_CATALYST_TEMP = 0x3C;
  static const PID_CONTROL_MODULE_VOLTAGE = 0x42;
  static const PID_ABSOLUTE_LOAD = 0x43;
  static const PID_AMBIENT_AIR_TEMP = 0x46;
  static const PID_OIL_TEMP = 0x5C;
  static const PID_FUEL_RATE = 0x5E;
  static const PID_ETHANOL_FUEL = 0x52;
  static const PID_FUEL_TYPE = 0x51;
  
  static final commands = {
    'ENGINE_RPM': OBDCommand('01 0C', 'Engine RPM', (String data) {
      try {
        print('Parsing RPM data: $data');
        
        // Parse standard OBD-II response for RPM
        // Format: 41 0C XX YY where (XX * 256 + YY) / 4 = RPM
        if (data.startsWith('41 0C')) {
          List<String> bytes = data.split(' ');
          if (bytes.length >= 4) {
            int a = int.parse(bytes[2], radix: 16);
            int b = int.parse(bytes[3], radix: 16);
            return ((a * 256) + b) / 4;
          }
        } 
        // Some adapters return without spaces
        else if (data.startsWith('410C')) {
          if (data.length >= 8) {
            int a = int.parse(data.substring(4, 6), radix: 16);
            int b = int.parse(data.substring(6, 8), radix: 16);
            return ((a * 256) + b) / 4;
          }
        }
        // Check if we're getting the command echo instead of a response
        else if (data.trim() == '01 0C' || data.trim() == '010C') {
          print('Received command echo instead of response for RPM');
          return 0;
        }
        // Try to parse as direct value
        else {
          try {
            return double.parse(data).round();
          } catch (e) {
            print('Cannot parse RPM data: $data');
            return 0;
          }
        }
        
        print('Failed to parse RPM data: $data');
        return 0;
      } catch (e) {
        print('Error parsing RPM data: $e');
        print('Raw data: $data');
        return 0;
      }
    }),

    'COOLANT_TEMP': OBDCommand('01 05', 'Coolant Temperature', (String data) {
      try {
        print('Parsing coolant temp data: $data');
        
        // Parse standard OBD-II response for coolant temp
        // Format: 41 05 XX where XX - 40 = Temperature in °C
        if (data.startsWith('41 05')) {
          List<String> bytes = data.split(' ');
          if (bytes.length >= 3) {
            int temp = int.parse(bytes[2], radix: 16);
            return temp - 40;
          }
        }
        // Some adapters return without spaces
        else if (data.startsWith('4105')) {
          if (data.length >= 6) {
            int temp = int.parse(data.substring(4, 6), radix: 16);
            return temp - 40;
          }
        }
        // Check if we're getting the command echo instead of a response
        else if (data.trim() == '01 05' || data.trim() == '0105') {
          print('Received command echo instead of response for coolant temp');
          return 0;
        }
        // Try to parse as direct value
        else {
          try {
            return double.parse(data).round();
          } catch (e) {
            print('Cannot parse coolant temp data: $data');
            return 0;
          }
        }
        
        print('Failed to parse coolant temp data: $data');
        return 0;
      } catch (e) {
        print('Error parsing coolant temperature data: $e');
        print('Raw data: $data');
        return 0;
      }
    }),

    'VEHICLE_SPEED': OBDCommand('01 0D', 'Vehicle Speed', (String data) {
      try {
        print('Parsing vehicle speed data: $data');
        
        // Parse standard OBD-II response for speed
        // Format: 41 0D XX where XX = Speed in km/h
        if (data.startsWith('41 0D')) {
          List<String> bytes = data.split(' ');
          if (bytes.length >= 3) {
            return int.parse(bytes[2], radix: 16);
          }
        }
        // Some adapters return without spaces
        else if (data.startsWith('410D')) {
          if (data.length >= 6) {
            return int.parse(data.substring(4, 6), radix: 16);
          }
        }
        // Check if we're getting the command echo instead of a response
        else if (data.trim() == '01 0D' || data.trim() == '010D') {
          print('Received command echo instead of response for vehicle speed');
          return 0;
        }
        // Try to parse as direct value
        else {
          try {
            return double.parse(data).round();
          } catch (e) {
            print('Cannot parse vehicle speed data: $data');
            return 0;
          }
        }
        
        print('Failed to parse vehicle speed data: $data');
        return 0;
      } catch (e) {
        print('Error parsing vehicle speed data: $e');
        print('Raw data: $data');
        return 0;
      }
    }),

    'INTAKE_PRESSURE': OBDCommand('01 0B', 'Intake Pressure', (String data) {
      try {
        print('Parsing intake pressure data: $data');
        
        // Parse standard OBD-II response for intake pressure
        // Format: 41 0B XX where XX = Pressure in kPa
        if (data.startsWith('41 0B')) {
          List<String> bytes = data.split(' ');
          if (bytes.length >= 3) {
            return int.parse(bytes[2], radix: 16);
          }
        }
        // Some adapters return without spaces
        else if (data.startsWith('410B')) {
          if (data.length >= 6) {
            return int.parse(data.substring(4, 6), radix: 16);
          }
        }
        // Check if we're getting the command echo instead of a response
        else if (data.trim() == '01 0B' || data.trim() == '010B') {
          print('Received command echo instead of response for intake pressure');
          return 0;
        }
        // Try to parse as direct value
        else {
          try {
            return double.parse(data).round();
          } catch (e) {
            print('Cannot parse intake pressure data: $data');
            return 0;
          }
        }
        
        print('Failed to parse intake pressure data: $data');
        return 0;
      } catch (e) {
        print('Error parsing intake pressure data: $e');
        print('Raw data: $data');
        return 0;
      }
    }),

    'MAF_SENSOR': OBDCommand('01 10', 'MAF Sensor', (String data) {
      try {
        print('Parsing MAF sensor data: $data');
        
        // Parse standard OBD-II response for MAF
        if (data.startsWith('41 10')) {
          List<String> bytes = data.split(' ');
          if (bytes.length >= 4) {
            int a = int.parse(bytes[2], radix: 16);
            int b = int.parse(bytes[3], radix: 16);
            return ((a * 256) + b) / 100;
          }
        }
        // Some adapters return without spaces
        else if (data.startsWith('4110')) {
          if (data.length >= 8) {
            int a = int.parse(data.substring(4, 6), radix: 16);
            int b = int.parse(data.substring(6, 8), radix: 16);
            return ((a * 256) + b) / 100;
          }
        }
        // Check for command echo
        else if (data.trim() == '01 10' || data.trim() == '0110') {
          print('Received command echo instead of response for MAF Sensor');
          return 0;
        }
        // Try direct parsing
        else {
          try {
            return double.parse(data);
          } catch (e) {
            print('Cannot parse MAF sensor data: $data');
            return 0;
          }
        }
        
        print('Failed to parse MAF sensor data: $data');
        return 0;
      } catch (e) {
        print('Error parsing MAF sensor data: $e');
        print('Raw data: $data');
        return 0;
      }
    }),

    'O2_VOLTAGE': OBDCommand('01 14', 'O2 Voltage', (String data) {
      try {
        print('Parsing O2 voltage data: $data');
        
        // Parse standard OBD-II response for O2 sensor
        if (data.startsWith('41 14')) {
          List<String> bytes = data.split(' ');
          if (bytes.length >= 3) {
            int a = int.parse(bytes[2], radix: 16);
            return a / 200;
          }
        }
        // Some adapters return without spaces
        else if (data.startsWith('4114')) {
          if (data.length >= 6) {
            int a = int.parse(data.substring(4, 6), radix: 16);
            return a / 200;
          }
        }
        // Check for command echo
        else if (data.trim() == '01 14' || data.trim() == '0114') {
          print('Received command echo instead of response for O2 Voltage');
          return 0;
        }
        // Try direct parsing
        else {
          try {
            return double.parse(data);
          } catch (e) {
            print('Cannot parse O2 voltage data: $data');
            return 0;
          }
        }
        
        print('Failed to parse O2 voltage data: $data');
        return 0;
      } catch (e) {
        print('Error parsing O2 voltage data: $e');
        print('Raw data: $data');
        return 0;
      }
    }),
    
    'FUEL_LEVEL': OBDCommand('01 2F', 'Fuel Level', (String data) {
      try {
        print('Parsing fuel level data: $data');
        
        if (data.startsWith('41 2F')) {
          List<String> bytes = data.split(' ');
          if (bytes.length >= 3) {
            int level = int.parse(bytes[2], radix: 16);
            return level * 100 / 255; // Convert to percentage
          }
        }
        // Some adapters return without spaces
        else if (data.startsWith('412F')) {
          if (data.length >= 6) {
            int level = int.parse(data.substring(4, 6), radix: 16);
            return level * 100 / 255; // Convert to percentage
          }
        }
        // Check for command echo
        else if (data.trim() == '01 2F' || data.trim() == '012F') {
          print('Received command echo instead of response for Fuel Level');
          return 0;
        }
        // Try direct parsing
        else {
          try {
            return double.parse(data);
          } catch (e) {
            print('Cannot parse fuel level data: $data');
            return 0;
          }
        }
        
        print('Failed to parse fuel level data: $data');
        return 0;
      } catch (e) {
        print('Error parsing fuel level data: $e');
        print('Raw data: $data');
        return 0;
      }
    }),
    
    'THROTTLE_POS': OBDCommand('01 11', 'Throttle Position', (String data) {
      try {
        print('Parsing throttle position data: $data');
        
        if (data.startsWith('41 11')) {
          List<String> bytes = data.split(' ');
          if (bytes.length >= 3) {
            int pos = int.parse(bytes[2], radix: 16);
            return pos * 100 / 255; // Convert to percentage
          }
        }
        // Some adapters return without spaces
        else if (data.startsWith('4111')) {
          if (data.length >= 6) {
            int pos = int.parse(data.substring(4, 6), radix: 16);
            return pos * 100 / 255; // Convert to percentage
          }
        }
        // Check for command echo
        else if (data.trim() == '01 11' || data.trim() == '0111') {
          print('Received command echo instead of response for Throttle Position');
          return 0;
        }
        // Try direct parsing
        else {
          try {
            return double.parse(data);
          } catch (e) {
            print('Cannot parse throttle position data: $data');
            return 0;
          }
        }
        
        print('Failed to parse throttle position data: $data');
        return 0;
      } catch (e) {
        print('Error parsing throttle position data: $e');
        print('Raw data: $data');
        return 0;
      }
    }),
    
    // Additional sensors
    'ENGINE_LOAD': OBDCommand('01 04', 'Engine Load', (String data) {
      try {
        print('Parsing engine load data: $data');
        
        if (data.startsWith('41 04')) {
          List<String> bytes = data.split(' ');
          if (bytes.length >= 3) {
            int load = int.parse(bytes[2], radix: 16);
            return load * 100 / 255; // Convert to percentage
          }
        }
        // Some adapters return without spaces
        else if (data.startsWith('4104')) {
          if (data.length >= 6) {
            int load = int.parse(data.substring(4, 6), radix: 16);
            return load * 100 / 255; // Convert to percentage
          }
        }
        // Check for command echo
        else if (data.trim() == '01 04' || data.trim() == '0104') {
          print('Received command echo instead of response for Engine Load');
          return 0;
        }
        // Try direct parsing
        else {
          try {
            return double.parse(data);
          } catch (e) {
            print('Cannot parse engine load data: $data');
            return 0;
          }
        }
        
        print('Failed to parse engine load data: $data');
        return 0;
      } catch (e) {
        print('Error parsing engine load data: $e');
        print('Raw data: $data');
        return 0;
      }
    }),
    
    'TIMING_ADVANCE': OBDCommand('01 0E', 'Timing Advance', (String data) {
      try {
        print('Parsing timing advance data: $data');
        
        if (data.startsWith('41 0E')) {
          List<String> bytes = data.split(' ');
          if (bytes.length >= 3) {
            int advance = int.parse(bytes[2], radix: 16);
            return (advance - 128) / 2; // Convert to degrees before TDC
          }
        }
        // Some adapters return without spaces
        else if (data.startsWith('410E')) {
          if (data.length >= 6) {
            int advance = int.parse(data.substring(4, 6), radix: 16);
            return (advance - 128) / 2; // Convert to degrees before TDC
          }
        }
        // Check for command echo
        else if (data.trim() == '01 0E' || data.trim() == '010E') {
          print('Received command echo instead of response for Timing Advance');
          return 0;
        }
        // Try direct parsing
        else {
          try {
            return double.parse(data);
          } catch (e) {
            print('Cannot parse timing advance data: $data');
            return 0;
          }
        }
        
        print('Failed to parse timing advance data: $data');
        return 0;
      } catch (e) {
        print('Error parsing timing advance data: $e');
        print('Raw data: $data');
        return 0;
      }
    }),
    
    'FUEL_PRESSURE': OBDCommand('01 0A', 'Fuel Pressure', (String data) {
      try {
        print('Parsing fuel pressure data: $data');
        
        if (data.startsWith('41 0A')) {
          List<String> bytes = data.split(' ');
          if (bytes.length >= 3) {
            int pressure = int.parse(bytes[2], radix: 16);
            return pressure * 3; // Convert to kPa (3 kPa per bit)
          }
        }
        // Some adapters return without spaces
        else if (data.startsWith('410A')) {
          if (data.length >= 6) {
            int pressure = int.parse(data.substring(4, 6), radix: 16);
            return pressure * 3; // Convert to kPa (3 kPa per bit)
          }
        }
        // Check for command echo
        else if (data.trim() == '01 0A' || data.trim() == '010A') {
          print('Received command echo instead of response for Fuel Pressure');
          return 0;
        }
        // Try direct parsing
        else {
          try {
            return double.parse(data);
          } catch (e) {
            print('Cannot parse fuel pressure data: $data');
            return 0;
          }
        }
        
        print('Failed to parse fuel pressure data: $data');
        return 0;
      } catch (e) {
        print('Error parsing fuel pressure data: $e');
        print('Raw data: $data');
        return 0;
      }
    }),
    
    'BAROMETRIC_PRESSURE': OBDCommand('01 33', 'Barometric Pressure', (String data) {
      try {
        print('Parsing barometric pressure data: $data');
        
        if (data.startsWith('41 33')) {
          List<String> bytes = data.split(' ');
          if (bytes.length >= 3) {
            int pressure = int.parse(bytes[2], radix: 16);
            return pressure; // Value in kPa
          }
        }
        // Some adapters return without spaces
        else if (data.startsWith('4133')) {
          if (data.length >= 6) {
            int pressure = int.parse(data.substring(4, 6), radix: 16);
            return pressure; // Value in kPa
          }
        }
        // Check for command echo
        else if (data.trim() == '01 33' || data.trim() == '0133') {
          print('Received command echo instead of response for Barometric Pressure');
          return 0;
        }
        // Try direct parsing
        else {
          try {
            return double.parse(data);
          } catch (e) {
            print('Cannot parse barometric pressure data: $data');
            return 0;
          }
        }
        
        print('Failed to parse barometric pressure data: $data');
        return 0;
      } catch (e) {
        print('Error parsing barometric pressure data: $e');
        print('Raw data: $data');
        return 0;
      }
    }),
    
    'AMBIENT_TEMP': OBDCommand('01 46', 'Ambient Temperature', (String data) {
      try {
        print('Parsing ambient temperature data: $data');
        
        if (data.startsWith('41 46')) {
          List<String> bytes = data.split(' ');
          if (bytes.length >= 3) {
            int temp = int.parse(bytes[2], radix: 16);
            return temp - 40; // Convert to °C
          }
        }
        // Some adapters return without spaces
        else if (data.startsWith('4146')) {
          if (data.length >= 6) {
            int temp = int.parse(data.substring(4, 6), radix: 16);
            return temp - 40; // Convert to °C
          }
        }
        // Check for command echo
        else if (data.trim() == '01 46' || data.trim() == '0146') {
          print('Received command echo instead of response for Ambient Temperature');
          return 0;
        }
        // Try direct parsing
        else {
          try {
            return double.parse(data);
          } catch (e) {
            print('Cannot parse ambient temperature data: $data');
            return 0;
          }
        }
        
        print('Failed to parse ambient temperature data: $data');
        return 0;
      } catch (e) {
        print('Error parsing ambient temperature data: $e');
        print('Raw data: $data');
        return 0;
      }
    }),
    
    'OIL_TEMP': OBDCommand('01 5C', 'Oil Temperature', (String data) {
      try {
        print('Parsing oil temperature data: $data');
        
        if (data.startsWith('41 5C')) {
          List<String> bytes = data.split(' ');
          if (bytes.length >= 3) {
            int temp = int.parse(bytes[2], radix: 16);
            return temp - 40; // Convert to °C
          }
        }
        // Some adapters return without spaces
        else if (data.startsWith('415C')) {
          if (data.length >= 6) {
            int temp = int.parse(data.substring(4, 6), radix: 16);
            return temp - 40; // Convert to °C
          }
        }
        // Check for command echo
        else if (data.trim() == '01 5C' || data.trim() == '015C') {
          print('Received command echo instead of response for Oil Temperature');
          return 0;
        }
        // Try direct parsing
        else {
          try {
            return double.parse(data);
          } catch (e) {
            print('Cannot parse oil temperature data: $data');
            return 0;
          }
        }
        
        print('Failed to parse oil temperature data: $data');
        return 0;
      } catch (e) {
        print('Error parsing oil temperature data: $e');
        print('Raw data: $data');
        return 0;
      }
    }),
    
    'FUEL_RATE': OBDCommand('01 5E', 'Fuel Rate', (String data) {
      try {
        print('Parsing fuel rate data: $data');
        
        if (data.startsWith('41 5E')) {
          List<String> bytes = data.split(' ');
          if (bytes.length >= 4) {
            int a = int.parse(bytes[2], radix: 16);
            int b = int.parse(bytes[3], radix: 16);
            return ((a * 256) + b) / 20; // Convert to L/h
          }
        }
        // Some adapters return without spaces
        else if (data.startsWith('415E')) {
          if (data.length >= 8) {
            int a = int.parse(data.substring(4, 6), radix: 16);
            int b = int.parse(data.substring(6, 8), radix: 16);
            return ((a * 256) + b) / 20; // Convert to L/h
          }
        }
        // Check for command echo
        else if (data.trim() == '01 5E' || data.trim() == '015E') {
          print('Received command echo instead of response for Fuel Rate');
          return 0;
        }
        // Try direct parsing
        else {
          try {
            return double.parse(data);
          } catch (e) {
            print('Cannot parse fuel rate data: $data');
            return 0;
          }
        }
        
        print('Failed to parse fuel rate data: $data');
        return 0;
      } catch (e) {
        print('Error parsing fuel rate data: $e');
        print('Raw data: $data');
        return 0;
      }
    }),
    
    'FUEL_TYPE': OBDCommand('01 51', 'Fuel Type', (String data) {
      try {
        print('Parsing fuel type data: $data');
        
        if (data.startsWith('41 51')) {
          List<String> bytes = data.split(' ');
          if (bytes.length >= 3) {
            int fuelType = int.parse(bytes[2], radix: 16);
            return _getFuelTypeName(fuelType);
          }
        }
        // Some adapters return without spaces
        else if (data.startsWith('4151')) {
          if (data.length >= 6) {
            int fuelType = int.parse(data.substring(4, 6), radix: 16);
            return _getFuelTypeName(fuelType);
          }
        }
        // Check for command echo
        else if (data.trim() == '01 51' || data.trim() == '0151') {
          print('Received command echo instead of response for Fuel Type');
          return 'Unknown';
        }
        
        print('Failed to parse fuel type data: $data');
        return 'Unknown';
      } catch (e) {
        print('Error parsing fuel type data: $e');
        print('Raw data: $data');
        return 'Unknown';
      }
    }),
    
    'ETHANOL_FUEL': OBDCommand('01 52', 'Ethanol Fuel %', (String data) {
      try {
        print('Parsing ethanol fuel data: $data');
        
        if (data.startsWith('41 52')) {
          List<String> bytes = data.split(' ');
          if (bytes.length >= 3) {
            int ethanol = int.parse(bytes[2], radix: 16);
            return ethanol * 100 / 255; // Convert to percentage
          }
        }
        // Some adapters return without spaces
        else if (data.startsWith('4152')) {
          if (data.length >= 6) {
            int ethanol = int.parse(data.substring(4, 6), radix: 16);
            return ethanol * 100 / 255; // Convert to percentage
          }
        }
        // Check for command echo
        else if (data.trim() == '01 52' || data.trim() == '0152') {
          print('Received command echo instead of response for Ethanol Fuel');
          return 0;
        }
        // Try direct parsing
        else {
          try {
            return double.parse(data);
          } catch (e) {
            print('Cannot parse ethanol fuel data: $data');
            return 0;
          }
        }
        
        print('Failed to parse ethanol fuel data: $data');
        return 0;
      } catch (e) {
        print('Error parsing ethanol fuel data: $e');
        print('Raw data: $data');
        return 0;
      }
    }),
    
    'CATALYST_TEMP': OBDCommand('01 3C', 'Catalyst Temperature', (String data) {
      try {
        print('Parsing catalyst temperature data: $data');
        
        if (data.startsWith('41 3C')) {
          List<String> bytes = data.split(' ');
          if (bytes.length >= 4) {
            int a = int.parse(bytes[2], radix: 16);
            int b = int.parse(bytes[3], radix: 16);
            return ((a * 256) + b) / 10 - 40; // Convert to °C
          }
        }
        // Some adapters return without spaces
        else if (data.startsWith('413C')) {
          if (data.length >= 8) {
            int a = int.parse(data.substring(4, 6), radix: 16);
            int b = int.parse(data.substring(6, 8), radix: 16);
            return ((a * 256) + b) / 10 - 40; // Convert to °C
          }
        }
        // Check for command echo
        else if (data.trim() == '01 3C' || data.trim() == '013C') {
          print('Received command echo instead of response for Catalyst Temperature');
          return 0;
        }
        // Try direct parsing
        else {
          try {
            return double.parse(data);
          } catch (e) {
            print('Cannot parse catalyst temperature data: $data');
            return 0;
          }
        }
        
        print('Failed to parse catalyst temperature data: $data');
        return 0;
      } catch (e) {
        print('Error parsing catalyst temperature data: $e');
        print('Raw data: $data');
        return 0;
      }
    }),
    
    'CONTROL_MODULE_VOLTAGE': OBDCommand('01 42', 'Control Module Voltage', (String data) {
      try {
        print('Parsing control module voltage data: $data');
        
        if (data.startsWith('41 42')) {
          List<String> bytes = data.split(' ');
          if (bytes.length >= 4) {
            int a = int.parse(bytes[2], radix: 16);
            int b = int.parse(bytes[3], radix: 16);
            return ((a * 256) + b) / 1000; // Convert to Volts
          }
        }
        // Some adapters return without spaces
        else if (data.startsWith('4142')) {
          if (data.length >= 8) {
            int a = int.parse(data.substring(4, 6), radix: 16);
            int b = int.parse(data.substring(6, 8), radix: 16);
            return ((a * 256) + b) / 1000; // Convert to Volts
          }
        }
        // Check for command echo
        else if (data.trim() == '01 42' || data.trim() == '0142') {
          print('Received command echo instead of response for Control Module Voltage');
          return 0;
        }
        // Try direct parsing
        else {
          try {
            return double.parse(data);
          } catch (e) {
            print('Cannot parse control module voltage data: $data');
            return 0;
          }
        }
        
        print('Failed to parse control module voltage data: $data');
        return 0;
      } catch (e) {
        print('Error parsing control module voltage data: $e');
        print('Raw data: $data');
        return 0;
      }
    }),
    
    'ABSOLUTE_LOAD': OBDCommand('01 43', 'Absolute Load', (String data) {
      try {
        print('Parsing absolute load data: $data');
        
        if (data.startsWith('41 43')) {
          List<String> bytes = data.split(' ');
          if (bytes.length >= 4) {
            int a = int.parse(bytes[2], radix: 16);
            int b = int.parse(bytes[3], radix: 16);
            return ((a * 256) + b) * 100 / 255; // Convert to percentage
          }
        }
        // Some adapters return without spaces
        else if (data.startsWith('4143')) {
          if (data.length >= 8) {
            int a = int.parse(data.substring(4, 6), radix: 16);
            int b = int.parse(data.substring(6, 8), radix: 16);
            return ((a * 256) + b) * 100 / 255; // Convert to percentage
          }
        }
        // Check for command echo
        else if (data.trim() == '01 43' || data.trim() == '0143') {
          print('Received command echo instead of response for Absolute Load');
          return 0;
        }
        // Try direct parsing
        else {
          try {
            return double.parse(data);
          } catch (e) {
            print('Cannot parse absolute load data: $data');
            return 0;
          }
        }
        
        print('Failed to parse absolute load data: $data');
        return 0;
      } catch (e) {
        print('Error parsing absolute load data: $e');
        print('Raw data: $data');
        return 0;
      }
    }),
  };
  
  // Helper method to convert fuel type code to name
  static String _getFuelTypeName(int code) {
    switch (code) {
      case 0: return 'Not Available';
      case 1: return 'Gasoline';
      case 2: return 'Methanol';
      case 3: return 'Ethanol';
      case 4: return 'Diesel';
      case 5: return 'LPG';
      case 6: return 'CNG';
      case 7: return 'Propane';
      case 8: return 'Electric';
      case 9: return 'Bifuel running Gasoline';
      case 10: return 'Bifuel running Methanol';
      case 11: return 'Bifuel running Ethanol';
      case 12: return 'Bifuel running LPG';
      case 13: return 'Bifuel running CNG';
      case 14: return 'Bifuel running Propane';
      case 15: return 'Bifuel running Electricity';
      case 16: return 'Bifuel running electric and combustion engine';
      case 17: return 'Hybrid gasoline';
      case 18: return 'Hybrid Ethanol';
      case 19: return 'Hybrid Diesel';
      case 20: return 'Hybrid Electric';
      case 21: return 'Hybrid running electric and combustion engine';
      case 22: return 'Hybrid Regenerative';
      case 23: return 'Bifuel running diesel';
      default: return 'Unknown';
    }
  }
  
  // Parse OBD-II response based on PID
  static dynamic parseOBDResponse(String data, int pid) {
    try {
      // Trim whitespace and split by spaces
      final parts = data.trim().split(' ');
      
      // Check if we have a valid response format
      if (parts.length < 2) {
        print('Invalid response format: $data');
        return null;
      }
      
      // Check if this is a response to our request (should start with 41 + PID)
      // Standard OBD-II response format: 41 [PID] [Data bytes...]
      // 41 is the response code (01 + 40)
      if (parts[0] != '41' && parts[1] != pid.toRadixString(16).padLeft(2, '0')) {
        // If we're getting "01 XX" responses, it means we're seeing the request echo, not the response
        print('Not a valid response for PID ${pid.toRadixString(16)}: $data');
        return null;
      }
      
      // Parse based on PID
      switch (pid) {
        case PID_ENGINE_COOLANT_TEMP:
        case PID_INTAKE_AIR_TEMP:
        case PID_AMBIENT_AIR_TEMP:
        case PID_OIL_TEMP:
          if (parts.length > 2) {
            // A - 40 (where A is the data byte)
            final value = int.parse(parts[2], radix: 16) - 40;
            return value.toDouble();
          }
          break;
          
        case PID_INTAKE_MANIFOLD_PRESSURE:
        case PID_BAROMETRIC_PRESSURE:
        case PID_FUEL_PRESSURE:
          if (parts.length > 2) {
            // A (where A is the data byte in kPa)
            final value = int.parse(parts[2], radix: 16);
            return value.toDouble();
          }
          break;
          
        case PID_ENGINE_RPM:
          if (parts.length > 3) {
            // ((A * 256) + B) / 4 (where A and B are data bytes)
            final a = int.parse(parts[2], radix: 16);
            final b = int.parse(parts[3], radix: 16);
            final rpm = ((a * 256) + b) / 4;
            return rpm;
          }
          break;
          
        case PID_VEHICLE_SPEED:
          if (parts.length > 2) {
            // A (where A is the data byte in km/h)
            final value = int.parse(parts[2], radix: 16);
            return value.toDouble();
          }
          break;
          
        case PID_TIMING_ADVANCE:
          if (parts.length > 2) {
            // (A - 128) / 2 (where A is the data byte)
            final value = (int.parse(parts[2], radix: 16) - 128) / 2;
            return value.toDouble();
          }
          break;
          
        case PID_MAF_RATE:
          if (parts.length > 3) {
            // ((A * 256) + B) / 100 (where A and B are data bytes)
            final a = int.parse(parts[2], radix: 16);
            final b = int.parse(parts[3], radix: 16);
            final maf = ((a * 256) + b) / 100;
            return maf;
          }
          break;
          
        case PID_THROTTLE_POS:
        case PID_ENGINE_LOAD:
        case PID_ABSOLUTE_LOAD:
        case PID_ETHANOL_FUEL:
          if (parts.length > 2) {
            // A * 100 / 255 (where A is the data byte)
            final value = int.parse(parts[2], radix: 16) * 100 / 255;
            return value.toDouble();
          }
          break;
          
        case PID_FUEL_TYPE:
          if (parts.length > 2) {
            // A (where A is the fuel type code)
            final code = int.parse(parts[2], radix: 16);
            return _getFuelTypeName(code);
          }
          break;
          
        case PID_CONTROL_MODULE_VOLTAGE:
          if (parts.length > 3) {
            // ((A * 256) + B) / 1000 (where A and B are data bytes)
            final a = int.parse(parts[2], radix: 16);
            final b = int.parse(parts[3], radix: 16);
            final voltage = ((a * 256) + b) / 1000;
            return voltage;
          }
          break;
          
        case PID_CATALYST_TEMP:
          if (parts.length > 3) {
            // ((A * 256) + B) / 10 - 40 (where A and B are data bytes)
            final a = int.parse(parts[2], radix: 16);
            final b = int.parse(parts[3], radix: 16);
            final temp = ((a * 256) + b) / 10 - 40;
            return temp;
          }
          break;
          
        case PID_FUEL_RATE:
          if (parts.length > 3) {
            // ((A * 256) + B) / 20 (where A and B are data bytes)
            final a = int.parse(parts[2], radix: 16);
            final b = int.parse(parts[3], radix: 16);
            final rate = ((a * 256) + b) / 20;
            return rate;
          }
          break;
      }
      
      print('Failed to parse data for PID ${pid.toRadixString(16)}: $data');
      return null;
    } catch (e) {
      print('Error parsing data for PID ${pid.toRadixString(16)}: $e');
      print('Raw data: $data');
      return null;
    }
  }
  
  // Format OBD-II request command
  static String formatRequest(int pid) {
    // Standard OBD-II request format: 01 [PID]
    return '01 ${pid.toRadixString(16).padLeft(2, '0')}';
  }
}

