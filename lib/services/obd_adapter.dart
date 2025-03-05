import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'obd_protocol.dart';

class OBDAdapter {
  final BluetoothDevice device;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _readCharacteristic;
  bool _isConnected = false;
  bool _isStandardOBD = false;
  
  // Add a stream subscription for notifications
  StreamSubscription? _notificationSubscription;
  final _responseStreamController = StreamController<String>.broadcast();
  
  // Add a completer to handle async responses
  Completer<String>? _currentResponseCompleter;
  
  // Add a buffer for collecting multi-part responses
  final List<String> _responseBuffer = [];
  Timer? _responseTimer;
  
  OBDAdapter(this.device);
  
  Future<bool> connect() async {
    try {
      print('Connecting to device: ${device.platformName}');
      await device.connect(autoConnect: false);
      print('Connected, discovering services...');
      
      List<BluetoothService> services = await device.discoverServices();
      print('Found ${services.length} services');
      
      // Debug: Print all services and characteristics
      for (var service in services) {
        print('Service: ${service.uuid}');
        for (var char in service.characteristics) {
          String props = '';
          if (char.properties.read) props += 'R';
          if (char.properties.write) props += 'W';
          if (char.properties.notify) props += 'N';
          if (char.properties.writeWithoutResponse) props += 'WWR';
          print('  Char: ${char.uuid} ($props)');
        }
      }
      
      // Common service UUIDs for OBD adapters:
      final List<String> knownServiceUuids = [
        "fff0", // Common for ELM327 clones
        "ffe0", // Common for HC-05/HC-06 modules
        "0000ffe0-0000-1000-8000-00805f9b34fb", // Full UUID version
        "0000fff0-0000-1000-8000-00805f9b34fb"  // Full UUID version
      ];
      
      // Common characteristic UUIDs for OBD adapters:
      final List<String> knownCharUuids = [
        "fff1", "fff2", // Write/read for some adapters
        "ffe1", "ffe2", // Write/read for HC-05/HC-06
        "0000ffe1-0000-1000-8000-00805f9b34fb",
        "0000fff1-0000-1000-8000-00805f9b34fb"
      ];
      
      // First try to find known OBD service/characteristic pairs
      for (var service in services) {
        String serviceUuidString = service.uuid.toString().toLowerCase();
        String shortUuid;
        
        // Extract the short UUID safely
        try {
          // For full UUIDs like "0000fff0-0000-1000-8000-00805f9b34fb"
          if (serviceUuidString.contains('-')) {
            shortUuid = serviceUuidString.split('-')[0];
            // Remove leading zeros
            while (shortUuid.startsWith('0') && shortUuid.length > 4) {
              shortUuid = shortUuid.substring(1);
            }
          } 
          // For short UUIDs like "fff0"
          else {
            shortUuid = serviceUuidString;
          }
        } catch (e) {
          print('Error extracting short UUID: $e');
          shortUuid = serviceUuidString; // Use the full string as fallback
        }
        
        print('Service UUID: $serviceUuidString, Short UUID: $shortUuid');
        
        if (knownServiceUuids.contains(shortUuid) || 
            knownServiceUuids.contains(serviceUuidString)) {
          print('Found potential OBD service: ${service.uuid}');
          
          for (var char in service.characteristics) {
            String charUuidString = char.uuid.toString().toLowerCase();
            String shortCharUuid;
            
            // Extract the short characteristic UUID safely
            try {
              // For full UUIDs
              if (charUuidString.contains('-')) {
                shortCharUuid = charUuidString.split('-')[0];
                // Remove leading zeros
                while (shortCharUuid.startsWith('0') && shortCharUuid.length > 4) {
                  shortCharUuid = shortCharUuid.substring(1);
                }
              } 
              // For short UUIDs
              else {
                shortCharUuid = charUuidString;
              }
            } catch (e) {
              print('Error extracting short char UUID: $e');
              shortCharUuid = charUuidString; // Use the full string as fallback
            }
            
            print('Char UUID: $charUuidString, Short UUID: $shortCharUuid');
            
            // For fff0 service, fff1 is typically read/notify and fff2 is write
            if (shortUuid == "fff0") {
              if (shortCharUuid == "fff1" && (char.properties.read || char.properties.notify)) {
                _readCharacteristic = char;
                print('Found read characteristic: ${char.uuid}');
              }
              if (shortCharUuid == "fff2" && char.properties.write) {
                _writeCharacteristic = char;
                print('Found write characteristic: ${char.uuid}');
              }
            }
            // For other services, use the generic approach
            else if (char.properties.write && 
                (knownCharUuids.contains(shortCharUuid) || 
                 knownCharUuids.contains(charUuidString))) {
              _writeCharacteristic = char;
              print('Found write characteristic: ${char.uuid}');
            }
            
            if ((char.properties.read || char.properties.notify) && 
                (knownCharUuids.contains(shortCharUuid) || 
                 knownCharUuids.contains(charUuidString))) {
              _readCharacteristic = char;
              print('Found read characteristic: ${char.uuid}');
            }
          }
        }
      }
      
      // If we didn't find known characteristics, try a more generic approach
      if (_writeCharacteristic == null || _readCharacteristic == null) {
        print('Known OBD characteristics not found, trying generic approach');
        for (var service in services) {
          String serviceUuidString = service.uuid.toString().toLowerCase();
          
          // Skip the Generic Access and Generic Attribute services
          if (serviceUuidString.contains('1800') || serviceUuidString.contains('1801')) {
            continue;
          }
          
          for (var char in service.characteristics) {
            String charUuidString = char.uuid.toString().toLowerCase();
            
            // Skip the Device Name characteristic (2a00)
            if (charUuidString.contains('2a00')) {
              continue;
            }
            
            if (char.properties.write && _writeCharacteristic == null) {
              _writeCharacteristic = char;
              print('Using generic write characteristic: ${char.uuid}');
            }
            
            if ((char.properties.read || char.properties.notify) && _readCharacteristic == null) {
              _readCharacteristic = char;
              print('Using generic read characteristic: ${char.uuid}');
            }
            
            if (_writeCharacteristic != null && _readCharacteristic != null) break;
          }
          if (_writeCharacteristic != null && _readCharacteristic != null) break;
        }
      }
      
      if (_writeCharacteristic == null || _readCharacteristic == null) {
        print('OBD characteristics not found');
        return false;
      }
      
      // Set up notification if available
      if (_readCharacteristic!.properties.notify) {
        print('Setting up notifications for read characteristic');
        await _readCharacteristic!.setNotifyValue(true);
        _notificationSubscription = _readCharacteristic!.value.listen((value) {
          if (value.isNotEmpty) {
            String response = String.fromCharCodes(value).trim();
            print('Notification received: $response');
            _responseStreamController.add(response);
            
            // Add to buffer for multi-part responses
            _handleResponsePart(response);
          }
        });
      }
      
      _isConnected = true;
      await _initializeAdapter();
      return true;
    } catch (e) {
      print('Failed to connect to OBD adapter: $e');
      return false;
    }
  }
  
