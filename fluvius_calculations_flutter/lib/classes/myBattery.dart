import 'package:flutter/material.dart';

class Battery extends ChangeNotifier {
  double max_capacity = 0; // in kWh
  double efficiency = 0.95;
  double _SOC = 0.33; // Made private to control access through setter
  double fixed_costs = 1000; // in €
  double variable_cost = 700;
  int battery_lifetime = 10;
  double C_rate = 0.25;
  List<double> SOC_history = [];

  Battery() {
    if (efficiency < 0 || efficiency > 1) {
      throw ArgumentError('Efficiency must be between 0 and 1');
    }
    if (max_capacity < 0) {
      throw ArgumentError('Max capacity must be non-negative');
    }
  }

  // Getter for SOC
  double get SOC => _SOC;

  // Setter for SOC with validation
  set SOC(double value) {
    if (value < 0 || value > 1) {
      throw ArgumentError('SOC must be between 0 and 1 (0% to 100%)');
    }
    _SOC = value;
    // Optionally add to history when SOC changes
    SOC_history.add(value);
  }

  void updateParameters({
    double? newMaxCapacity,
    double? newEfficiency,
    double? newSOC,
    double? newFixedCosts,
    double? newVariableCost,
    int? newBatteryLifetime,
    double? newCRate,
    List<double>? newSOCHistory,
  }) {
    if (newMaxCapacity != null) {
      max_capacity = newMaxCapacity;
    }
    if (newEfficiency != null) {
      efficiency = newEfficiency;
    }
    if (newSOC != null) {
      SOC = newSOC;
    }
    if (newFixedCosts != null) {
      fixed_costs = newFixedCosts;
    }
    if (newVariableCost != null) {
      variable_cost = newVariableCost;
    }
    if (newBatteryLifetime != null) {
      battery_lifetime = newBatteryLifetime;
    }
    if (newCRate != null) {
      C_rate = newCRate;
    }
    if (newSOCHistory != null) {
      SOC_history = newSOCHistory;
    }
    notifyListeners();
  }

  Map<String, dynamic> toJson() {
    return {
      'max_capacity': max_capacity,
      'efficiency': efficiency,
      'SOC': SOC,
      'variable_cost': variable_cost,
      'battery_lifetime': battery_lifetime,
      'C_rate': C_rate,
    };
  }
}
