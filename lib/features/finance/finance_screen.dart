import 'package:flutter/material.dart';

import '../../shared/widgets/feature_screen_scaffold.dart';

/// Finance screen: transactions, categories, budgets.
class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  static const String routeName = '/finance';

  @override
  Widget build(BuildContext context) {
    return const FeatureScreenScaffold(
      title: 'Финансы',
      screenName: 'Финансы',
    );
  }
}
