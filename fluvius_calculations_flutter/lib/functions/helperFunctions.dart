import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

void showMyDialog(String title, String message, BuildContext context) {
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

void showPlotDialog(List<String> base64Images, BuildContext context) {
  if (base64Images.isEmpty) {
    showMyDialog('No Data', 'No visualization data available.', context);
    return;
  }

  showDialog(
    context: context,
    builder: (context) => _PlotDialogState(base64Images: base64Images),
  );
}

class _PlotDialogState extends StatefulWidget {
  final List<String> base64Images;

  const _PlotDialogState({required this.base64Images});

  @override
  State<_PlotDialogState> createState() => _PlotDialogStateState();
}

class _PlotDialogStateState extends State<_PlotDialogState> {
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = 0;
  }

  void _nextImage() {
    if (currentIndex < widget.base64Images.length - 1) {
      setState(() => currentIndex++);
    }
  }

  void _previousImage() {
    if (currentIndex > 0) {
      setState(() => currentIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final decodedBytes = base64Decode(widget.base64Images[currentIndex]);
    final svgString = utf8.decode(decodedBytes);

    return Dialog(
      child: Container(
        width: 1100,
        height: 750,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header with title and figure counter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Data Visualization',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Figure ${currentIndex + 1} of ${widget.base64Images.length}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // SVG Display
            Expanded(child: SvgPicture.string(svgString, fit: BoxFit.contain)),
            const SizedBox(height: 16),
            // Navigation Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: currentIndex > 0 ? _previousImage : null,
                  child: const Text('← Previous'),
                ),
                const SizedBox(width: 16),
                // Dropdown to select figure
                DropdownButton<int>(
                  value: currentIndex,
                  items: List.generate(
                    widget.base64Images.length,
                    (index) => DropdownMenuItem(
                      value: index,
                      child: Text('Figure ${index + 1}'),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => currentIndex = value);
                    }
                  },
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: currentIndex < widget.base64Images.length - 1
                      ? _nextImage
                      : null,
                  child: const Text('Next →'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildField({
  required BuildContext context,
  required String title,
  String? hoverText,
  TextEditingController? controller,
  double? currentValue,
  double? min,
  double? max,
  int? divisions,
  String? Function(double)? labelFormatter,
  ValueChanged<String>? onTextChanged, // for text input or fallback
  ValueChanged<double>? onValueChanged, // for numeric slider fields
}) {
  // If min/max are not provided, just return a TextField
  if (min == null || max == null || currentValue == null) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Tooltip(
          message: hoverText ?? '',
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          onChanged: onTextChanged,
        ),
      ],
    );
  }

  // Otherwise, return Slider + TextField
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Tooltip(
        message: hoverText ?? '',
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      Row(
        children: [
          Expanded(
            flex: 3,
            child: Slider(
              min: min,
              max: max,
              divisions: divisions ?? ((max - min).round()),
              value: currentValue.clamp(min, max),
              label:
                  labelFormatter?.call(currentValue) ??
                  currentValue.toStringAsFixed(1),
              onChanged: (value) {
                if (onValueChanged != null) onValueChanged(value);
                if (controller != null) {
                  controller.text = value.toStringAsFixed(2);
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d{0,3}\.?\d{0,2}$'),
                ),
              ],
              onChanged: (value) {
                final newValue = double.tryParse(value);
                if (newValue != null && newValue >= min && newValue <= max) {
                  if (onValueChanged != null) onValueChanged(newValue);
                } else if (newValue != null) {
                  showMyDialog(
                    'Invalid Input',
                    'Please enter a value between $min and $max.',
                    context,
                  );
                }
              },
            ),
          ),
        ],
      ),
    ],
  );
}

SnackBar mySnackBar(
  String message, {
  Duration duration = const Duration(milliseconds: 999),
}) {
  Color bgColor;
  if (message.toLowerCase().contains('error')) {
    bgColor = Colors.red[800]!;
  } else {
    bgColor = Colors.green[800]!;
  }
  return SnackBar(
    content: Text(
      message,
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.white),
    ),
    backgroundColor: bgColor,
    behavior: SnackBarBehavior.floating,
    duration: duration,
    margin: const EdgeInsets.symmetric(horizontal: 16),
  );
}
