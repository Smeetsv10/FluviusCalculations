import 'package:flutter/material.dart';
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
                TextButton(
                  onPressed: () {
                    print(Provider.of<House>(context, listen: false).toJson());
                  },
                  child: const Text('Print House JSON'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