  void _handleResponsePart(String responsePart) {
    // Cancel any existing timer
    _responseTimer?.cancel();
    
    // If this is an empty response, ignore it
    if (responsePart.isEmpty) {
      return;
    }
    
    // Add to buffer
    _responseBuffer.add(responsePart);
    
    // Start a timer to collect all parts of the response
    _responseTimer = Timer(Duration(milliseconds: 200), () {
      if (_currentResponseCompleter != null && !_currentResponseCompleter!.isCompleted) {
        // Join all parts of the response
        String fullResponse = _responseBuffer.join(' ');
        print('Collected full response: $fullResponse');
        
        // Complete the current response
        _currentResponseCompleter!.complete(fullResponse);
        _currentResponseCompleter = null;
        
        // Clear the buffer
        _responseBuffer.clear();
      }
    });
  }
  
  Future<void> _initializeAdapter() async {
    try {
      // Try standard ELM327 initialization
      print('Initializing adapter...');
      
      // Reset the adapter
      String response = await sendRawCommand('ATZ', timeout: Duration(seconds: 3));
      print('Reset response: $response');
      
      if (response.contains('ELM') || response.contains('elm')) {
        print('ELM327 adapter detected');
        _isStandardOBD = true;
        
        // Configure the adapter - try different termination characters
        await sendRawCommand('ATE0\r'); // Echo off with CR
        await sendRawCommand('ATL0\r'); // Linefeeds off with CR
        await sendRawCommand('ATS0\r'); // Spaces off with CR
        await sendRawCommand('ATH0\r'); // Headers off with CR
        await sendRawCommand('ATSP0\r'); // Auto protocol with CR
        
        // Try with both CR and LF
        await sendRawCommand('ATE0\r\n'); // Echo off with CRLF
        
        // Test if the adapter is responding correctly
        String testResponse = await sendRawCommand('0100\r');
        print('Test response: $testResponse');
        
        if (testResponse.startsWith('41')) {
          print('OBD-II communication successful');
        } else {
          print('OBD-II communication test failed, response: $testResponse');
          
          // Try again with explicit protocol
          await sendRawCommand('ATSP6\r'); // Try protocol 6 (ISO 15765-4 CAN)
          testResponse = await sendRawCommand('0100\r');
          print('Second test response: $testResponse');
          
          // Try with different line endings
          await sendRawCommand('ATSP0\r\n');
          testResponse = await sendRawCommand('0100\r\n');
          print('Third test response: $testResponse');
        }
      } else {
        // Try your custom device initialization
        print('Custom OBD adapter detected, trying generic initialization');
        _isStandardOBD = false;
        
        // Some adapters need a different initialization
        await sendRawCommand('ATD\r'); // Set defaults
        await sendRawCommand('ATZ\r'); // Reset
        await sendRawCommand('ATE0\r'); // Echo off
        await sendRawCommand('ATL0\r'); // Linefeeds off
        
        // Try with both CR and LF
        await sendRawCommand('ATE0\r\n'); // Echo off with CRLF
      }
    } catch (e) {
      print('Error initializing adapter: $e');
    }
  }
  
