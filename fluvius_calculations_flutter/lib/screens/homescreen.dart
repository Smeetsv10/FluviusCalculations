import 'package:flutter/material.dart';
import 'package:fluvius_calculations_flutter/classes/apiService.dart';
import 'package:fluvius_calculations_flutter/classes/myBattery.dart';
import 'package:fluvius_calculations_flutter/classes/myGridData.dart';
import 'package:fluvius_calculations_flutter/classes/myHouse.dart';
import 'package:fluvius_calculations_flutter/functions/helperFunctions.dart';
import 'package:fluvius_calculations_flutter/screens/batteryParameterScreen.dart';
import 'package:fluvius_calculations_flutter/screens/gridDataParametersScreen.dart';
import 'package:fluvius_calculations_flutter/screens/houseParametersScreen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false; // Loading state for Load Data
  bool _isBrowsing = false; // Loading state for Browse button
  bool _isTestingAPI = false; // Loading state for API test

  Future<void> testAPI() async {
    setState(() {
      _isTestingAPI = true;
    });

    try {
      final response = await ApiService.testConnection();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ API Test Success: ${response['message']}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ API Test Failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isTestingAPI = false;
      });
    }
  }

  Future<void> processData() async {
    setState(() {
      _isLoading = true;
    });
    if (Provider.of<GridData>(context, listen: false).csvFileBytes == null) {
      showMyDialog(
        'No CSV Selected',
        'Please select a CSV file in the Grid Data section before sending data.',
        context,
      );

      setState(() {
        _isLoading = false;
      });
      return;
    }
    try {
      final house = context.read<House>();
      final response = await ApiService.sendHouseData(house);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Success!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      _isLoading = false;
      setState(() {});
    }
  }

  Future<void> simulateHousehold() async {
    // Placeholder for simulate functionality
    showMyDialog(
      'Not Implemented',
      'Simulate household functionality not yet implemented.',
      context,
    );
  }

  Future<void> optimizeBattery() async {
    // Placeholder for optimize functionality
    showMyDialog(
      'Not Implemented',
      'Optimize battery functionality not yet implemented.',
      context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Home Battery Sizing Tool',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Stack(
        children: [
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- House Parameters Section ---
                const HouseParameterScreen(),
                const SizedBox(height: 20),
                // --- Battery Parameters Section ---
                const BatteryParameterScreen(),
                const SizedBox(height: 20),
                // --- Grid Data Parameters Section ---
                const GridDataParameterScreen(),
                const SizedBox(height: 20),

                // --- Debug / Print JSON ---
                ElevatedButton(
                  onPressed: () {
                    print(Provider.of<House>(context, listen: false).toJson());
                  },
                  child: const Text('Print House JSON'),
                ),

                ElevatedButton(
                  onPressed: _isTestingAPI ? null : testAPI,
                  child: Wrap(
                    children: [
                      _isTestingAPI
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_protected_setup),
                      Text(
                        _isTestingAPI ? 'Testing...' : '🔧 Test API Connection',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Functional buttons
                ElevatedButton(
                  onPressed: processData,
                  child: const Text('1. Process Data'),
                ),
                ElevatedButton(
                  onPressed: null,
                  child: const Text('2. Simulate Household (TBD)'),
                ),
                ElevatedButton(
                  onPressed: null,
                  child: const Text('3. Optimize Battery (TBD)'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
