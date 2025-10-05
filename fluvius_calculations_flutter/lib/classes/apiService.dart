import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fluvius_calculations_flutter/classes/myHouse.dart';

class ApiService {
  static const String baseUrl =
      'http://127.0.0.1:8000'; // Change to your IP if using emulator/device

  static Future<Map<String, dynamic>> testConnection() async {
    final url = Uri.parse('$baseUrl/');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ API Test Response: $data');
        return data;
      } else {
        print('❌ API Test failed: ${response.statusCode} - ${response.body}');
        throw Exception('API connection failed: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ API Test error: $e');
      throw Exception('Could not connect to API: $e');
    }
  }

  static Future<Map<String, dynamic>> sendHouseData(House house) async {
    final url = Uri.parse('$baseUrl/load_data');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(house.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Server Response: $data');
        return data;
      } else {
        print('❌ Server error: ${response.statusCode} - ${response.body}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Failed to send data: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> vizualizeHouseData(House house) async {
    final url = Uri.parse('$baseUrl/plot_data');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(house.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print(
          '❌ Visualization error: ${response.statusCode} - ${response.body}',
        );
        throw Exception('Visualization error: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Failed to visualize data: $e');
      rethrow;
    }
  }

  static void handlePythonResponse(
    Map<String, dynamic> simulationResponse,
    House house,
  ) {
    List<double>? importEnergyHistory;
    List<double>? exportEnergyHistory;
    List<double>? socHistory;
    double? importCost;
    double? exportRevenue;
    double? energyCost;
    double? optimalBatteryCapacity;

    if (simulationResponse.containsKey('import_energy_history')) {
      importEnergyHistory = List<double>.from(
        simulationResponse['import_energy_history'],
      );
    }

    if (simulationResponse.containsKey('export_energy_history')) {
      exportEnergyHistory = List<double>.from(
        simulationResponse['export_energy_history'],
      );
    }

    if (simulationResponse.containsKey('soc_history')) {
      socHistory = List<double>.from(simulationResponse['soc_history']);
    }

    if (simulationResponse.containsKey('import_cost')) {
      importCost = (simulationResponse['import_cost'] as num?)?.toDouble();
    }

    if (simulationResponse.containsKey('export_revenue')) {
      exportRevenue = (simulationResponse['export_revenue'] as num?)
          ?.toDouble();
    }

    if (simulationResponse.containsKey('energy_cost')) {
      energyCost = (simulationResponse['energy_cost'] as num?)?.toDouble();
    }

    if (simulationResponse.containsKey('optimal_capacity')) {
      optimalBatteryCapacity = (simulationResponse['optimal_capacity'] as num?)
          ?.toDouble();
    }

    // Only pass non-null parameters to update methods
    house.updateParameters(
      newImportEnergyHistory: importEnergyHistory,
      newExportEnergyHistory: exportEnergyHistory,
      newImportCost: importCost,
      newExportRevenue: exportRevenue,
      newEnergyCost: energyCost,
      newOptimalBatteryCapacity: optimalBatteryCapacity,
    );

    house.battery.updateParameters(newSOCHistory: socHistory);
  }
}
