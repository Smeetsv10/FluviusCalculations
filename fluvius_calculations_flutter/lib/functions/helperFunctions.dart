import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:flutter/services.dart';

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

void showPlotDialog(String base64Image, BuildContext context) {
  // Clean the base64 string by removing data URL prefix if present
  String cleanBase64 = base64Image;
  if (base64Image.contains(',')) {
    cleanBase64 = base64Image.split(',').last;
  }

  // Remove any whitespace or newlines
  cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Data Visualization',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: cleanBase64.isEmpty
                  ? const Center(
                      child: Text(
                        'No image data available',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : Image.memory(
                      base64Decode(cleanBase64),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Failed to load image\nError: $error',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    ),
  );
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
