import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../settings/settings_screen.dart';
import '../dashboard/dashboard_screen.dart';

/// First-launch welcome screen.
///
/// Shows the app logo, the tagline "Твой приватный ассистент" and a
/// "Начать настройку" button. Finishing onboarding persists
/// [AppConstants.prefOnboardingCompleted] so it is shown only once.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.onFinished});

  /// Optional callback invoked after the onboarding flag was stored
  /// (used by `_RootGate` in app.dart to swap the root screen).
  final VoidCallback? onFinished;

  static const String routeName = '/onboarding';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _finishing = false;

  Future<void> _startSetup() async {
    if (_finishing) return;
    setState(() => _finishing = true);

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.prefOnboardingCompleted, true);
    } catch (e) {
      debugPrint('OnboardingScreen: failed to persist flag: $e');
    }

    if (!mounted) return;

    if (widget.onFinished != null) {
      widget.onFinished!.call();
    } else {
      // Opened as a standalone route — go to the main navigation flow.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text(AppConstants.appName)),
            body: const DashboardScreen(),
          ),
        ),
      );
    }
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            children: <Widget>[
              const Spacer(flex: 2),

              // ----------------------------------------------------------------
              // Logo
              // ----------------------------------------------------------------
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[scheme.primaryContainer, scheme.primary],
                  ),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 56,
                  color: scheme.onPrimaryContainer,
                ),
              ),

              const SizedBox(height: 40),

              // ----------------------------------------------------------------
              // Headline + description
              // ----------------------------------------------------------------
              Text(
                AppConstants.appName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Твой приватный ассистент',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Финансы, задачи и чат с ИИ — всё хранится только '
                'на твоём устройстве. Никакого облака.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 3),

              // ----------------------------------------------------------------
              // Feature bullets
              // ----------------------------------------------------------------
              _FeatureRow(
                icon: Icons.lock_outline,
                text: 'Полностью локальное хранение данных',
              ),
              const SizedBox(height: 12),
              _FeatureRow(
                icon: Icons.account_balance_wallet_outlined,
                text: 'Учёт финансов и бюджетов',
              ),
              const SizedBox(height: 12),
              _FeatureRow(
                icon: Icons.check_circle_outline,
                text: 'Задачи, привычки и план на день',
              ),

              const SizedBox(height: 40),

              // ----------------------------------------------------------------
              // CTA
              // ----------------------------------------------------------------
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _finishing ? null : _startSetup,
                  icon: _finishing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.rocket_launch_outlined),
                  label: const Text('Начать настройку'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openSettings,
                  icon: const Icon(Icons.palette_outlined),
                  label: const Text('Настроить тему'),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small icon + text row used for the feature list.
class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }
}
