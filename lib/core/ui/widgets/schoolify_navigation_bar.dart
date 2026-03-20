import 'package:flutter/material.dart';

/// Branded [NavigationBar] — use for mobile shell / thumb-first nav.
class SchoolifyNavigationBar extends StatelessWidget {
  const SchoolifyNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: destinations,
    );
  }
}
