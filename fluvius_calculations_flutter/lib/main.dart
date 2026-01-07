import 'package:flutter/material.dart';
import 'package:fluvius_calculations_flutter/classes/myBattery.dart';
import 'package:fluvius_calculations_flutter/classes/myGridData.dart';
import 'package:fluvius_calculations_flutter/classes/myHouse.dart';
import 'package:fluvius_calculations_flutter/classes/myUser.dart';
import 'package:fluvius_calculations_flutter/widgets/screenSelector.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  runApp(
    MultiProvider(
      providers: [
        Provider<User>(create: (_) => User()),
        ChangeNotifierProvider<House>(create: (_) => House()),
        ChangeNotifierProxyProvider<House, GridData>(
          create: (_) => GridData(),
          update: (_, house, _) => house.grid_data,
        ),
        ChangeNotifierProxyProvider<House, Battery>(
          create: (_) => Battery(),
          update: (_, house, _) => house.battery,
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
          seedColor: Colors.green[700]!,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.antaTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
      ),
      home: ScreenSelector(),
    );
  }
}
