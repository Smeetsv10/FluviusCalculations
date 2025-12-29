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

  String get base64Figure {
    if (import_energy_history.isEmpty || export_energy_history.isEmpty) {
      return '';
    }

    try {
      // Overall dimensions
      const int width = 1000;
      const int height = 600;
      const double padding = 60.0;
      const double graphWidth = width - 2 * padding;
      const double graphHeight = height - 2 * padding;

      // Create SVG string
      final StringBuffer svg = StringBuffer();
      svg.writeln('<?xml version="1.0" encoding="UTF-8"?>');
      svg.writeln(
        '<svg width="$width" height="$height" xmlns="http://www.w3.org/2000/svg">',
      );

      // Background
      svg.writeln('<rect width="$width" height="$height" fill="white"/>');

      // Title
      svg.writeln(
        '<text x="${width / 2}" y="30" font-size="20" font-weight="bold" text-anchor="middle" fill="black">Simulation results</text>',
      );

      // Y-axis label
      svg.writeln(
        '<text x="15" y="${height / 2}" font-size="14" text-anchor="middle" transform="rotate(-90, 15, ${height / 2})" fill="black">Energy (kWh)</text>',
      );

      // X-axis label
      svg.writeln(
        '<text x="${width / 2}" y="${height - 5}" font-size="14" text-anchor="middle" fill="black">Datetime (15min)</text>',
      );

      // Find max for plot
      double maxImport = import_energy_history.isEmpty
          ? 1
          : import_energy_history.reduce((a, b) => a > b ? a : b);
      double maxExport = export_energy_history.isEmpty
          ? 1
          : export_energy_history.reduce((a, b) => a > b ? a : b);
      double maxEnergy = maxImport > maxExport ? maxImport : maxExport;
      if (maxEnergy == 0) maxEnergy = 1;

      // Draw axes
      svg.writeln(
        '<line x1="$padding" y1="${height - padding}" x2="${width - padding}" y2="${height - padding}" stroke="black" stroke-width="2"/>',
      );
      svg.writeln(
        '<line x1="$padding" y1="$padding" x2="$padding" y2="${height - padding}" stroke="black" stroke-width="2"/>',
      );

      // Y-axis ticks and labels
      for (int i = 0; i <= 5; i++) {
        double yVal = (maxEnergy / 5) * i;
        double yPos = height - padding - (i / 5) * graphHeight;
        svg.writeln(
          '<line x1="${padding - 5}" y1="$yPos" x2="$padding" y2="$yPos" stroke="black" stroke-width="1"/>',
        );
        svg.writeln(
          '<text x="${padding - 10}" y="${yPos + 5}" font-size="12" text-anchor="end" fill="black">${yVal.toStringAsFixed(2)}</text>',
        );
      }

      // X-axis ticks and labels
      for (int i = 0; i <= 5; i++) {
        double xPos = padding + (i / 5) * graphWidth;
        int dataIndex = ((i / 5) * (import_energy_history.length - 1)).toInt();
        svg.writeln(
          '<line x1="$xPos" y1="${height - padding}" x2="$xPos" y2="${height - padding + 5}" stroke="black" stroke-width="1"/>',
        );
      }

      // Date range on X-axis
      final startDateStr = DateFormat(
        'dd/MM/yy HH:mm',
      ).format(grid_data.start_date);
      final endDateStr = DateFormat(
        'dd/MM/yy HH:mm',
      ).format(grid_data.end_date);
      svg.writeln(
        '<text x="$padding" y="${height - 5}" font-size="12" text-anchor="start" fill="black">$startDateStr</text>',
      );
      svg.writeln(
        '<text x="${width - padding}" y="${height - 5}" font-size="12" text-anchor="end" fill="black">$endDateStr</text>',
      );

      // Plot lines
      if (import_energy_history.length > 1) {
        StringBuffer pathImport = StringBuffer('M ');
        StringBuffer pathExport = StringBuffer('M ');

        for (int i = 0; i < import_energy_history.length; i++) {
          final x =
              padding + (i / (import_energy_history.length - 1)) * graphWidth;
          final yImport =
              height -
              padding -
              (import_energy_history[i] / maxEnergy) * graphHeight;
          final yExport =
              height -
              padding -
              (export_energy_history[i] / maxEnergy) * graphHeight;

          if (i == 0) {
            pathImport.write('$x $yImport ');
            pathExport.write('$x $yExport ');
          } else {
            pathImport.write('L $x $yImport ');
            pathExport.write('L $x $yExport ');
          }
        }

        svg.writeln(
          '<path d="$pathImport" fill="none" stroke="green" stroke-width="2" opacity="0.7"/>',
        );
        svg.writeln(
          '<path d="$pathExport" fill="none" stroke="orange" stroke-width="2" opacity="0.7"/>',
        );
      }

      // Draw data points (sampled for large datasets)
      for (int i = 0; i < import_energy_history.length; i++) {
        if (i % (import_energy_history.length ~/ 100 + 1) == 0) {
          final x =
              padding +
              (i /
                      (import_energy_history.length - 1 > 0
                          ? import_energy_history.length - 1
                          : 1)) *
                  graphWidth;
          final yImport =
              height -
              padding -
              (import_energy_history[i] / maxEnergy) * graphHeight;
          final yExport =
              height -
              padding -
              (export_energy_history[i] / maxEnergy) * graphHeight;

          svg.writeln(
            '<circle cx="$x" cy="$yImport" r="3" fill="green" opacity="0.6"/>',
          );
          svg.writeln(
            '<circle cx="$x" cy="$yExport" r="3" fill="orange" opacity="0.6"/>',
          );
        }
      }

      // Legend
      const legendX = width - 250.0;
      const legendY = 60.0;
      svg.writeln(
        '<rect x="$legendX" y="$legendY" width="220" height="70" fill="white" stroke="black" stroke-width="1"/>',
      );
      svg.writeln(
        '<line x1="${legendX + 10}" y1="${legendY + 20}" x2="${legendX + 40}" y2="${legendY + 20}" stroke="green" stroke-width="3"/>',
      );
      svg.writeln(
        '<text x="${legendX + 50}" y="${legendY + 25}" font-size="14" fill="black">Import Energy</text>',
      );
      svg.writeln(
        '<line x1="${legendX + 10}" y1="${legendY + 50}" x2="${legendX + 40}" y2="${legendY + 50}" stroke="orange" stroke-width="3"/>',
      );
      svg.writeln(
        '<text x="${legendX + 50}" y="${legendY + 55}" font-size="14" fill="black">Export Energy</text>',
      );

      svg.writeln('</svg>');

      // Encode SVG to base64
      final svgBytes = utf8.encode(svg.toString());
      return base64Encode(svgBytes);
    } catch (e) {
      print('Error generating base64Figure: $e');
      return '';
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
