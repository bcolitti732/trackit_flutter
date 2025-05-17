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

  List<Map<String, dynamic>> get _pages {
    final localizations = AppLocalizations.of(context)!;
    return [
      {'title': localizations.home, 'route': '/', 'icon': Icons.home},
      {'title': localizations.profile, 'route': '/profile', 'icon': Icons.account_circle},
      {'title': localizations.chat, 'route': '/contactList', 'icon': Icons.chat},
    ];
  }

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

    return Scaffold(
      appBar: AppBar(
        title: Text(_pages[_currentIndex]['title']),
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
        items: _pages.map((page) {
          return BottomNavigationBarItem(
            icon: Icon(page['icon']),
            label: page['title'],
          );
        }).toList(),
      ),
    );
  }
}
