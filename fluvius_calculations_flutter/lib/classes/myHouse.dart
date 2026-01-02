import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluvius_calculations_flutter/classes/myBattery.dart';
import 'package:fluvius_calculations_flutter/classes/myGridData.dart';
import 'package:intl/intl.dart';

class House extends ChangeNotifier {
  String location = '';
  double injection_price = 0.05; // (€/kWh)
  double price_per_kWh = 0.35; // (€/kWh)
  Battery battery = Battery();
  GridData grid_data = GridData();

  List<double> import_energy_history =
      []; // List to store import energy history
  List<double> export_energy_history =
      []; // List to store export energy history
  double import_cost = 0.0;
  double export_revenue = 0.0;
  double energy_cost = 0.0;
  double optimal_battery_capacity = 0.0;
  List<double> capacity_array = [];
  List<double> savings_list = [];
  List<double> annualized_battery_cost_array = [];

  void updateParameters({
    String? newLocation,
    double? newInjectionPrice,
    double? newPricePerKWh,
    Battery? newBattery,
    GridData? newGridData,
    List<double>? newImportEnergyHistory,
    List<double>? newExportEnergyHistory,
    double? newImportCost,
    double? newExportRevenue,
    double? newEnergyCost,
    double? newOptimalBatteryCapacity,
    List<double>? capacity_array,
    List<double>? savings_list,
    List<double>? annualized_battery_cost_array,
    String? newBase64Image,
  }) {
    if (newLocation != null) {
      location = newLocation;
    }
    if (newInjectionPrice != null) {
      injection_price = newInjectionPrice;
    }
    if (newPricePerKWh != null) {
      price_per_kWh = newPricePerKWh;
    }
    if (newBattery != null) {
      battery = newBattery;
    }
    if (newGridData != null) {
      grid_data = newGridData;
    }
    if (newImportEnergyHistory != null) {
      import_energy_history = newImportEnergyHistory;
    }
    if (newExportEnergyHistory != null) {
      export_energy_history = newExportEnergyHistory;
    }
    if (newImportCost != null) {
      import_cost = newImportCost;
    }
    if (newExportRevenue != null) {
      export_revenue = newExportRevenue;
    }
    if (newEnergyCost != null) {
      energy_cost = newEnergyCost;
    }
    if (newOptimalBatteryCapacity != null) {
      optimal_battery_capacity = newOptimalBatteryCapacity;
    }
    if (capacity_array != null) {
      capacity_array = capacity_array;
    }
    if (savings_list != null) {
      savings_list = savings_list;
    }
    if (annualized_battery_cost_array != null) {
      annualized_battery_cost_array = annualized_battery_cost_array;
    }
    notifyListeners();
  }

  // Battery Management System methods
  Map<String, double> batteryManagementSystem(
    double remainingEnergy,
    DateTime currentTime,
  ) {
    return greedyBatteryManagementSystem(remainingEnergy);
    // return dynamicBatteryManagementSystem(remainingEnergy, currentTime);
  }

  Map<String, double> greedyBatteryManagementSystem(double remainingEnergy) {
    double releasedEnergy = 0;
    double storedEnergy = 0;

    if (remainingEnergy > 0) {
      // Discharge battery
      releasedEnergy = battery.releaseEnergy(remainingEnergy);
    } else {
      // Charge battery
      storedEnergy = battery.storeEnergy(-remainingEnergy);
    }

    return {'released': releasedEnergy, 'stored': storedEnergy};
  }

  Map<String, double> dynamicBatteryManagementSystem(
    double remainingEnergy,
    DateTime currentTime,
  ) {
    double releasedEnergy = 0;
    double storedEnergy = 0;

    // If surplus -> charge
    if (remainingEnergy <= 0) {
      storedEnergy = battery.storeEnergy(-remainingEnergy);
    }
    // If deficit and SOC > reserve threshold -> discharge
    else if (remainingEnergy > 0 &&
        battery.SOC > battery.reserveSoc(currentTime)) {
      releasedEnergy = battery.releaseEnergy(remainingEnergy);
    }
    // If deficit and SOC ≤ reserve -> cautious strategy
    else if (remainingEnergy > 0 &&
        battery.SOC <= battery.reserveSoc(currentTime)) {
      final threshold = battery.dynamicThreshold(remainingEnergyHistory());
      if (remainingEnergy > threshold) {
        releasedEnergy = battery.releaseEnergy(
          remainingEnergy * 0.5,
        ); // Conservative discharge
      }
      // Else: Don't discharge, preserve battery for critical needs
    }

    return {'released': releasedEnergy, 'stored': storedEnergy};
  }

