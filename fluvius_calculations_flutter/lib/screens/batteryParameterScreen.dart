import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fluvius_calculations_flutter/classes/myBattery.dart';
import 'package:fluvius_calculations_flutter/functions/helperFunctions.dart';

class BatteryParameterScreen extends StatefulWidget {
  const BatteryParameterScreen({super.key});

  @override
  State<BatteryParameterScreen> createState() => _BatteryParameterScreenState();
}

class _BatteryParameterScreenState extends State<BatteryParameterScreen> {
  late TextEditingController maxCapacityController;
  late TextEditingController efficiencyController;
  late TextEditingController socController;
  late TextEditingController variableCostController;
  late TextEditingController batteryLifetimeController;
  late TextEditingController cRateController;
  late TextEditingController fixedCostController;

  @override
  void initState() {
    super.initState();
    final battery = Provider.of<Battery>(context, listen: false);

    maxCapacityController = TextEditingController(
      text: battery.max_capacity.toString(),
    );
    efficiencyController = TextEditingController(
      text: battery.efficiency.toString(),
    );
    socController = TextEditingController(text: battery.SOC.toString());
    fixedCostController = TextEditingController(
      text: battery.fixed_costs.toString(),
    );
    variableCostController = TextEditingController(
      text: battery.variable_cost.toString(),
    );
    batteryLifetimeController = TextEditingController(
      text: battery.battery_lifetime.toString(),
    );
    cRateController = TextEditingController(text: battery.C_rate.toString());
  }

  @override
  void dispose() {
    maxCapacityController.dispose();
    efficiencyController.dispose();
    socController.dispose();
    variableCostController.dispose();
    batteryLifetimeController.dispose();
    cRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Battery>(
      builder: (context, battery, child) {
        Widget buildMaxCapacityField() {
          return buildField(
            context: context,
            title: 'Max Capacity (kWh)',
            hoverText:
                'Maximum energy capacity of the battery in kilowatt-hours (kWh).',
            min: 0,
            max: 100,
            currentValue: battery.max_capacity,
            controller: maxCapacityController,
            onValueChanged: (value) {
              battery.updateParameters(newMaxCapacity: value);
            },
          );
        }

        Widget buildEfficiencyField() {
          return buildField(
            context: context,
            title: 'Efficiency (0-1)',
            min: 0,
            max: 1,
            hoverText:
                'Efficiency of the battery during charge and discharge cycles ≈0.95.',
            currentValue: battery.efficiency,
            controller: efficiencyController,
            onValueChanged: (value) {
              battery.updateParameters(newEfficiency: value);
            },
            divisions: 100,
            labelFormatter: (value) => (value * 100).toStringAsFixed(0) + '%',
          );
        }

        Widget buildSOCField() {
          return buildField(
            context: context,
            title: 'State of Charge (SOC) (0-1)',
            hoverText: 'Initial state of charge of the battery.',
            min: 0,
            max: 1,
            currentValue: battery.SOC,
            controller: socController,
            onValueChanged: (value) {
              battery.updateParameters(newSOC: value);
            },
            divisions: 100,
            labelFormatter: (value) => (value * 100).toStringAsFixed(0) + '%',
          );
        }

        Widget buildFixedCostField() {
          return buildField(
            context: context,
            title: 'Battery Fixed Costs (€)',
            hoverText: 'Fixed costs associated with the battery installation.',
            min: 0,
            max: 5000,
            labelFormatter: (value) => value.toStringAsFixed(0),
            currentValue: battery.fixed_costs,
            controller: fixedCostController,
            onValueChanged: (value) {
              battery.updateParameters(newFixedCosts: value);
            },
          );
        }

        Widget buildVariableCostField() {
          return buildField(
            context: context,
            title: 'Battery Price (€/kWh)',
            hoverText: 'Cost of the battery divided by its capacity ≈€700.',
            min: 0,
            max: 2000,
            currentValue: battery.variable_cost,
            controller: variableCostController,
            onValueChanged: (value) {
              battery.updateParameters(newVariableCost: value);
            },
          );
        }

        Widget buildBatteryLifetimeField() {
          return buildField(
            context: context,
            title: 'Battery Lifetime (years)',
            hoverText: 'Expected lifetime of the battery ≈10 years.',
            min: 1,
            max: 25,
            currentValue: battery.battery_lifetime.toDouble(),
            controller: batteryLifetimeController,
            onValueChanged: (value) {
              battery.updateParameters(newBatteryLifetime: value.toInt());
            },
            divisions: 24,
          );
        }

        Widget buildCRateField() {
          return buildField(
            context: context,
            title: 'C-rate',
            hoverText:
                'Rate at which the battery can be charged/discharged relative to its maximum capacity. A C-rate of 1 means the battery can be fully charged or discharged in one hour. A C-rate of 0.5 means it takes two hours, and a C-rate of 2 means it takes half an hour. Typical values for home batteries are between 0.1 and 1.',
            min: 0.01,
            max: 5.0,
            currentValue: battery.C_rate,
            controller: cRateController,
            onValueChanged: (value) {
              battery.updateParameters(newCRate: value);
            },
            labelFormatter: (value) => value.toStringAsFixed(2),
            divisions: 499,
          );
        }

        return ExpansionTile(
          title: const Text(
            "Battery Parameters",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          initiallyExpanded: true,
          tilePadding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Column(
                children: [
                  buildMaxCapacityField(),
                  const SizedBox(height: 8),
                  buildEfficiencyField(),
                  const SizedBox(height: 8),
                  buildSOCField(),
                  const SizedBox(height: 8),
                  buildCRateField(),
                  const SizedBox(height: 16),
                  buildFixedCostField(),
                  const SizedBox(height: 8),
                  buildVariableCostField(),
                  const SizedBox(height: 8),
                  buildBatteryLifetimeField(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
