import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LayoutWrapper extends StatefulWidget {
  final Widget child;
  final String title;

  const LayoutWrapper({
    super.key,
    required this.child,
    required this.title,
  });

  @override
  State<LayoutWrapper> createState() => _LayoutWrapperState();
}

class _LayoutWrapperState extends State<LayoutWrapper> {
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _pages = [
    {'route': '/', 'icon': Icons.home},
    {'route': '/profile', 'icon': Icons.account_circle},
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    context.go(_pages[index]['route']);
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouter.of(context).routerDelegate.currentConfiguration.fullPath;
    final newIndex = _pages.indexWhere((page) => page['route'] == currentRoute);
    if (newIndex != -1 && newIndex != _currentIndex) {
      setState(() {
        _currentIndex = newIndex;
      });
    }

    // Cargar los títulos traducidos
    final homeTitle = AppLocalizations.of(context)!.home;
    final profileTitle = AppLocalizations.of(context)!.profile;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? homeTitle : profileTitle),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 2,
      ),
      body: Container(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1),
        child: widget.child,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface,
        items: [
          BottomNavigationBarItem(
            icon: Icon(_pages[0]['icon']),
            label: homeTitle,  // Usar el texto traducido
          ),
          BottomNavigationBarItem(
            icon: Icon(_pages[1]['icon']),
            label: profileTitle,  // Usar el texto traducido
          ),
        ],
      ),
    );
  }
}
