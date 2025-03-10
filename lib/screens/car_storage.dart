// First, let's create a car_storage.dart file to handle saving and loading car data

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Car {
  final String make;
  final String model;
  final String year;
  final String engine;
  final String transmission;
  final String power;

  Car({
    required this.make,
    required this.model,
    required this.year,
    required this.engine,
    required this.transmission,
    required this.power,
  });

  Map<String, dynamic> toJson() {
    return {
      'make': make,
      'model': model,
      'year': year,
      'engine': engine,
      'transmission': transmission,
      'power': power,
    };
  }

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      make: json['make'],
      model: json['model'],
      year: json['year'],
      engine: json['engine'],
      transmission: json['transmission'],
      power: json['power'],
    );
  }
}

class CarStorage {
  static const String _carKey = 'saved_car';

  // Save car data
  static Future<void> saveCar(Car car) async {
    final prefs = await SharedPreferences.getInstance();
    final carJson = jsonEncode(car.toJson());
    await prefs.setString(_carKey, carJson);
  }

  // Load car data
  static Future<Car?> loadCar() async {
    final prefs = await SharedPreferences.getInstance();
    final carJson = prefs.getString(_carKey);
    
    if (carJson == null) {
      return null;
    }
    
    try {
      final Map<String, dynamic> carMap = jsonDecode(carJson);
      return Car.fromJson(carMap);
    } catch (e) {
      print('Error loading car: $e');
      return null;
    }
  }

  // Check if car exists
  static Future<bool> hasSavedCar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_carKey);
  }

  // Delete car data
  static Future<void> deleteCar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_carKey);
  }
}