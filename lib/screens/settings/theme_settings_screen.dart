import 'package:fitcoach_/services/theme_manager.dart';
import 'package:flutter/material.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final accentColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Theme Settings",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: ThemeManager.instance,
        builder: (context, child) {
          final currentMode = ThemeManager.instance.themeMode;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildThemeOption(
                      context: context,
                      title: "System Default",
                      subtitle: "Matches your phone's dark/light mode",
                      icon: Icons.brightness_auto,
                      value: ThemeMode.system,
                      groupValue: currentMode,
                      accentColor: accentColor,
                      isDark: isDark,
                    ),
                    Divider(
                      color: isDark ? Colors.white10 : Colors.black12,
                      height: 1,
                    ),
                    _buildThemeOption(
                      context: context,
                      title: "Light Mode",
                      subtitle: "Bright and clean",
                      icon: Icons.light_mode,
                      value: ThemeMode.light,
                      groupValue: currentMode,
                      accentColor: accentColor,
                      isDark: isDark,
                    ),
                    Divider(
                      color: isDark ? Colors.white10 : Colors.black12,
                      height: 1,
                    ),
                    _buildThemeOption(
                      context: context,
                      title: "Dark Mode",
                      subtitle: "Easy on the eyes (and battery)",
                      icon: Icons.dark_mode,
                      value: ThemeMode.dark,
                      groupValue: currentMode,
                      accentColor: accentColor,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeMode value,
    required ThemeMode groupValue,
    required Color accentColor,
    required bool isDark,
  }) {
    return RadioListTile<ThemeMode>(
      value: value,
      groupValue: groupValue,
      onChanged: (ThemeMode? newMode) {
        if (newMode != null) {
          ThemeManager.instance.changeTheme(newMode);
        }
      },
      activeColor: accentColor,
      secondary: Icon(icon, color: isDark ? Colors.white : Colors.black),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? Colors.grey : Colors.black54,
          fontSize: 12,
        ),
      ),
    );
  }
}
