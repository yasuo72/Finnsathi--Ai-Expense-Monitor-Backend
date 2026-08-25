import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

class ThemeToggleWidget extends StatelessWidget {
  final bool showLabel;
  final double scale;
  
  const ThemeToggleWidget({
    Key? key,
    this.showLabel = true,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel)
          Text(
            isDark ? 'Dark Mode' : 'Light Mode',
            style: TextStyle(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black87,
            ),
          ),
        if (showLabel) SizedBox(width: 8),
        Transform.scale(
          scale: scale,
          child: Switch(
            value: isDark,
            onChanged: (value) {
              themeService.setDarkMode(value);
            },
            activeColor: Theme.of(context).colorScheme.secondary,
            activeTrackColor: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}

// A simpler icon button version for app bars and other compact spaces
class ThemeToggleIconButton extends StatelessWidget {
  const ThemeToggleIconButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;
    
    return IconButton(
      icon: Icon(
        isDark ? Icons.light_mode : Icons.dark_mode,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87,
      ),
      onPressed: () {
        themeService.toggleTheme();
      },
      tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
    );
  }
}
