import 'package:flutter/material.dart';
import 'package:fluvius_calculations_flutter/classes/myBattery.dart';
import 'package:fluvius_calculations_flutter/classes/myGridData.dart';
import 'package:fluvius_calculations_flutter/classes/myHouse.dart';
import 'package:fluvius_calculations_flutter/screens/homescreen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<House>(create: (_) => House()),
        ChangeNotifierProxyProvider<House, GridData>(
          create: (_) => GridData(),
          update: (_, house, __) => house.grid_data,
        ),
        ChangeNotifierProxyProvider<House, Battery>(
          create: (_) => Battery(),
          update: (_, house, __) => house.battery,
        ),
      ],
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
