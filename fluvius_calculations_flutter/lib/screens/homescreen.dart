import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Controllers for all SimulationRequest fields
  final TextEditingController startDateController = TextEditingController(
    text: DateTime.now()
        .subtract(const Duration(days: 7))
        .toIso8601String()
        .substring(0, 10),
  );
  final TextEditingController endDateController = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10),
  );
  final TextEditingController locationController = TextEditingController();
  final TextEditingController injectionPriceController = TextEditingController(
    text: '0.04',
  );
  final TextEditingController pricePerKWhController = TextEditingController(
    text: '0.35',
  );
  final TextEditingController batteryCapacityController = TextEditingController(
    text: '0',
  );
  final TextEditingController batteryLifetimeController = TextEditingController(
    text: '10',
  );
  final TextEditingController pricePerKWhBatteryController =
      TextEditingController(text: '700');
  final TextEditingController efficiencyController = TextEditingController(
    text: '0.95',
  );
  final TextEditingController cRateController = TextEditingController(
    text: '0.0625',
  );
  final TextEditingController dynamicController = TextEditingController(
    text: 'false',
  );
  final TextEditingController flagEVController = TextEditingController(
    text: 'true',
  );
  final TextEditingController flagPVController = TextEditingController(
    text: 'true',
  );
  final TextEditingController eanIdController = TextEditingController();
  final TextEditingController filePathController = TextEditingController();

  // API base URL - adjust this to match your FastAPI server
  static const String apiBaseUrl = 'http://127.0.0.1:8000';

  bool _isLoading = false; // Loading state for Load Data
  bool _isBrowsing = false; // Loading state for Browse button
  PlatformFile? selectedFile; // Store the selected file
  Uint8List? csvFileBytes; // Store CSV file bytes

  Future<void> pickFiles() async {
    if (_isBrowsing) return; // Prevent multiple clicks

    try {
      setState(() {
        _isBrowsing = true;
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true, // This is important to get file bytes
      );

      if (result != null && result.files.isNotEmpty) {
        final PlatformFile file = result.files.first;

        setState(() {
          selectedFile = file;
          csvFileBytes = file.bytes; // Get file bytes directly

          // Update file path display
          if (kIsWeb) {
            filePathController.text =
                "📤 ${file.name} (${file.bytes?.length ?? 0} bytes)";
          } else {
            String filePath = file.path ?? file.name;
            filePathController.text = filePath;
          }
        });

        print('🔍 DEBUG: File selected: ${file.name}');
        print('🔍 DEBUG: File size: ${file.bytes?.length ?? 0} bytes');
        print('🔍 DEBUG: File path: ${file.path ?? "N/A"}');

        // Debug: Show first 200 characters of CSV
        if (csvFileBytes != null) {
          try {
            String csvContent = String.fromCharCodes(csvFileBytes!);
            print(
              '🔍 DEBUG: CSV preview (first 200 chars): ${csvContent.length > 200 ? csvContent.substring(0, 200) : csvContent}',
            );
          } catch (e) {
            print('🔍 DEBUG: Could not preview CSV content: $e');
          }
        }
      } else {
        print('🔍 DEBUG: No file selected');
      }
    } catch (e) {
      print('❌ Error picking file: $e');
      _showErrorDialog('File Selection Error', 'Failed to select file: $e');
    } finally {
      setState(() {
        _isBrowsing = false;
      });
    }
  }

  Future<void> loadData() async {
    if (_isLoading) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Validate required fields
      if (csvFileBytes == null && filePathController.text.isEmpty) {
        _showErrorDialog('Validation Error', 'Please select a CSV file first.');
        return;
      }

      print('🔍 DEBUG: Starting loadData...');
      print('🔍 DEBUG: CSV bytes available: ${csvFileBytes != null}');
      print('🔍 DEBUG: CSV bytes length: ${csvFileBytes?.length ?? 0}');
      print('🔍 DEBUG: File path: ${filePathController.text}');

      // Convert CSV bytes to base64 string
      String? csvDataB64;
      if (csvFileBytes != null) {
        csvDataB64 = base64Encode(csvFileBytes!);
        print('🔍 DEBUG: Base64 encoded CSV length: ${csvDataB64.length}');
        print(
          '🔍 DEBUG: Base64 preview (first 100 chars): ${csvDataB64.length > 100 ? csvDataB64.substring(0, 100) : csvDataB64}',
        );
      }

      // Construct SimulationRequest from form values
      final requestBody = {
        'start_date': startDateController.text,
        'end_date': endDateController.text,
        'location': locationController.text,
        'injection_price': _parseDouble(injectionPriceController.text) ?? 0.04,
        'price_per_kWh': _parseDouble(pricePerKWhController.text) ?? 0.35,
        'battery_capacity': _parseDouble(batteryCapacityController.text) ?? 0.0,
        'battery_lifetime': _parseInt(batteryLifetimeController.text) ?? 10,
        'price_per_kWh_battery':
            _parseDouble(pricePerKWhBatteryController.text) ?? 700.0,
        'efficiency': _parseDouble(efficiencyController.text) ?? 0.95,
        'C_rate': _parseDouble(cRateController.text) ?? 0.0625,
        'dynamic': _parseBool(dynamicController.text),
        'flag_EV': _parseBool(flagEVController.text),
        'flag_PV': _parseBool(flagPVController.text),
        'EAN_ID': eanIdController.text.isEmpty
            ? -1
            : _parseInt(eanIdController.text) ?? -1,
        'file_path': selectedFile?.name ?? filePathController.text,
        'csv_data': csvDataB64, // Send CSV data as base64 string
      };

      print('🔍 DEBUG: Request body keys: ${requestBody.keys.toList()}');
      print('🔍 DEBUG: CSV data included: ${csvDataB64 != null}');
      print('🔍 DEBUG: API URL: $apiBaseUrl/load_data');

      // Make API call
      final response = await http.post(
        Uri.parse('$apiBaseUrl/load_data'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('🔍 DEBUG: Response status: ${response.statusCode}');
      print('🔍 DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData.containsKey('error')) {
          _showErrorDialog('API Error', responseData['error']);
        } else {
          String message =
              responseData['message'] ?? 'Data loaded successfully';

          // Add data info if available
          if (responseData.containsKey('data_info')) {
            final dataInfo = responseData['data_info'];
            message += '\n\nData Info:';
            message += '\n• Records: ${dataInfo['records']}';
            message +=
                '\n• Columns: ${dataInfo['columns']?.join(', ') ?? 'N/A'}';
            if (dataInfo['date_range'] != null) {
              message +=
                  '\n• Date range: ${dataInfo['date_range']['start']} to ${dataInfo['date_range']['end']}';
            }
            setState(() {
              startDateController.text = dataInfo['date_range']['start'] ?? '';
              endDateController.text = dataInfo['date_range']['end'] ?? '';
            });
          }

          _showSuccessDialog('Success', message);
        }
      } else {
        _showErrorDialog(
          'HTTP Error',
          'Request failed with status: ${response.statusCode}\nResponse: ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error in loadData: $e');
      _showErrorDialog('Network Error', 'Failed to connect to API: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> simulateHousehold() async {
    // Placeholder for simulate functionality
    _showErrorDialog(
      'Not Implemented',
      'Simulate household functionality not yet implemented.',
    );
  }

  Future<void> optimizeBattery() async {
    // Placeholder for optimize functionality
    _showErrorDialog(
      'Not Implemented',
      'Optimize battery functionality not yet implemented.',
    );
  }

  Future<void> plotData() async {
    try {
      // Check if data is loaded first
      if (csvFileBytes == null && filePathController.text.isEmpty) {
        _showErrorDialog(
          'Data Required',
          'Please load data first before plotting.',
        );
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Construct request body (you might not need all fields for plotting)
      final requestBody = {
        'start_date': startDateController.text,
        'end_date': endDateController.text,
        'location': locationController.text,
        'injection_price': _parseDouble(injectionPriceController.text) ?? 0.04,
        'price_per_kWh': _parseDouble(pricePerKWhController.text) ?? 0.35,
        'battery_capacity': _parseDouble(batteryCapacityController.text) ?? 0.0,
        'battery_lifetime': _parseInt(batteryLifetimeController.text) ?? 10,
        'price_per_kWh_battery':
            _parseDouble(pricePerKWhBatteryController.text) ?? 700.0,
        'efficiency': _parseDouble(efficiencyController.text) ?? 0.95,
        'C_rate': _parseDouble(cRateController.text) ?? 0.0625,
        'dynamic': _parseBool(dynamicController.text),
        'flag_EV': _parseBool(flagEVController.text),
        'flag_PV': _parseBool(flagPVController.text),
        'EAN_ID': eanIdController.text.isEmpty
            ? -1
            : _parseInt(eanIdController.text) ?? -1,
        'file_path': selectedFile?.name ?? filePathController.text,
      };

      // Make API call to plot_data endpoint
      final response = await http.post(
        Uri.parse('$apiBaseUrl/plot_data'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData.containsKey('error')) {
          _showErrorDialog('Plot Error', responseData['error']);
        } else if (responseData.containsKey('plot_data')) {
          // Show the plot in a dialog
          _showPlotDialog(responseData['plot_data']);
        } else {
          _showErrorDialog('Plot Error', 'No plot data received from server.');
        }
      } else {
        _showErrorDialog(
          'HTTP Error',
          'Request failed with status: ${response.statusCode}\nResponse: ${response.body}',
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      print('❌ Error in plotData: $e');
      _showErrorDialog('Network Error', 'Failed to connect to API: $e');
    }
  }

  // Helper methods
  double? _parseDouble(String text) {
    return double.tryParse(text);
  }

  int? _parseInt(String text) {
    return int.tryParse(text);
  }

  bool _parseBool(String text) {
    return text.toLowerCase() == 'true';
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPlotDialog(String base64Image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 800,
          height: 600,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Data Visualization',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Image.memory(
                  base64Decode(base64Image),
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fluvius Calculations'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // File Selection
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: filePathController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'CSV File Path',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isBrowsing ? null : pickFiles,
                  child: _isBrowsing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Browse'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Form fields in a grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: [
                  TextField(
                    controller: startDateController,
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  TextField(
                    controller: endDateController,
                    decoration: const InputDecoration(
                      labelText: 'End Date',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  TextField(
                    controller: injectionPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Injection Price',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  TextField(
                    controller: pricePerKWhController,
                    decoration: const InputDecoration(
                      labelText: 'Price per kWh',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  TextField(
                    controller: batteryCapacityController,
                    decoration: const InputDecoration(
                      labelText: 'Battery Capacity',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  TextField(
                    controller: batteryLifetimeController,
                    decoration: const InputDecoration(
                      labelText: 'Battery Lifetime',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  TextField(
                    controller: pricePerKWhBatteryController,
                    decoration: const InputDecoration(
                      labelText: 'Battery Price per kWh',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  TextField(
                    controller: efficiencyController,
                    decoration: const InputDecoration(
                      labelText: 'Efficiency',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  TextField(
                    controller: cRateController,
                    decoration: const InputDecoration(
                      labelText: 'C Rate',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  TextField(
                    controller: dynamicController,
                    decoration: const InputDecoration(
                      labelText: 'Dynamic',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  TextField(
                    controller: flagEVController,
                    decoration: const InputDecoration(
                      labelText: 'Flag EV',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  TextField(
                    controller: flagPVController,
                    decoration: const InputDecoration(
                      labelText: 'Flag PV',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  TextField(
                    controller: eanIdController,
                    decoration: const InputDecoration(
                      labelText: 'EAN ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : loadData,
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Load Data"),
                ),
                ElevatedButton(
                  onPressed: simulateHousehold,
                  child: const Text("Simulate"),
                ),
                ElevatedButton(
                  onPressed: optimizeBattery,
                  child: const Text("Optimize"),
                ),
                ElevatedButton(
                  onPressed: plotData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text("📊 Plot Data"),
                ),
                ElevatedButton(
                  onPressed: () {
                    print(
                      '🔍 DEBUG: Current file_path = "${filePathController.text}"',
                    );
                    print(
                      '🔍 DEBUG: File path length = ${filePathController.text.length}',
                    );
                    print(
                      '🔍 DEBUG: File path isEmpty = ${filePathController.text.isEmpty}',
                    );
                    print(
                      '🔍 DEBUG: CSV bytes available = ${csvFileBytes != null}',
                    );
                    print(
                      '🔍 DEBUG: CSV bytes length = ${csvFileBytes?.length ?? 0}',
                    );
                    print(
                      '🔍 DEBUG: Selected file = ${selectedFile?.name ?? "None"}',
                    );
                    _showSuccessDialog(
                      'Debug Info',
                      'File: ${selectedFile?.name ?? "None"}\n'
                          'Path: ${filePathController.text}\n'
                          'Bytes: ${csvFileBytes?.length ?? 0}',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text("🐛 Debug"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
