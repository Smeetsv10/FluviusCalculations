import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluvius_calculations_flutter/classes/myHouse.dart';
import 'package:provider/provider.dart';
import 'package:fluvius_calculations_flutter/classes/myBattery.dart';
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

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "House Parameters",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Divider(),
              const SizedBox(height: 8),

              // --- Max Capacity ---
              buildLocationField(),
              const SizedBox(height: 8),
              buildInjectionPriceField(),
              const SizedBox(height: 8),
              buildPricePerKWhField(),
              const SizedBox(height: 8),
              Divider(),
            ],
          ),
        );
      },
    );
  }
}
