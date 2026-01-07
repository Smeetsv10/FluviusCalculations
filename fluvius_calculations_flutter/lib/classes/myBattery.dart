import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class CostPoint {
  double capacity; // kWh
  double price; // €

  CostPoint(this.capacity, this.price);

  Map<String, dynamic> toJson() => {'capacity': capacity, 'price': price};

  factory CostPoint.fromJson(Map<String, dynamic> json) =>
      CostPoint(json['capacity'], json['price']);
}

class Battery extends ChangeNotifier {
  // Initial default values for resetting
  static const double _INITIAL_MAX_CAPACITY = 10; // in kWh
  static const double _INITIAL_EFFICIENCY = 0.95;
  static const double _INITIAL_SOC0 = 0.33; // Initial State of Charge (0 to 1)
  static const double _INITIAL_FIXED_COSTS = 1000; // in €
  static const double _INITIAL_VARIABLE_COST = 700;
  static const int _INITIAL_BATTERY_LIFETIME = 10;
  static const double _INITIAL_C_RATE = 0.25;

  double max_capacity = _INITIAL_MAX_CAPACITY;
  double efficiency = _INITIAL_EFFICIENCY;
  double _SOC0 = _INITIAL_SOC0;
  late double _SOC = _SOC0;
  double fixed_costs = _INITIAL_FIXED_COSTS;
  double variable_cost = _INITIAL_VARIABLE_COST;
  int battery_lifetime = _INITIAL_BATTERY_LIFETIME;
  double C_rate = _INITIAL_C_RATE;
  List<double> SOC_history = [];
  DateTime? start_date;
  DateTime? end_date;

  // Piecewise linear cost model
  bool usePiecewiseCost = false;
  List<CostPoint> costPoints = [];

  Battery() {
    initializeParameters();
  }

  void initializeParameters() {
    max_capacity = _INITIAL_MAX_CAPACITY;
    efficiency = _INITIAL_EFFICIENCY;
    _SOC0 = _INITIAL_SOC0;
    _SOC = _SOC0;
    fixed_costs = _INITIAL_FIXED_COSTS;
    variable_cost = _INITIAL_VARIABLE_COST;
    battery_lifetime = _INITIAL_BATTERY_LIFETIME;
    C_rate = _INITIAL_C_RATE;
    SOC_history = [];
    start_date = null;
    end_date = null;
    usePiecewiseCost = false;
    costPoints = [CostPoint(0, 0), CostPoint(10, 8000)];

    if (efficiency < 0 || efficiency > 1) {
      throw ArgumentError('Efficiency must be between 0 and 1');
    }
    if (max_capacity < 0) {
      throw ArgumentError('Max capacity must be non-negative');
    }
    notifyListeners();
  }

  // Getter for SOC
  double get SOC0 => _SOC0;
  set SOC(double value) {
    if (value < 0) {
      _SOC = 0;
    } else if (value > 1) {
      _SOC = 1;
    } else {
      _SOC = value;
    }
    SOC_history.add(_SOC);
  }

  double get SOC => _SOC;

