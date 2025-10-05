import 'package:flutter/material.dart';
import 'package:fluvius_calculations_flutter/classes/myBattery.dart';
import 'package:fluvius_calculations_flutter/classes/myGridData.dart';

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
    notifyListeners();
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
