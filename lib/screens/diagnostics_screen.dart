import 'package:flutter/material.dart';
import '../services/obd_service.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../services/permission_service.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  _DiagnosticsScreenState createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  final OBDService _obdService = OBDService();
  bool _isConnected = false;
  String _connectionStatus = 'Disconnected';
  Map<String, String> _diagnosticData = {};
  Set<String> _selectedSensors = {
    'Engine RPM',
    'Vehicle Speed',
    'Coolant Temperature',
    'Intake Pressure',
    'MAF Sensor',
    'O2 Voltage'
  };

  Future<void> _connectToOBD() async {
    bool permissionsGranted = await PermissionService.requestPermissions();
    
    if (!permissionsGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bluetooth and Location permissions are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final BluetoothDevice? selectedDevice = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DeviceListScreen(),
      ),
    );

    if (selectedDevice != null) {
      final bool connected = await _obdService.connect(selectedDevice.address);
      setState(() {
        _isConnected = connected;
        _connectionStatus = connected ? 'Connected' : 'Connection failed';
      });

      if (connected) {
        _obdService.dataStream.listen((data) {
          setState(() {
            _diagnosticData = data;
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _obdService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OBD-II Diagnostics'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildConnectionStatus(),
            const SizedBox(height: 16),
            _buildConnectButton(),
            const SizedBox(height: 16),
            Expanded(child: _buildDiagnosticInfo()),
            const SizedBox(height: 16),
            _buildSensorSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Text(
      _connectionStatus,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildConnectButton() {
    return ElevatedButton(
      onPressed: _isConnected ? null : _connectToOBD,
      child: Text(_isConnected ? 'Disconnect' : 'Connect to OBD-II'),
    );
  }

  Widget _buildDiagnosticInfo() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _selectedSensors.length,
      itemBuilder: (context, index) {
        String key = _selectedSensors.elementAt(index);
        String value = _diagnosticData[key] ?? 'N/A';
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF27272A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                key,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSensorSelector() {
    return ElevatedButton(
      onPressed: () async {
        final result = await showDialog<Set<String>>(
          context: context,
          builder: (BuildContext context) {
            return SensorSelectorDialog(
              availableSensors: _diagnosticData.keys.toSet(),
              selectedSensors: _selectedSensors,
            );
          },
        );
        if (result != null) {
          setState(() {
            _selectedSensors = result;
          });
        }
      },
      child: const Text('Select Sensors'),
    );
  }
}

class DeviceListScreen extends StatelessWidget {
  const DeviceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select OBD-II Device')),
      body: FutureBuilder(
        future: FlutterBluetoothSerial.instance.getBondedDevices(),
        builder: (context, AsyncSnapshot<List<BluetoothDevice>> snapshot) {
          if (snapshot.hasData) {
            return ListView(
              children: snapshot.data!.map((device) {
                return ListTile(
                  title: Text(device.name ?? "Unknown device"),
                  subtitle: Text(device.address),
                  onTap: () => Navigator.of(context).pop(device),
                );
              }).toList(),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class SensorSelectorDialog extends StatefulWidget {
  final Set<String> availableSensors;
  final Set<String> selectedSensors;

  const SensorSelectorDialog({
    super.key,
    required this.availableSensors,
    required this.selectedSensors,
  });

  @override
  _SensorSelectorDialogState createState() => _SensorSelectorDialogState();
}

class _SensorSelectorDialogState extends State<SensorSelectorDialog> {
  late Set<String> _selectedSensors;

  @override
  void initState() {
    super.initState();
    _selectedSensors = Set.from(widget.selectedSensors);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Sensors'),
      content: SingleChildScrollView(
        child: ListBody(
          children: widget.availableSensors.map((sensor) {
            return CheckboxListTile(
              title: Text(sensor),
              value: _selectedSensors.contains(sensor),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedSensors.add(sensor);
                  } else {
                    _selectedSensors.remove(sensor);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('OK'),
          onPressed: () => Navigator.of(context).pop(_selectedSensors),
        ),
      ],
    );
  }
}

