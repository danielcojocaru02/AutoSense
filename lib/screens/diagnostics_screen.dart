import 'package:flutter/material.dart';
import 'dart:async';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({Key? key}) : super(key: key);

  @override
  _DiagnosticsScreenState createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  bool _isConnected = false;
  String _connectionStatus = 'Disconnected';
  Map<String, String> _diagnosticData = {};

  Future<void> _connectToOBD() async {
    // TODO: Implement actual OBD-II Bluetooth connection logic
    setState(() {
      _isConnected = true;
      _connectionStatus = 'Connected';
    });
    _simulateDiagnosticData();
  }

  void _simulateDiagnosticData() {
    // This is a placeholder for real OBD-II data
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isConnected) {
        timer.cancel();
        return;
      }
      setState(() {
        _diagnosticData = {
          'Engine RPM': '${1000 + (DateTime.now().second * 50)}',
          'Vehicle Speed': '${DateTime.now().second} km/h',
          'Coolant Temp': '${80 + (DateTime.now().second % 20)}°C',
          'Battery Voltage': '${12 + (DateTime.now().millisecond / 1000)} V',
        };
      });
    });
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
              Text(
                'Diagnostics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildConnectionStatus(),
              const SizedBox(height: 20),
              _buildConnectButton(),
              const SizedBox(height: 20),
              Expanded(child: _buildDiagnosticInfo()),
            ],
          ),
        ),
      ),
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
        children: [
          Icon(
            _isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
            color: _isConnected ? const Color(0xFFF97316) : Colors.grey,
          ),
          const SizedBox(width: 16),
          Text(
            _connectionStatus,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
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
        backgroundColor: const Color(0xFFF97316),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Center(
        child: Text(
          _isConnected ? 'Connected' : 'Connect to OBD-II',
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
}

