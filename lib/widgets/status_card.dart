import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Widget buildStatusCards() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatusCard(
            'Engine Status',
            Icons.speed,
            progress: 72,
          ),
          const SizedBox(height: 16),
          _buildStatusCard(
            'Location',
            Icons.location_on,
            subtitle: '123 Main Street, Boston, MA',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, IconData icon, {double? progress, String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF27272A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFFF97316)),
                  const SizedBox(width: 12),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.grey[800],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF97316)),
            ),
          ],
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
