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

  void handlePythonResponse(Map<String, dynamic> simulationResponse) {
    if (simulationResponse.containsKey('import_energy_history')) {
      import_energy_history = List<double>.from(
        simulationResponse['import_energy_history'],
      );
    }
    if (simulationResponse.containsKey('export_energy_history')) {
      export_energy_history = List<double>.from(
        simulationResponse['export_energy_history'],
      );
    }
    if (simulationResponse.containsKey('export_energy_history')) {
      export_energy_history = List<double>.from(
        simulationResponse['export_energy_history'],
      );
    }
    if (simulationResponse.containsKey('soc_history')) {
      battery.SOC_history = List<double>.from(
        simulationResponse['soc_history'],
      );
    }
    if (simulationResponse.containsKey('import_cost')) {
      import_cost = simulationResponse['import_cost'];
    }
    if (simulationResponse.containsKey('export_revenue')) {
      export_revenue = simulationResponse['export_revenue'];
    }
    if (simulationResponse.containsKey('energy_cost')) {
      energy_cost = simulationResponse['energy_cost'];
    }
    if (simulationResponse.containsKey('optimal_capacity')) {
      optimal_battery_capacity = simulationResponse['optimal_battery_capacity'];
    }
    notifyListeners();
  }
}