  Future<String> sendRawCommand(String command, {Duration? timeout}) async {
    if (!_isConnected || _writeCharacteristic == null || _readCharacteristic == null) {
      return 'Error: Not connected';
    }
    
    timeout ??= Duration(milliseconds: 1500);
    
    try {
      // Clear any pending data
      try {
        await _readCharacteristic!.read();
      } catch (e) {
        // Ignore errors from initial read
      }
      
      // Clear the response buffer
      _responseBuffer.clear();
      
      // Add carriage return if not already present
      String fullCommand = command;
      if (!command.endsWith('\r') && !command.endsWith('\r\n')) {
        fullCommand = '$command\r';
      }
      print('Sending command: $fullCommand');
      
      // Create a completer for this command
      _currentResponseCompleter = Completer<String>();
      
      // Send the command
      await _writeCharacteristic!.write(Uint8List.fromList(fullCommand.codeUnits));
      
      // If using notifications, wait for the response via the completer
      if (_readCharacteristic!.properties.notify) {
        return _currentResponseCompleter!.future.timeout(timeout, onTimeout: () {
          if (_currentResponseCompleter != null && !_currentResponseCompleter!.isCompleted) {
            _currentResponseCompleter!.complete('Timeout');
          }
          return 'Timeout';
        });
      } 
      // Otherwise, use polling to read the response
      else {
        // Wait a bit for the device to process
        await Future.delayed(Duration(milliseconds: 500));
        
        // Read the response
        List<int> response = await _readCharacteristic!.read();
        String responseStr = String.fromCharCodes(response).trim();
        print('Read response: $responseStr');
        
        // If we got back the command we sent, it's an echo - try reading again
        if (responseStr.startsWith(command.split('\r')[0]) || responseStr.isEmpty) {
          await Future.delayed(Duration(milliseconds: 500));
          response = await _readCharacteristic!.read();
          responseStr = String.fromCharCodes(response).trim();
          print('Second read response: $responseStr');
          
          // Try one more time with a longer delay
          if (responseStr.isEmpty || responseStr.startsWith(command.split('\r')[0])) {
            await Future.delayed(Duration(milliseconds: 1000));
            response = await _readCharacteristic!.read();
            responseStr = String.fromCharCodes(response).trim();
            print('Third read response: $responseStr');
          }
        }
        
        return responseStr;
      }
    } catch (e) {
      print('Error sending command: $e');
      return 'Error: $e';
    }
  }
  
  Future<String> sendCommand(String command) async {
    // For OBD-II commands, we need to handle multi-line responses
    String response = await sendRawCommand(command);
    
    // If we got back the command we sent, it's an echo - try a different approach
    if (response.startsWith(command.split(' ')[0]) || response.isEmpty) {
      print('Received echo or empty response, trying with explicit CR and longer timeout');
      
      // Try with explicit CR and longer timeout
      response = await sendRawCommand('$command\r', timeout: Duration(milliseconds: 2000));
      
      // If still getting echo, try with CRLF
      if (response.startsWith(command.split(' ')[0]) || response.isEmpty) {
        print('Still receiving echo, trying with CRLF');
        response = await sendRawCommand('$command\r\n', timeout: Duration(milliseconds: 2000));
      }
    }
    
    // Some adapters return multiple lines, we need to join them
    if (response.contains('\r') || response.contains('\n')) {
      List<String> lines = response.split(RegExp(r'[\r\n]+'))
          .where((line) => line.isNotEmpty)
          .toList();
      
      // Find the actual response line (usually starts with 4)
      for (String line in lines) {
        if (line.startsWith('4') || line.startsWith('7')) {
          return line;
        }
      }
      
      // If no valid response line found, return the whole response
      return response;
    }
    
    return response;
  }
  
  Future<dynamic> getSensorValue(String sensorKey) async {
    if (!OBDProtocol.commands.containsKey(sensorKey)) {
      return 'Unknown sensor';
    }
    
    OBDCommand command = OBDProtocol.commands[sensorKey]!;
    
    // Try up to 3 times to get a valid response
    for (int i = 0; i < 3; i++) {
      String response = await sendCommand(command.command);
      
      if (response == 'Error' || response.contains('ERROR') || 
          response.contains('?') || response == 'Timeout') {
        print('Invalid response for $sensorKey: $response, attempt ${i+1}/3');
        if (i == 2) return 'N/A'; // Give up after 3 attempts
        await Future.delayed(Duration(milliseconds: 500));
        continue;
      }
      
      // If we got back the command we sent, it's an echo - try a different approach
      if (response.startsWith(command.command.split(' ')[0])) {
        print('Received command echo for $sensorKey, attempt ${i+1}/3');
        if (i == 2) return 'N/A'; // Give up after 3 attempts
        await Future.delayed(Duration(milliseconds: 500));
        continue;
      }
      
      // We got a valid response
      return command.calculator(response);
    }
    
    return 'N/A';
  }
  
  void disconnect() {
    if (_isConnected) {
      _notificationSubscription?.cancel();
      _responseTimer?.cancel();
      _responseStreamController.close();
      device.disconnect();
      _isConnected = false;
    }
  }
  
  bool get isConnected => _isConnected;
  bool get isStandardOBD => _isStandardOBD;
}

