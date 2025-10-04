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
}
