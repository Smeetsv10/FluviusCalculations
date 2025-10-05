import 'package:flutter/material.dart';
import 'package:fluvius_calculations_flutter/classes/apiService.dart';
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
  bool _isTestingAPI = false;

  Future<void> _withLoading(Future<void> Function() action) async {
    final gridData = context.read<GridData>();
    if (gridData.csvFileBytes == null) {
      showMyDialog(
        'No CSV Selected',
        'Please select a CSV file in the Grid Data section before sending data.',
        context,
      );
      return;
    }

    setState(() => gridData.isLoading = true);
    try {
      await action();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      setState(() => gridData.isLoading = false);
    }
  }

  Future<void> testAPI() async {
    setState(() => _isTestingAPI = true);
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
      setState(() => _isTestingAPI = false);
    }
  }

  Future<void> processData() async => _withLoading(() async {
    final house = context.read<House>();
    final response = await ApiService.sendHouseData(house);

    if (response['data_info']?['date_range'] != null) {
      final startDate = DateTime.parse(
        response['data_info']['date_range']['start'],
      );
      final endDate = DateTime.parse(
        response['data_info']['date_range']['end'],
      );
      context.read<GridData>().updateParameters(
        newStartDate: startDate,
        newEndDate: endDate,
        newMinStartDate: startDate,
        newMaxEndDate: endDate,
      );
      setState(() {});
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Success!')));
  });

  Future<void> visualizeData() async => _withLoading(() async {
    final house = context.read<House>();
    final response = await ApiService.visualizeHouseData(house);
    house.grid_data.base64Image = response['base64Figure'];
    showPlotDialog(house.grid_data.base64Image, context);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Success!')));
  });

  Future<void> simulateHousehold() async => _withLoading(() async {
    final house = context.read<House>();
    final response = await ApiService.simulateHouse(house);

    if (response.containsKey('error')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response['error'])));
      return;
    }

    ApiService.handlePythonResponse(response, house);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Success!')));
  });

  Future<void> optimizeBattery() async => _withLoading(() async {
    final house = context.read<House>();
    final response = await ApiService.optimizeBattery(house);
    ApiService.handlePythonResponse(response, house);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Success!')));
  });

  Future<void> visualizeSimulation() async => _withLoading(() async {
    final house = context.read<House>();
    final response = await ApiService.visualizeSimulation(house);
    house.grid_data.base64Image = response['base64Figure'];
    showPlotDialog(house.grid_data.base64Image, context);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Success!')));
  });

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
      body: Consumer<GridData>(
        builder: (context, gridData, child) {
          return Stack(
            children: [
              if (gridData.isLoading)
                Container(
                  color: const Color.fromARGB(69, 0, 0, 0),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HouseParameterScreen(),
                    const SizedBox(height: 20),
                    const BatteryParameterScreen(),
                    const SizedBox(height: 20),
                    const GridDataParameterScreen(),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => print(context.read<House>().toJson()),
                      child: const Text('Print House JSON'),
                    ),
                    TextButton(
                      onPressed: _isTestingAPI ? null : testAPI,
                      child: Wrap(
                        children: [
                          _isTestingAPI
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.wifi_protected_setup),
                          Text(
                            _isTestingAPI
                                ? 'Testing...'
                                : '🔧 Test API Connection',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: gridData.isLoading ? null : processData,
                      child: const Text('Process Data'),
                    ),
                    TextButton(
                      onPressed: gridData.isLoading ? null : visualizeData,
                      child: const Text('Visualize Data'),
                    ),
                    TextButton(
                      onPressed: gridData.isLoading ? null : simulateHousehold,
                      child: const Text('Simulate Household'),
                    ),
                    TextButton(
                      onPressed: gridData.isLoading
                          ? null
                          : visualizeSimulation,
                      child: const Text('Plot Simulation Results'),
                    ),
                    TextButton(
                      onPressed: gridData.isLoading ? null : optimizeBattery,
                      child: const Text('Optimize Battery'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
