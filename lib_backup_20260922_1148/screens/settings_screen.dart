import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../services/language_service.dart';
import '../services/locale_strings.dart';

class SettingsScreen extends StatelessWidget {
  final ThemeService themeService;
  final LanguageService languageService;

  const SettingsScreen({
    super.key,
    required this.themeService,
    required this.languageService,
  });

  @override
  Widget build(BuildContext context) {
    final l = L(languageService.lang);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.settingsTheme, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Text(l.settingsDark),
                        selected: themeService.isDark,
                        onSelected: (_) => themeService.setMode(AppThemeMode.dark),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: Text(l.settingsLight),
                        selected: !themeService.isDark,
                        onSelected: (_) => themeService.setMode(AppThemeMode.light),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('رنگ اصلی', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _colorBox(AppColorScheme.blue, const Color(0xFF2196F3), l.settingsColorBlue)),
                    const SizedBox(width: 8),
                    Expanded(child: _colorBox(AppColorScheme.green, const Color(0xFF00DCA0), l.settingsColorGreen)),
                    const SizedBox(width: 8),
                    Expanded(child: _colorBox(AppColorScheme.purple, const Color(0xFF9C27B0), l.settingsColorPurple)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.settingsLanguage, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                RadioListTile<AppLanguage>(
                  title: Text(l.settingsFarsi),
                  value: AppLanguage.fa,
                  groupValue: languageService.lang,
                  onChanged: (v) => languageService.setLanguage(v!),
                ),
                RadioListTile<AppLanguage>(
                  title: Text(l.settingsEnglish),
                  value: AppLanguage.en,
                  groupValue: languageService.lang,
                  onChanged: (v) => languageService.setLanguage(v!),
                ),
                RadioListTile<AppLanguage>(
                  title: Text(l.settingsArabic),
                  value: AppLanguage.ar,
                  groupValue: languageService.lang,
                  onChanged: (v) => languageService.setLanguage(v!),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.settingsAbout, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('تایم لاگر نسخه ۲.۰.۰', style: TextStyle(fontSize: 13)),
                const Text('سازنده: کورش شیراز', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _colorBox(AppColorScheme scheme, Color color, String label) {
    final selected = themeService.color == scheme;
    return GestureDetector(
      onTap: () => themeService.setColor(scheme),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: selected ? Border.all(color: Colors.white, width: 3) : null,
        ),
        child: Center(
          child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}