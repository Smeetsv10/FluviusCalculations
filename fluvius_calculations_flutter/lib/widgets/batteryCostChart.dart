import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:fluvius_calculations_flutter/classes/myGridData.dart';

class BatteryCostChart extends StatefulWidget {
  final List<double> savings_list;
  final List<double> capacity_array;

  const BatteryCostChart({
    super.key,
    required this.savings_list,
    required this.capacity_array,
  });

  @override
  State<BatteryCostChart> createState() => _BatteryCostChartState();
}

class _BatteryCostChartState extends State<BatteryCostChart> {
  late List<EnergyDataPoint> data;
  late int minIndex;
  late double minCost;
  late double minCapacity;
  late TooltipBehavior _tooltipBehavior;
  late TrackballBehavior _trackballBehavior;

  @override
  void initState() {
    super.initState();
    _tooltipBehavior = TooltipBehavior(enable: true);
    _trackballBehavior = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      tooltipSettings: const InteractiveTooltip(
        enable: true,
        color: Colors.black87,
      ),
    );
    _generateChartData();
  }

  void _generateChartData() {
    data = [];
    minIndex = 0;
    minCost = double.infinity;

    for (int i = 0; i < widget.capacity_array.length; i++) {
      data.add(
        EnergyDataPoint(
          datetime: DateTime(0),
          volume_afname_kwh: widget.savings_list[i],
          volume_injectie_kwh: widget.capacity_array[i],
        ),
      );

      // Find minimum cost
      if (widget.savings_list[i] < minCost) {
        minCost = widget.savings_list[i];
        minCapacity = widget.capacity_array[i];
        minIndex = i;
      }
    }
  }

  @override
  void didUpdateWidget(BatteryCostChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _generateChartData();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 300,
      width: 1000,
      child: SfCartesianChart(
        primaryXAxis: NumericAxis(
          title: AxisTitle(text: 'Battery Capacity (kWh)'),
        ),
        primaryYAxis: NumericAxis(
          labelFormat: '{value}',
          labelStyle: const TextStyle(fontSize: 10),
          title: AxisTitle(text: 'Annualized Cost (euro)'),
        ),
        title: ChartTitle(
          text: 'Cost vs Battery Capacity',
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        legend: Legend(
          isVisible: true,
          position: LegendPosition.top,
          overflowMode: LegendItemOverflowMode.wrap,
        ),
        tooltipBehavior: _tooltipBehavior,
        trackballBehavior: _trackballBehavior,
        series: <CartesianSeries>[
          LineSeries<EnergyDataPoint, double>(
            dataSource: data,
            xValueMapper: (EnergyDataPoint datapoint, _) =>
                datapoint.volume_injectie_kwh,
            yValueMapper: (EnergyDataPoint datapoint, _) =>
                datapoint.volume_afname_kwh,
            color: Colors.blueGrey,
            name: 'Annualized cost (euro)',
            enableTooltip: true,
            markerSettings: const MarkerSettings(
              isVisible: false,
            ),
          ),
          ScatterSeries<EnergyDataPoint, double>(
            dataSource: [data[minIndex]],
            xValueMapper: (EnergyDataPoint datapoint, _) =>
                datapoint.volume_injectie_kwh,
            yValueMapper: (EnergyDataPoint datapoint, _) =>
                datapoint.volume_afname_kwh,
            color: Colors.red,
            name: 'Minimum Cost',
            markerSettings: const MarkerSettings(
              isVisible: true,
              height: 10,
              width: 10,
              shape: DataMarkerType.circle,
              borderColor: Colors.red,
              borderWidth: 2,
            ),
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              labelAlignment: ChartDataLabelAlignment.top,
              builder: (data, point, series, pointIndex, seriesIndex) {
                return Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Min: ${minCapacity.toStringAsFixed(1)} kWh\n${minCost.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
