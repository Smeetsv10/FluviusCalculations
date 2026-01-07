import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluvius_calculations_flutter/classes/myHouse.dart';
import 'package:provider/provider.dart';
import 'package:fluvius_calculations_flutter/functions/helperFunctions.dart';

class HouseParameterScreen extends StatefulWidget {
  const HouseParameterScreen({super.key});

  @override
  State<HouseParameterScreen> createState() => _HouseParameterScreenState();
}

class _HouseParameterScreenState extends State<HouseParameterScreen> {
  late TextEditingController injectionPriceController;
  late TextEditingController locationController;
  late TextEditingController pricePerKWhController;

  @override
  void initState() {
    super.initState();
    final house = Provider.of<House>(context, listen: false);

    injectionPriceController = TextEditingController(
      text: house.injection_price.toString(),
    );
    locationController = TextEditingController(text: house.location);
    pricePerKWhController = TextEditingController(
      text: house.price_per_kWh.toString(),
    );
  }

  @override
  void dispose() {
    injectionPriceController.dispose();
    locationController.dispose();
    pricePerKWhController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<House>(
      builder: (context, house, child) {
        Widget buildInjectionPriceField() {
          return buildField(
            context: context,
            title: 'Injection Price (€/kWh)',
            hoverText:
                'Price you get for injecting electricity into the grid ≈0.05€/kWh',
            min: 0,
            max: 1,
            divisions: 100,
            currentValue: house.injection_price,
            controller: injectionPriceController,
            onValueChanged: (value) {
              house.updateParameters(newInjectionPrice: value);
            },
            labelFormatter: (value) => (value).toStringAsFixed(2),
          );
        }

        Widget buildLocationField() {
          return buildField(
            context: context,
            title: 'Location (City, Country)',
            controller: locationController,
            onTextChanged: (value) {
              house.updateParameters(newLocation: value);
            },
          );
        }

        Widget buildPricePerKWhField() {
          return buildField(
            context: context,
            title: 'Price per kWh (€/kWh)',
            hoverText:
                'Total price you pay for electricity from the grid, including taxes, distribution fees, etc. ≈0.35€/kWh',
            min: 0,
            max: 1,
            divisions: 100,
            currentValue: house.price_per_kWh,
            controller: pricePerKWhController,
            onValueChanged: (value) {
              house.updateParameters(newPricePerKWh: value);
            },
            labelFormatter: (value) => (value).toStringAsFixed(2),
          );
        }

        return ExpansionTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "House Parameters",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.grey),
                tooltip: 'Reset House Parameters',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text('Reset House Parameters?'),
                      content: const Text(
                        'This will reset all house parameters (location, injection price, price per kWh) to their default values.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            house.initializeParameters();
                            // Update controllers to reflect reset values
                            locationController.text = house.location;
                            injectionPriceController.text = house
                                .injection_price
                                .toString();
                            pricePerKWhController.text = house.price_per_kWh
                                .toString();
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  '✅ House parameters reset to defaults',
                                ),
                                backgroundColor: Colors.grey.shade600,
                              ),
                            );
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          initiallyExpanded: false,
          tilePadding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Column(
                children: [
                  buildLocationField(),
                  const SizedBox(height: 8),
                  buildInjectionPriceField(),
                  const SizedBox(height: 8),
                  buildPricePerKWhField(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
