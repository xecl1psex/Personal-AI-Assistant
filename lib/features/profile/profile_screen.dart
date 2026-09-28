import 'package:flutter/material.dart';

import '../../shared/widgets/feature_screen_scaffold.dart';

/// Profile screen: user data, avatar, AI context about the owner.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const String routeName = '/profile';

  @override
  Widget build(BuildContext context) {
    return FeatureScreenScaffold(
      title: 'Профиль',
      screenName: 'Профиль',
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Настройки',
          onPressed: () {
            Navigator.of(context).pushNamed(SettingsScreenRoutes.settings);
          },
        ),
      ],
    );
  }
}

/// Route-name holder to avoid a circular import between features.
class SettingsScreenRoutes {
  static const String settings = '/settings';
}
