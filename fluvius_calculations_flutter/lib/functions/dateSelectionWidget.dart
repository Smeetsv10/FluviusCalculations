import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DateSelectionWidget extends StatefulWidget {
  final String title;
  final TextEditingController controller;
  final Function(String)? onDateChanged;

  const DateSelectionWidget({
    super.key,
    required this.title,
    required this.controller,
    this.onDateChanged,
  });

  @override
  State<DateSelectionWidget> createState() => _DateSelectionWidgetState();
}

class _DateSelectionWidgetState extends State<DateSelectionWidget> {
  late TextEditingController dayController;
  late TextEditingController monthController;
  late TextEditingController yearController;

  late FocusNode dayFocus;
  late FocusNode monthFocus;
  late FocusNode yearFocus;

  bool isValid = true;

  @override
  void initState() {
    super.initState();

    dayController = TextEditingController();
    monthController = TextEditingController();
    yearController = TextEditingController();

    dayFocus = FocusNode();
    monthFocus = FocusNode();
    yearFocus = FocusNode();

    if (widget.controller.text.isNotEmpty) {
      final parts = widget.controller.text.split('-');
      if (parts.length == 3) {
        dayController.text = parts[0];
        monthController.text = parts[1];
        yearController.text = parts[2];
      }
    }

    void updateDate() {
      final d = int.tryParse(dayController.text) ?? 0;
      final m = int.tryParse(monthController.text) ?? 0;
      final y = int.tryParse(yearController.text) ?? 0;

      bool valid =
          d >= 1 &&
          d <= 31 &&
          m >= 1 &&
          m <= 12 &&
          yearController.text.length == 4;

      setState(() {
        isValid = valid;
      });

      final dateStr =
          '${d.toString().padLeft(2, '0')}-${m.toString().padLeft(2, '0')}-${y.toString().padLeft(4, '0')}';
      widget.controller.text = dateStr;

      if (valid && widget.onDateChanged != null) {
        widget.onDateChanged!(dateStr);
      }
    }

    dayController.addListener(updateDate);
    monthController.addListener(updateDate);
    yearController.addListener(updateDate);
  }

  @override
  void dispose() {
    dayController.dispose();
    monthController.dispose();
    yearController.dispose();
    dayFocus.dispose();
    monthFocus.dispose();
    yearFocus.dispose();
    super.dispose();
  }

  Widget buildNumberField({
    required TextEditingController controller,
    required int length,
    required FocusNode focusNode,
    FocusNode? nextFocus,
  }) {
    return SizedBox(
      width: length * 10 + 15, // width per character
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlignVertical: TextAlignVertical.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(length),
        ],
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
        onChanged: (value) {
          if (value.length == length && nextFocus != null) {
            nextFocus.requestFocus();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: isValid ? Colors.black : Colors.red,
    );

    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: titleStyle),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    buildNumberField(
                      controller: dayController,
                      length: 2,
                      focusNode: dayFocus,
                      nextFocus: monthFocus,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text('-'),
                    ),
                    buildNumberField(
                      controller: monthController,
                      length: 2,
                      focusNode: monthFocus,
                      nextFocus: yearFocus,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text('-'),
                    ),
                    buildNumberField(
                      controller: yearController,
                      length: 4,
                      focusNode: yearFocus,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
