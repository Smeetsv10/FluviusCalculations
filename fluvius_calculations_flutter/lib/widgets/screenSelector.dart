import 'package:flutter/material.dart';
import 'package:fluvius_calculations_flutter/screens/homescreen.dart';
import 'package:fluvius_calculations_flutter/screens/insctructionScreen.dart';

class ScreenSelector extends StatefulWidget {
  const ScreenSelector({super.key});

  @override
  State<ScreenSelector> createState() => _ScreenSelectorState();
}

class _ScreenSelectorState extends State<ScreenSelector> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _screens = [
    {
      'name': 'Home battery sizing tool',
      'icon': Icons.home,
      'widget': const _KeepAliveWrapper(child: HomeScreen()),
    },
    {
      'name': 'Instructions',
      'icon': Icons.info,
      'widget': const _KeepAliveWrapper(child: InstructionScreen()),
    },
  ];

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            destinations: _screens.map((screen) {
              return NavigationDestination(
                icon: Icon(screen['icon']),
                label: screen['name'],
              );
            }).toList(),
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens
                  .map((screen) => screen['widget'] as Widget)
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
