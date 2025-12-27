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

  // Battery utility methods
  double batteryCost() {
    return variable_cost * max_capacity + fixed_costs;
  }

  double currentCapacity() {
    return SOC * max_capacity;
  }

  double availableCapacity() {
    return max_capacity - currentCapacity();
  }

  double maxChargeRate() {
    return C_rate * max_capacity;
  }

  double reserveSoc(DateTime currentTime) {
    final hour = currentTime.hour;
    if (hour >= 17 && hour < 20) {
      // Evening peak
      return 0.5;
    } else if (hour >= 0 && hour < 6) {
      // Night + morning peak
      return 0.25;
    } else {
      // Daytime
      return 0.05;
    }
  }

  double dynamicThreshold(List<double> loadHistory) {
    if (loadHistory.isEmpty) return 0.0;

    // Take last day (24 * 4 = 96 quarters) or all available data
    final startIndex = (loadHistory.length - 96).clamp(0, loadHistory.length);
    final recentLoad = loadHistory.sublist(startIndex);

    final avgLoad = recentLoad.reduce((a, b) => a + b) / recentLoad.length;
    return 0.15 * avgLoad; // 15% of avg load
  }

  double storeEnergy(double energy) {
    if (max_capacity <= 0) return 0;

    // Apply efficiency during charging
    final energyIn = energy * efficiency;

    final chargeLimit = [
      maxChargeRate(),
      availableCapacity(),
    ].reduce((a, b) => a < b ? a : b);
    final storableEnergy = [
      energyIn,
      chargeLimit,
    ].reduce((a, b) => a < b ? a : b);

    _SOC += storableEnergy / max_capacity;
    return storableEnergy / efficiency; // Return original input energy used
  }

  double releaseEnergy(double energy) {
    if (max_capacity <= 0) return 0;

    final dischargeLimit = [
      maxChargeRate(),
      currentCapacity(),
    ].reduce((a, b) => a < b ? a : b);
    final releasableEnergy = [
      energy,
      dischargeLimit,
    ].reduce((a, b) => a < b ? a : b);

    _SOC -= releasableEnergy / max_capacity;
    return releasableEnergy * efficiency; // Energy actually delivered to load
  }

  Map<String, dynamic> toJson() {
    return {
      'max_capacity': max_capacity,
      'efficiency': efficiency,
      'SOC': SOC,
      'variable_cost': variable_cost,
      'fixed_costs': fixed_costs,
      'battery_lifetime': battery_lifetime,
      'C_rate': C_rate,
    };
  }
}
