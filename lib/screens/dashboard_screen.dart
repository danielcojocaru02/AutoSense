import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  final String? carMake;
  final String? carModel;
  final String? carYear;
  final String? carEngine;
  final String? carTransmission;
  final String? carPower;

  const DashboardScreen({
    Key? key,
    this.carMake,
    this.carModel,
    this.carYear,
    this.carEngine,
    this.carTransmission,
    this.carPower,
  }) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime? _lastOilChange;
  int? _lastOilChangeMileage;
  int? _oilChangeInterval;
  int? _currentMileage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFF18181B),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCarInfoCard(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Maintenance Info',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            _buildMaintenanceInputs(),
            const SizedBox(height: 24),
            if (_lastOilChange != null &&
                _oilChangeInterval != null &&
                _currentMileage != null)
              _buildMaintenanceStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildCarInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3A3A3C), Color(0xFF2C2C2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.carYear ?? ''} ${widget.carMake ?? ''} ${widget.carModel ?? ''}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Engine', widget.carEngine),
            _buildInfoRow('Transmission', widget.carTransmission),
            _buildInfoRow('Power', widget.carPower),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value ?? 'Not specified',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceInputs() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      color: const Color(0xFF2C2C2E),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDatePicker(
              label: 'Last Oil Change',
              value: _lastOilChange,
              onChanged: (date) => setState(() => _lastOilChange = date),
            ),
            const SizedBox(height: 16),
            _buildNumberInput(
              label: 'Last Oil Change Mileage',
              value: _lastOilChangeMileage,
              onChanged: (value) => setState(() => _lastOilChangeMileage = value),
            ),
            const SizedBox(height: 16),
            _buildNumberInput(
              label: 'Oil Change Interval (miles)',
              value: _oilChangeInterval,
              onChanged: (value) => setState(() => _oilChangeInterval = value),
            ),
            const SizedBox(height: 16),
            _buildNumberInput(
              label: 'Current Mileage',
              value: _currentMileage,
              onChanged: (value) => setState(() => _currentMileage = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        TextButton(
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              onChanged(date);
            }
          },
          child: Text(
            value != null
                ? DateFormat('MMM d, yyyy').format(value)
                : 'Select Date',
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberInput({
    required String label,
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        SizedBox(
          width: 100,
          child: TextField(
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
            onChanged: (text) => onChanged(int.tryParse(text)),
            controller: TextEditingController(text: value?.toString() ?? ''),
          ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceStatus() {
  if (_lastOilChange == null || _oilChangeInterval == null || _currentMileage == null) {
    return const SizedBox(); // Avoid showing incomplete info
  }

  // User inputs
  int lastOilChangeMileage = _lastOilChangeMileage ?? 0;
  int oilChangeInterval = _oilChangeInterval ?? 0;
  int currentMileage = _currentMileage ?? 0;

  // Next oil change mileage
  int nextOilChangeMileage = lastOilChangeMileage + oilChangeInterval;
  int milesUntilNextChange = nextOilChangeMileage - currentMileage;

  // Next oil change date (1 year after last oil change)
  DateTime nextOilChangeDate = _lastOilChange!.add(const Duration(days: 365));
  int daysUntilNextChange = nextOilChangeDate.difference(DateTime.now()).inDays;

  return Card(
    margin: const EdgeInsets.all(16.0),
    color: const Color(0xFF2C2C2E),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Maintenance Status',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildStatusRow('Last Oil Change Mileage', '$lastOilChangeMileage miles'),
          _buildStatusRow('Next Oil Change Mileage', '$nextOilChangeMileage miles'),
          _buildStatusRow('Miles Until Next Change', '$milesUntilNextChange miles'),
          _buildStatusRow('Next Oil Change Date', DateFormat('MMM d, yyyy').format(nextOilChangeDate)),
          _buildStatusRow('Days Until Next Change', '$daysUntilNextChange days'),
        ],
      ),
    ),
  );
}




  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

