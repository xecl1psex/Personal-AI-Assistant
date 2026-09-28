import 'package:flutter/material.dart';

import '../../shared/widgets/feature_screen_scaffold.dart';

/// Tasks screen: today's plan, weekly view and habits.
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  static const String routeName = '/tasks';

  @override
  Widget build(BuildContext context) {
    return const FeatureScreenScaffold(
      title: 'Задачи',
      screenName: 'Задачи',
    );
  }
}
