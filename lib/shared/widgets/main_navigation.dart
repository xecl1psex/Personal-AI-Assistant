import 'package:flutter/material.dart';

import '../dashboard/dashboard_screen.dart';
import '../chat/chat_screen.dart';
import '../finance/finance_screen.dart';
import '../tasks/tasks_screen.dart';
import '../profile/profile_screen.dart';

/// Root navigation: Material 3 [NavigationBar] with 5 tabs.
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key, this.initialIndex = 0});

  /// Tab shown after onboarding (0 = Dashboard).
  final int initialIndex;

  static const String routeName = '/';

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _index = widget.initialIndex;

  static const List<Widget> _screens = <Widget>[
    DashboardScreen(),
    ChatScreen(),
    FinanceScreen(),
    TasksScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        showUnselectedLabels: true,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: 'Дашборд',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: 'Чат',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Финансы',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Задачи',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
        onDestinationSelected: (int i) => setState(() => _index = i),
      ),
    );
  }
}