  void updateParameters({
    double? newMaxCapacity,
    double? newEfficiency,
    double? newSOC,
    double? newFixedCosts,
    double? newVariableCost,
    int? newBatteryLifetime,
    double? newCRate,
    List<double>? newSOCHistory,
    bool? newUsePiecewiseCost,
    List<CostPoint>? newCostPoints,
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
    if (newUsePiecewiseCost != null) {
      usePiecewiseCost = newUsePiecewiseCost;
    }
    if (newCostPoints != null) {
      costPoints = newCostPoints;
    }
    notifyListeners();
  }

  // Battery utility methods
  double batteryCost() {
    if (usePiecewiseCost && costPoints.length >= 2) {
      return _piecewiseLinearCost(max_capacity);
    }
    return variable_cost * max_capacity + fixed_costs;
  }

  double _piecewiseLinearCost(double capacity) {
    // Sort points by capacity
    final sortedPoints = List<CostPoint>.from(costPoints)
      ..sort((a, b) => a.capacity.compareTo(b.capacity));

    // If capacity is below first point, use first point price
    if (capacity <= sortedPoints.first.capacity) {
      return sortedPoints.first.price;
    }

    // If capacity is above last point, extrapolate from last segment
    if (capacity >= sortedPoints.last.capacity) {
      final last = sortedPoints.last;
      final secondLast = sortedPoints[sortedPoints.length - 2];
      final slope =
          (last.price - secondLast.price) /
          (last.capacity - secondLast.capacity);
      return last.price + slope * (capacity - last.capacity);
    }

    // Find the two points to interpolate between
    for (int i = 0; i < sortedPoints.length - 1; i++) {
      final p1 = sortedPoints[i];
      final p2 = sortedPoints[i + 1];

      if (capacity >= p1.capacity && capacity <= p2.capacity) {
        // Linear interpolation
        final slope = (p2.price - p1.price) / (p2.capacity - p1.capacity);
        return p1.price + slope * (capacity - p1.capacity);
      }
    }

    return fixed_costs + variable_cost * capacity;
  }

  double currentCapacity() {
    return _SOC * max_capacity;
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
    // Input is the excess energy available for charging
    // Output is the energy actually stored in the battery
    if (max_capacity <= 0) return 0;

    // Apply efficiency during charging, only a fraction of input energy is stored
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
    return storableEnergy / efficiency;
  }

  double releaseEnergy(double energy) {
    // Input is the remaining energy required by the load
    // Output is the energy released by the battery
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
    return releasableEnergy; // Do not apply energy during discharge, otherwiase BMS would not be working correctly
  }

  Map<String, dynamic> toJson() {
    return {
      'max_capacity': max_capacity,
      'efficiency': efficiency,
      'SOC': _SOC,
      'variable_cost': variable_cost,
      'fixed_costs': fixed_costs,
      'battery_lifetime': battery_lifetime,
      'C_rate': C_rate,
    };
  }

  String get base64Figure {
    if (SOC_history.isEmpty) {
      return '';
    }

    try {
      // Image dimensions
      const int width = 1000;
      const int height = 600;
      const double padding = 60.0;
      const double graphWidth = width - 2 * padding;
      const double graphHeight = height - 2 * padding;

      // Find max SOC
      double maxSOC = SOC_history.reduce((a, b) => a > b ? a : b);
      if (maxSOC == 0) maxSOC = 1;

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
        '<text x="${width / 2}" y="30" font-size="20" font-weight="bold" text-anchor="middle" fill="black">Battery State of Charge</text>',
      );

      // Y-axis label
      svg.writeln(
        '<text x="15" y="${height / 2}" font-size="14" text-anchor="middle" transform="rotate(-90, 15, ${height / 2})" fill="black">SOC (%)</text>',
      );

      // X-axis label
      svg.writeln(
        '<text x="${width / 2}" y="${height - 5}" font-size="14" text-anchor="middle" fill="black">Datetime (15min)</text>',
      );

      // Draw axes
      svg.writeln(
        '<line x1="$padding" y1="${height - padding}" x2="${width - padding}" y2="${height - padding}" stroke="black" stroke-width="2"/>',
      );
      svg.writeln(
        '<line x1="$padding" y1="$padding" x2="$padding" y2="${height - padding}" stroke="black" stroke-width="2"/>',
      );

      // Y-axis ticks and labels (0-100%)
      for (int i = 0; i <= 5; i++) {
        double yVal = (100.0 / 5) * i;
        double yPos = height - padding - (i / 5) * graphHeight;
        svg.writeln(
          '<line x1="${padding - 5}" y1="$yPos" x2="$padding" y2="$yPos" stroke="black" stroke-width="1"/>',
        );
        svg.writeln(
          '<text x="${padding - 10}" y="${yPos + 5}" font-size="12" text-anchor="end" fill="black">${yVal.toStringAsFixed(0)}%</text>',
        );
      }

      // X-axis ticks
      for (int i = 0; i <= 5; i++) {
        double xPos = padding + (i / 5) * graphWidth;
        svg.writeln(
          '<line x1="$xPos" y1="${height - padding}" x2="$xPos" y2="${height - padding + 5}" stroke="black" stroke-width="1"/>',
        );
      }

      // Date range on X-axis
      if (start_date != null && end_date != null) {
        final startDateStr = DateFormat('dd/MM/yy HH:mm').format(start_date!);
        final endDateStr = DateFormat('dd/MM/yy HH:mm').format(end_date!);
        svg.writeln(
          '<text x="$padding" y="${height - padding + 20}" font-size="12" text-anchor="start" fill="black">$startDateStr</text>',
        );
        svg.writeln(
          '<text x="${width - padding}" y="${height - padding + 20}" font-size="12" text-anchor="end" fill="black">$endDateStr</text>',
        );
      }

      // Plot line
      if (SOC_history.length > 1) {
        StringBuffer pathSOC = StringBuffer('M ');

        for (int i = 0; i < SOC_history.length; i++) {
          final x = padding + (i / (SOC_history.length - 1)) * graphWidth;
          final ySOC =
              height - padding - (SOC_history[i] * 100 / 100) * graphHeight;

          if (i == 0) {
            pathSOC.write('$x $ySOC ');
          } else {
            pathSOC.write('L $x $ySOC ');
          }
        }

        svg.writeln(
          '<path d="$pathSOC" fill="none" stroke="purple" stroke-width="2" opacity="0.7"/>',
        );
      }

      // Draw data points (sampled for large datasets)
      for (int i = 0; i < SOC_history.length; i++) {
        if (i % (SOC_history.length ~/ 100 + 1) == 0) {
          final x =
              padding +
              (i / (SOC_history.length - 1 > 0 ? SOC_history.length - 1 : 1)) *
                  graphWidth;
          final ySOC =
              height - padding - (SOC_history[i] * 100 / 100) * graphHeight;

          svg.writeln(
            '<circle cx="$x" cy="$ySOC" r="3" fill="purple" opacity="0.6"/>',
          );
        }
      }

      // Legend
      const legendX = width - 200.0;
      const legendY = 60.0;
      svg.writeln(
        '<rect x="$legendX" y="$legendY" width="180" height="50" fill="white" stroke="black" stroke-width="1"/>',
      );
      svg.writeln(
        '<line x1="${legendX + 10}" y1="${legendY + 20}" x2="${legendX + 40}" y2="${legendY + 20}" stroke="purple" stroke-width="3"/>',
      );
      svg.writeln(
        '<text x="${legendX + 50}" y="${legendY + 25}" font-size="14" fill="black">Battery SOC</text>',
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
}
