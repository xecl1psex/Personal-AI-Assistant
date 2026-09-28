import 'package:flutter/material.dart';

import '../../shared/widgets/feature_screen_scaffold.dart';

/// Dashboard screen: quick overview of finances, tasks and AI suggestions.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const String routeName = '/dashboard';

  @override
  Widget build(BuildContext context) {
    return const FeatureScreenScaffold(
      title: 'Дашборд',
      screenName: 'Дашборд',
    );
  }
}
