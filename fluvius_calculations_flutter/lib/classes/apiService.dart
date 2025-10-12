import 'dart:convert';
import 'package:fluvius_calculations_flutter/classes/myHouse.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  // Generic GET request
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    try {
      final response = await http.get(url);
      final data = _handleResponse(response, "GET $endpoint");
      return data;
    } catch (e) {
      print('⚠️ GET request error: $e');
      rethrow;
    }
  }

  // Generic POST request
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map body, {
    required House house,
  }) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final data = _handleResponse(response, "POST $endpoint");
      handlePythonResponse(data, house);

      return data;
    } catch (e) {
      print('⚠️ POST request error: $e');
      rethrow;
    }
  }

  // Handle response and decode JSON
  static Map<String, dynamic> _handleResponse(
    http.Response response,
    String label,
  ) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      print('❌ $label error: ${response.statusCode} - ${response.body}');
      throw Exception('$label failed: ${response.statusCode}');
    }
  }

  // Specific API endpoints
  static Future<Map<String, dynamic>> testConnection() => get('');
  static Future<Map<String, dynamic>> sendHouseData(House house) =>
      post('load_data', house.toJson(), house: house);
  static Future<Map<String, dynamic>> visualizeHouseData(House house) =>
      post('plot_data', house.toJson(), house: house);
  static Future<Map<String, dynamic>> simulateHouse(House house) =>
      post('simulate', house.toJson(), house: house);
  static Future<Map<String, dynamic>> optimizeBattery(House house) =>
      post('optimize', house.toJson(), house: house);
  static Future<Map<String, dynamic>> visualizeSimulation(House house) =>
      post('plot_simulation', house.toJson(), house: house);

  // Handle Python response
  static void handlePythonResponse(Map<String, dynamic> response, House house) {
    T? _get<T>(String key) =>
        response.containsKey(key) ? response[key] as T : null;
    List<double>? _getDoubleList(String key) =>
        response.containsKey(key) && response[key] != null
        ? List<double>.from(response[key])
        : null;
    double? _getDouble(String key) =>
        response.containsKey(key) && response[key] != null
        ? (response[key] as num).toDouble()
        : null;

    final importEnergyHistory =
        _getDoubleList('import_energy') ??
        _getDoubleList('import_energy_history');
    final exportEnergyHistory =
        _getDoubleList('export_energy') ??
        _getDoubleList('export_energy_history');
    final socHistory = _getDoubleList('soc_history');
    final importCost = _getDouble('import_cost');
    final exportRevenue = _getDouble('export_revenue');
    final energyCost = _getDouble('energy_cost');
    final optimalBatteryCapacity = _getDouble('optimal_capacity');
    final capacityArray = _getDoubleList('capacity_array');
    final savingsList = _getDoubleList('savings_list');
    final annualizedBatteryCostArray = _getDoubleList(
      'annualized_battery_cost_array',
    );
    final base64Figure = _get<String>('base64Figure');
    final base64GridDataFigure = _get<String>('base64GridDataFigure');

    house.updateParameters(
      newImportEnergyHistory: importEnergyHistory,
      newExportEnergyHistory: exportEnergyHistory,
      newImportCost: importCost,
      newExportRevenue: exportRevenue,
      newEnergyCost: energyCost,
      newOptimalBatteryCapacity: optimalBatteryCapacity,
      capacity_array: capacityArray,
      savings_list: savingsList,
      annualized_battery_cost_array: annualizedBatteryCostArray,
      newBase64Image: base64Figure,
    );
    house.grid_data.updateParameters(newBase64Image: base64GridDataFigure);
    house.battery.updateParameters(newSOCHistory: socHistory);
  }
}
