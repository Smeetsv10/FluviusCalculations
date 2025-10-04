import 'package:flutter/material.dart';
import 'package:fluvius_calculations_flutter/classes/myBattery.dart';
import 'package:fluvius_calculations_flutter/classes/myGridData.dart';

class House extends ChangeNotifier {
  String location = '';
  double injection_price = 0.05; // (€/kWh)
  double price_per_kWh = 0.35; // (€/kWh)
  Battery battery = Battery();
  GridData grid_data = GridData();

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
}
