import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme/theme_provider.dart';

/// A row/wrap of 8 circular swatches ([AppConstants.seedColors]).
///
/// Tapping a circle updates [ThemeProvider.setSeedColorByIndex], which
/// rebuilds the whole app theme and persists the choice via SharedPreferences.
class AccentColorPicker extends StatelessWidget {
  const AccentColorPicker({
    super.key,
    this.circleSize = 44,
    this.spacing = 12,
  });

  /// Diameter of each color circle.
  final double circleSize;

  /// Horizontal / vertical gap between circles.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final ThemeProvider theme = context.watch<ThemeProvider>();
    final int selectedIndex = theme.seedColorIndex;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      alignment: WrapAlignment.center,
      children: List<Widget>.generate(
        AppConstants.seedColors.length,
        (int index) {
          final Color color = Color(AppConstants.seedColors[index]);
          final bool isSelected = index == selectedIndex;
          final String name = index < AppConstants.seedColorNames.length
              ? AppConstants.seedColorNames[index]
              : 'Цвет ${index + 1}';

          return Tooltip(
            message: name,
            child: GestureDetector(
              onTap: () => theme.setSeedColorByIndex(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: isSelected
                      ? <BoxShadow>[
                          BoxShadow(
                            color: color.withAlpha(90),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: circleSize * 0.5,
                        color: _contrastColor(color),
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Picks black or white check-mark color depending on swatch luminance.
  static Color _contrastColor(Color background) =>
      ThemeData.estimateBrightnessForColor(background) == Brightness.dark
          ? Colors.white
          : Colors.black;
}
