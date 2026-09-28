import 'package:flutter/material.dart';

import '../../shared/widgets/feature_screen_scaffold.dart';

/// AI chat screen: conversation with the selected model.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  static const String routeName = '/chat';

  @override
  Widget build(BuildContext context) {
    return const FeatureScreenScaffold(
      title: 'Чат',
      screenName: 'Чат',
    );
  }
}
