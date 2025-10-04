import 'package:flutter/material.dart';
import 'package:fluvius_calculations_flutter/classes/myBattery.dart';
import 'package:fluvius_calculations_flutter/classes/myHouse.dart';
import 'package:fluvius_calculations_flutter/functions/helperFunctions.dart';
import 'package:fluvius_calculations_flutter/screens/batteryParameterScreen.dart';
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
    return Consumer<House>(
      builder: (context, house, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Fluvius Calculations'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                    // Provide the battery separately to BatteryParameterScreen
                    ChangeNotifierProvider<Battery>.value(
                      value: house.battery,
                      child: const BatteryParameterScreen(),
                    ),

                    ChangeNotifierProvider<House>.value(
                      value: house,
                      child: const HouseParameterScreen(),
                    ),

                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        print(house.toJson());
                      },
                      child: const Text('Print House JSON'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
