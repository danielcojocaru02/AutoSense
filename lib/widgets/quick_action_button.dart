import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Widget buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickActionButton(Icons.directions_car, 'Status'),
          _buildQuickActionButton(Icons.thermostat, 'Climate'),
          _buildQuickActionButton(Icons.power_settings_new, 'Power'),
          _buildQuickActionButton(Icons.settings, 'Settings'),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(IconData icon, String label) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF27272A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFF97316)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }