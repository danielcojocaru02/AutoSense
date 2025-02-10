import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class MainScreen extends StatefulWidget {
  final String carMake;
  final String carModel;
  final String carYear;
  final String carEngine;
  final String carTransmission;
  final String carPower;

  const MainScreen({
    super.key,
    required this.carMake,
    required this.carModel,
    required this.carYear,
    required this.carEngine,
    required this.carTransmission,
    required this.carPower,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            DashboardScreen(
              carMake: widget.carMake,
              carModel: widget.carModel,
              carYear: widget.carYear,
              carEngine: widget.carEngine,
              carTransmission: widget.carTransmission,
              carPower: widget.carPower,
            ),
            const Center(child: Text('Diagnostics Screen')),
            const Center(child: Text('Navigation Screen')),
            const Center(child: Text('Settings Screen')),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF18181B),
        selectedItemColor: const Color(0xFFF97316),
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.speed), label: 'Diagnostics'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Navigation'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}