  List<double> remainingEnergyHistory() {
    final List<double> remaining = [];
    for (
      int i = 0;
      i < import_energy_history.length && i < export_energy_history.length;
      i++
    ) {
      remaining.add(import_energy_history[i] - export_energy_history[i]);
    }
    return remaining;
  }

  // Main simulation method
  Map<String, dynamic> simulateHousehold() {
    if (grid_data.processedData.isEmpty) {
      return {
        'success': false,
        'message':
            'No processed data available. Please load and process CSV data first.',
      };
    }

    // Reset simulation data
    import_energy_history.clear();
    export_energy_history.clear();
    battery.SOC_history.clear();
    battery.start_date = grid_data.start_date;
    battery.end_date = grid_data.end_date;
    import_cost = 0;
    export_revenue = 0;
    energy_cost = 0;

    try {
      for (final dataPoint in grid_data.processedData) {
        final remainingEnergy =
            dataPoint.volume_afname_kwh - dataPoint.volume_injectie_kwh;

        // Battery management
        double remainingRequired = 0;
        double remainingExcess = 0;

        final bmsResult = batteryManagementSystem(
          remainingEnergy,
          dataPoint.datetime,
        );
        final releasedEnergy = bmsResult['released'] ?? 0;
        final storedEnergy = bmsResult['stored'] ?? 0;

        if (remainingEnergy > 0) {
          // Energy deficit - need to import from grid
          remainingRequired = remainingEnergy - releasedEnergy;
          if (remainingRequired < 0) {
            remainingRequired = 0; // Can't be negative
          }
        } else {
          // Energy surplus - may export to grid
          remainingExcess = (-remainingEnergy) - storedEnergy;
          if (remainingExcess < 0) remainingExcess = 0; // Can't be negative
        }

        // Save history
        import_energy_history.add(remainingRequired);
        export_energy_history.add(remainingExcess);
        battery.SOC_history.add(battery.SOC);
      }

      // Calculate costs
      _calculateCosts();

      notifyListeners();

      return {
        'success': true,
        'import_energy': import_energy_history,
        'export_energy': export_energy_history,
        'soc_history': battery.SOC_history,
        'import_cost': import_cost,
        'export_revenue': export_revenue,
        'energy_cost': energy_cost,
        'message': 'Simulation completed successfully',
      };
    } catch (e) {
      return {'success': false, 'message': 'Simulation failed: $e'};
    }
  }

  void _calculateCosts() {
    import_cost = import_energy_history.fold(
      0.0,
      (sum, energy) => sum + energy * price_per_kWh,
    );
    export_revenue = export_energy_history.fold(
      0.0,
      (sum, energy) => sum + energy * injection_price,
    );
    energy_cost = import_cost - export_revenue;
  }

  // Cost calculation method
  double annualizedCostFunction() {
    if (grid_data.processedData.isEmpty) return 0;

    final firstTime = grid_data.processedData.first.datetime;
    final lastTime = grid_data.processedData.last.datetime;
    final timeSpanDays = lastTime.difference(firstTime).inDays.toDouble();

    if (timeSpanDays <= 0) return 0;

    final annualizedEnergyCost = (energy_cost / timeSpanDays) * 365;
    final annualizedBatteryCost =
        battery.batteryCost() / battery.battery_lifetime;

    return annualizedEnergyCost + annualizedBatteryCost;
  }

  // Optimization
  Map<String, dynamic> optimizeBatteryCapacity({
    double minCapacity = 0.0,
    double maxCapacity = 20.0,
    double stepSize = 1,
  }) {
    try {
      capacity_array.clear();
      savings_list.clear();
      annualized_battery_cost_array.clear();

      double bestCapacity = minCapacity;
      double lowestCost = double.infinity;

      for (
        double capacity = minCapacity;
        capacity <= maxCapacity;
        capacity += stepSize
      ) {
        battery.max_capacity = capacity;
        simulateHousehold();
        final totalCost = annualizedCostFunction();

        capacity_array.add(capacity);
        annualized_battery_cost_array.add(
          battery.batteryCost() / battery.battery_lifetime,
        );
        savings_list.add(annualizedCostFunction());

        if (totalCost < lowestCost) {
          lowestCost = totalCost;
          bestCapacity = capacity;
        }
      }

      optimal_battery_capacity = bestCapacity;
      notifyListeners();

      return {
        'success': true,
        'optimal_capacity': bestCapacity,
        'lowest_annualized_cost': lowestCost,
        'message': 'Optimization completed successfully',
      };
    } catch (e) {
      return {'success': false, 'message': 'Simulation failed: $e'};
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'injection_price': injection_price,
      'price_per_kWh': price_per_kWh,
      'battery': battery.toJson(),
      'grid_data': grid_data.toJson(),
    };
  }
}
