import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants.dart';
import 'core/theme/theme_provider.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/settings/settings_screen.dart';
import 'shared/widgets/main_navigation.dart';

/// Root widget: Material 3 [MaterialApp].
///
/// * Theme is rebuilt from [ThemeProvider] on every accent/brightness change.
/// * On first launch (onboarding not completed) shows [OnboardingScreen],
///   otherwise goes straight to [MainNavigation].
class PersonalAiApp extends StatelessWidget {
  const PersonalAiApp({super.key});

  static const String routeSettings = '/settings';

  @override
  Widget build(BuildContext context) {
    // Consumer<ThemeProvider>: rebuilds MaterialApp when theme changes.
    return Consumer<ThemeProvider>(
      builder: (BuildContext context, ThemeProvider theme, Widget? child) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,

          // Dark minimal theme with configurable seed color (Material 3).
          theme: theme.themeData,
          darkTheme: theme.themeData,
          themeMode: theme.isDarkMode ? ThemeMode.dark : ThemeMode.light,

          // First screen depends on onboarding state.
          home: const _RootGate(),

          routes: <String, WidgetBuilder>{
            MainNavigation.routeName: (_) => const MainNavigation(),
            routeSettings: (_) => const SettingsScreen(),
          },
        );
      },
    );
  }
}

/// Decides between [OnboardingScreen] (first launch) and [MainNavigation].
class _RootGate extends StatefulWidget {
  const _RootGate();

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  late Future<bool> _onboardingDone;

  @override
  void initState() {
    super.initState();
    _onboardingDone = _readOnboardingFlag();
  }

  Future<bool> _readOnboardingFlag() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.prefOnboardingCompleted) ?? false;
  }

  void _completeOnboarding() {
    Navigator.of(context).pushReplacementNamed(MainNavigation.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _onboardingDone,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          // Tiny splash while the flag is being read.
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data ?? false) {
          return const MainNavigation();
        }
        return OnboardingScreen(onFinished: _completeOnboarding);
      },
    );
  }
}
