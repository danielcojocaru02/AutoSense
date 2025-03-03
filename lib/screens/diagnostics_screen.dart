import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io' show Platform;
import '../services/obd_service.dart';
import '../services/sensor_preferences.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({Key? key}) : super(key: key);
  @override
  _DiagnosticsScreenState createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  bool _isConnected = false;
  String _connectionStatus = 'Disconnected';
  Map<String, String> _diagnosticData = {};
  List<String> _selectedSensors = [];
  final OBDService _obdService = OBDService();
  StreamSubscription<BluetoothAdapterState>? _bluetoothStateSubscription;

  @override
  void initState() {
    super.initState();
    _loadSelectedSensors();
    _initializeBluetooth();
  }

  Future<void> _disconnect() async {
    try {
      _obdService.disconnect();
      setState(() {
        _isConnected = false;
        _connectionStatus = 'Disconnected';
        _diagnosticData.clear();
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'Disconnect error: ${e.toString()}';
      });
    }
  }

  Future<void> _initializeBluetooth() async {
    try {
      await FlutterBluePlus.turnOn();
      
      _bluetoothStateSubscription = FlutterBluePlus.adapterState.listen((state) {
        setState(() {
          if (state == BluetoothAdapterState.on) {
            _connectionStatus = 'Bluetooth Ready';
          } else {
            _connectionStatus = 'Bluetooth ${state.toString().split('.').last}';
            _isConnected = false;
          }
        });
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'Bluetooth initialization failed';
      });
    }
  }

  Future<void> _loadSelectedSensors() async {
    final sensors = await SensorPreferences.getSelectedSensors();
    setState(() {
      _selectedSensors = List<String>.from(sensors);
    });
  }

  Future<void> _connectToOBD() async {
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      try {
        await FlutterBluePlus.turnOn();
      } catch (e) {
        setState(() {
          _connectionStatus = 'Please enable Bluetooth manually';
        });
        return;
      }
    }

    setState(() {
      _connectionStatus = 'Checking permissions...';
    });

    bool permissionGranted = await _checkBluetoothPermissions();
    if (!permissionGranted) {
      setState(() {
        _connectionStatus = 'Bluetooth permission denied';
      });
      return;
    }

    setState(() {
      _connectionStatus = 'Scanning...';
    });

    try {
      await _showDeviceSelectionDialog();
    } catch (e) {
      setState(() {
        _connectionStatus = 'Scan failed: ${e.toString()}';
      });
    }
  }

  Future<bool> _checkBluetoothPermissions() async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      return statuses.values.every((status) => status.isGranted);
    }
    return true;
  }

  Future<void> _showDeviceSelectionDialog() async {
    List<ScanResult> deviceList = [];
    
    try {
      await FlutterBluePlus.startScan(timeout: Duration(seconds: 10));
    } catch (e) {
      throw Exception('Failed to start scan: $e');
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            FlutterBluePlus.scanResults.listen((results) {
              setStateDialog(() {
                deviceList = results;
              });
            });

            return AlertDialog(
              backgroundColor: const Color(0xFF27272A),
              title: Text('Select OBD Device', 
                style: TextStyle(color: Colors.white)),
              content: Container(
                height: 300,
                width: double.maxFinite,
                child: ListView.builder(
                  itemCount: deviceList.length,
                  itemBuilder: (context, index) {
                    ScanResult result = deviceList[index];
                    String deviceName = result.device.platformName.isNotEmpty
                        ? result.device.platformName
                        : 'Unknown device';
                    return ListTile(
                      title: Text(deviceName, 
                        style: TextStyle(color: Colors.white)),
                      subtitle: Text(result.device.remoteId.str,
                        style: TextStyle(color: Colors.grey)),
                      onTap: () async {
                        await FlutterBluePlus.stopScan();
                        Navigator.pop(context);
                        await _connectToSelectedDevice(result.device);
                      },
                    );
                  },
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel', 
                    style: TextStyle(color: const Color(0xFFF97316))),
                  onPressed: () {
                    FlutterBluePlus.stopScan();
                    Navigator.pop(context);
                    setState(() {
                      _connectionStatus = 'Disconnected';
                    });
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _connectToSelectedDevice(BluetoothDevice device) async {
    setState(() {
      _connectionStatus = 'Connecting...';
    });

    try {
      bool success = await _obdService.connect(device);
      setState(() {
        _isConnected = success;
        _connectionStatus = success 
            ? 'Connected to ${device.platformName}'
            : 'Connection failed';
      });

      if (success) {
        _startListeningToOBDData();
      }
    } catch (e) {
      setState(() {
        _isConnected = false;
        _connectionStatus = 'Connection error: ${e.toString()}';
      });
    }
  }

  void _startListeningToOBDData() {
    _obdService.dataStream.listen(
      (data) {
        setState(() {
          _diagnosticData = data;
        });
      },
      onError: (error) {
        setState(() {
          _connectionStatus = 'Data error: $error';
        });
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18181B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Diagnostics',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isConnected)
                    _buildConnectionMenu(),
                ],
              ),
              const SizedBox(height: 20),
              _buildConnectionStatus(),
              const SizedBox(height: 20),
              _buildConnectButton(),
              const SizedBox(height: 20),
              _buildSensorSelectionButton(),
              const SizedBox(height: 20),
              Expanded(child: _buildDiagnosticInfo()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionMenu() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.white),
      color: const Color(0xFF27272A),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'disconnect',
          child: Row(
            children: [
              Icon(Icons.bluetooth_disabled, color: Colors.white),
              SizedBox(width: 8),
              Text('Disconnect', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'reconnect',
          child: Row(
            children: [
              Icon(Icons.bluetooth_searching, color: Colors.white),
              SizedBox(width: 8),
              Text('Connect to Different Device', 
                style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
      onSelected: (String value) async {
        if (value == 'disconnect') {
          await _disconnect();
        } else if (value == 'reconnect') {
          await _disconnect();
          await _connectToOBD();
        }
      },
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF27272A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isConnected 
                      ? Icons.bluetooth_connected 
                      : Icons.bluetooth_disabled,
                  color: _isConnected 
                      ? const Color(0xFFF97316) 
                      : Colors.grey,
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    _connectionStatus,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (_isConnected)
            TextButton(
              onPressed: _disconnect,
              child: Text(
                'Disconnect',
                style: TextStyle(
                  color: const Color(0xFFF97316),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConnectButton() {
    return ElevatedButton(
      onPressed: _isConnected ? null : _connectToOBD,
      style: ElevatedButton.styleFrom(
        backgroundColor: _isConnected 
            ? Colors.grey 
            : const Color(0xFFF97316),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isConnected 
                  ? Icons.bluetooth_connected 
                  : Icons.bluetooth_searching,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              _isConnected 
                  ? 'Connected' 
                  : 'Connect to OBD-II',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorSelectionButton() {
    return ElevatedButton(
      onPressed: _showSensorSelectionDialog,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF27272A),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Center(
        child: Text(
          'Select Sensors',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDiagnosticInfo() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _diagnosticData.length,
      itemBuilder: (context, index) {
        String key = _diagnosticData.keys.elementAt(index);
        String value = _diagnosticData[key] ?? '';
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
                style: TextStyle(
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

  void _showSensorSelectionDialog() {
    List<String> tempSelectedSensors = List<String>.from(_selectedSensors);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF27272A),
          title: Text('Select Sensors',
            style: TextStyle(color: Colors.white)),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              tempSelectedSensors = 
                                SensorPreferences.allSensors.keys.toList();
                            });
                          },
                          child: Text('Select All',
                            style: TextStyle(color: const Color(0xFFF97316))),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              tempSelectedSensors.clear();
                            });
                          },
                          child: Text('Deselect All',
                            style: TextStyle(color: const Color(0xFFF97316))),
                        ),
                      ],
                    ),
                    Expanded(
                      child: ListView(
                        children: SensorPreferences.allSensors.entries.map((entry) {
                          return CheckboxListTile(
                            title: Text(entry.value,
                              style: TextStyle(color: Colors.white)),
                            value: tempSelectedSensors.contains(entry.key),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  tempSelectedSensors.add(entry.key);
                                } else {
                                  tempSelectedSensors.remove(entry.key);
                                }
                              });
                            },
                            checkColor: Colors.white,
                            activeColor: const Color(0xFFF97316),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel',
                style: TextStyle(color: const Color(0xFFF97316))),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save',
                style: TextStyle(color: const Color(0xFFF97316))),
              onPressed: () {
                setState(() {
                  _selectedSensors = tempSelectedSensors;
                });
                SensorPreferences.setSelectedSensors(_selectedSensors);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _disconnect();
    _bluetoothStateSubscription?.cancel();
    super.dispose();
  }
}

