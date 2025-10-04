import 'package:flutter/material.dart';
import 'package:fluvius_calculations_flutter/classes/myHouse.dart';
import 'package:fluvius_calculations_flutter/screens/homescreen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => House())],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 34, 116, 36),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.antaTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
      ),
      home: HomeScreen(),
    );
  }
}
