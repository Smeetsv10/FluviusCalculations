import 'package:flutter/material.dart';
import 'package:fluvius_calculations_flutter/classes/myBattery.dart';

class PiecewiseCostEditor extends StatefulWidget {
  final Battery battery;

  const PiecewiseCostEditor({super.key, required this.battery});

  @override
  State<PiecewiseCostEditor> createState() => _PiecewiseCostEditorState();
}

class _PiecewiseCostEditorState extends State<PiecewiseCostEditor> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Cost Points (Capacity kWh → Price €)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.green),
              tooltip: 'Add Point',
              onPressed: _addPoint,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              _buildPointsList(),
              const SizedBox(height: 12),
              _buildCostGraph(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPointsList() {
    final sortedPoints = List<CostPoint>.from(widget.battery.costPoints)
      ..sort((a, b) => a.capacity.compareTo(b.capacity));

    return Column(
      children: sortedPoints.asMap().entries.map((entry) {
        final index = widget.battery.costPoints.indexOf(entry.value);
        final point = entry.value;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Capacity (kWh)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(
                    text: point.capacity.toStringAsFixed(1),
                  ),
                  onSubmitted: (value) {
                    final newCapacity = double.tryParse(value);
                    if (newCapacity != null) {
                      setState(() {
                        widget.battery.costPoints[index].capacity = newCapacity;
                        widget.battery.updateParameters(
                          newCostPoints: widget.battery.costPoints,
                        );
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Price (€)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(
                    text: point.price.toStringAsFixed(0),
                  ),
                  onSubmitted: (value) {
                    final newPrice = double.tryParse(value);
                    if (newPrice != null) {
                      setState(() {
                        widget.battery.costPoints[index].price = newPrice;
                        widget.battery.updateParameters(
                          newCostPoints: widget.battery.costPoints,
                        );
                      });
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Remove Point',
                onPressed: widget.battery.costPoints.length > 2
                    ? () => _removePoint(index)
                    : null,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCostGraph() {
    return SizedBox(
      height: 200,
      child: CustomPaint(
        painter: CostGraphPainter(widget.battery.costPoints),
        child: Container(),
      ),
    );
  }

  void _addPoint() {
    setState(() {
      // Add a new point between existing ones
      final sortedPoints = List<CostPoint>.from(widget.battery.costPoints)
        ..sort((a, b) => a.capacity.compareTo(b.capacity));

      if (sortedPoints.length >= 2) {
        final midCapacity =
            (sortedPoints.last.capacity +
                sortedPoints[sortedPoints.length - 2].capacity) /
            2;
        final midPrice =
            (sortedPoints.last.price +
                sortedPoints[sortedPoints.length - 2].price) /
            2;
        widget.battery.costPoints.add(CostPoint(midCapacity, midPrice));
      } else {
        widget.battery.costPoints.add(
          CostPoint(
            sortedPoints.last.capacity + 5,
            sortedPoints.last.price + 3000,
          ),
        );
      }

      widget.battery.updateParameters(newCostPoints: widget.battery.costPoints);
    });
  }

  void _removePoint(int index) {
    if (widget.battery.costPoints.length > 2) {
      setState(() {
        widget.battery.costPoints.removeAt(index);
        widget.battery.updateParameters(
          newCostPoints: widget.battery.costPoints,
        );
      });
    }
  }
}

class CostGraphPainter extends CustomPainter {
  final List<CostPoint> points;

  CostGraphPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final sortedPoints = List<CostPoint>.from(points)
      ..sort((a, b) => a.capacity.compareTo(b.capacity));

    // Find min/max for scaling
    final maxCapacity = sortedPoints
        .map((p) => p.capacity)
        .reduce((a, b) => a > b ? a : b);
    final minCapacity = sortedPoints
        .map((p) => p.capacity)
        .reduce((a, b) => a < b ? a : b);
    final maxPrice = sortedPoints
        .map((p) => p.price)
        .reduce((a, b) => a > b ? a : b);
    final minPrice = sortedPoints
        .map((p) => p.price)
        .reduce((a, b) => a < b ? a : b);

    const padding = 40.0;
    final graphWidth = size.width - 2 * padding;
    final graphHeight = size.height - 2 * padding;

    // Draw axes
    final axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      axisPaint,
    );
    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, size.height - padding),
      axisPaint,
    );

    // Draw axis labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // X-axis label
    textPainter.text = const TextSpan(
      text: 'Capacity (kWh)',
      style: TextStyle(color: Colors.black, fontSize: 12),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width / 2 - textPainter.width / 2, size.height - 15),
    );

    // Y-axis label
    canvas.save();
    canvas.translate(10, size.height / 2);
    canvas.rotate(-3.14159 / 2);
    textPainter.text = const TextSpan(
      text: 'Price (€)',
      style: TextStyle(color: Colors.black, fontSize: 12),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, 0));
    canvas.restore();

    // Draw lines between points
    final linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < sortedPoints.length - 1; i++) {
      final p1 = sortedPoints[i];
      final p2 = sortedPoints[i + 1];

      final x1 =
          padding +
          ((p1.capacity - minCapacity) / (maxCapacity - minCapacity)) *
              graphWidth;
      final y1 =
          size.height -
          padding -
          ((p1.price - minPrice) / (maxPrice - minPrice)) * graphHeight;
      final x2 =
          padding +
          ((p2.capacity - minCapacity) / (maxCapacity - minCapacity)) *
              graphWidth;
      final y2 =
          size.height -
          padding -
          ((p2.price - minPrice) / (maxPrice - minPrice)) * graphHeight;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), linePaint);
    }

    // Draw points
    final pointPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    for (final point in sortedPoints) {
      final x =
          padding +
          ((point.capacity - minCapacity) / (maxCapacity - minCapacity)) *
              graphWidth;
      final y =
          size.height -
          padding -
          ((point.price - minPrice) / (maxPrice - minPrice)) * graphHeight;

      canvas.drawCircle(Offset(x, y), 5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(CostGraphPainter oldDelegate) => true;
}
