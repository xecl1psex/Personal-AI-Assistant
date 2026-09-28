import 'package:flutter/material.dart';

/// Generic scaffold used by all feature screens while they are stubs.
class FeatureScreenScaffold extends StatelessWidget {
  const FeatureScreenScaffold({
    super.key,
    required this.title,
    required this.screenName,
    this.actions,
  });

  final String title;
  final String screenName;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.auto_awesome,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Экран $screenName — в разработке',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
