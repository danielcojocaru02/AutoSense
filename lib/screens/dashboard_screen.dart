import 'package:flutter/material.dart';
import '/widgets/quick_action_button.dart';
import '/widgets/status_card.dart';



class DashboardScreen extends StatelessWidget {
  final String carMake;
  final String carModel;
  final String carYear;
  final String carEngine;
  final String carTransmission;
  final String carPower;

  const DashboardScreen({
    super.key,
    required this.carMake,
    required this.carModel,
    required this.carYear,
    required this.carEngine,
    required this.carTransmission,
    required this.carPower,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$carMake $carModel $carYear',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$carEngine, $carTransmission, $carPower',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Icon(Icons.notifications_outlined, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 24),
          // Main content
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildCarImage(),
                  const SizedBox(height: 24),
                  buildQuickActions(),
                  const SizedBox(height: 24),
                  buildStatusCards(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildCarImage() {
  return Padding(
    padding: const EdgeInsets.only(top: 20), // Padding de 20px deasupra imaginii
    child: Container(
      height: 270,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        image: DecorationImage(
          image: AssetImage('assets/land_cruiser_banner.png'),
          fit: BoxFit.cover,
        ),
      ),
    ),
  );
}
}