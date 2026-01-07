import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:js_interop';

@JS()
external void open(String url, String target);

class InstructionScreen extends StatelessWidget {
  const InstructionScreen({super.key});

  // Open URL in new tab (Web)
  void _launchUrl(String url) {
    open(url, '_blank');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instruction text
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CSV Data Guide',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                    children: [
                      const TextSpan(text: '1. Go to '),
                      TextSpan(
                        text: 'fluvius.be',
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            _launchUrl('https://www.fluvius.be');
                          },
                      ),
                      const TextSpan(
                        text:
                            ' click on "Mijn Fluvius" and log in to your account.\n\n'
                            '2. Click on "Verbruik" to access your consumption data.\n\n'
                            '3. Click on "Historiek Downloaden" to download your consumption data as a CSV file.\n\n'
                            '4. Important: Select "Kwartiertotalen" to get an accurate simulation for your household.\n\n'
                            '5. Click on "Downloaden" and Load the CSV file into the app using the "Load CSV Data" button on the Home Screen.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // PDF as image
          Expanded(
            flex: 2,
            child: Image.asset('assets/csvDataGuide.png', fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }
}
