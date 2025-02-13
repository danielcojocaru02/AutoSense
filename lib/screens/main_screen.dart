import 'package:flutter/material.dart';
import './dashboard_screen.dart';
import './diagnostics_screen.dart';
import './add_car_screen.dart';

class MainScreen extends StatefulWidget {
  final String? carMake;
  final String? carModel;
  final String? carYear;
  final String? carEngine;
  final String? carTransmission;
  final String? carPower;

  const MainScreen({
    Key? key,
    this.carMake,
    this.carModel,
    this.carYear,
    this.carEngine,
    this.carTransmission,
    this.carPower,
  }) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(
        carMake: widget.carMake,
        carModel: widget.carModel,
        carYear: widget.carYear,
        carEngine: widget.carEngine,
        carTransmission: widget.carTransmission,
        carPower: widget.carPower,
      ),
      const DiagnosticsScreen(),
      const AddCarScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Diagnostics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Add Car',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: _onItemTapped,
      ),
    );
  }
}

