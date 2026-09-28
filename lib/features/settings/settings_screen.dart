import 'package:flutter/material.dart';

import '../../shared/widgets/feature_screen_scaffold.dart';

/// Settings screen: theme, AI provider, API keys, data management.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String routeName = '/settings';

  @override
  Widget build(BuildContext context) {
    return const FeatureScreenScaffold(
      title: 'Настройки',
      screenName: 'Настройки',
    );
  }
}
