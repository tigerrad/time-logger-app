import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../l10n/strings.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final lang = context.watch<LanguageProvider>();
    final s = S(lang.lang);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // ==== تم ====
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.brightness_6, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  Text(s.settingsTheme, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text(s.settingsDark),
                      selected: theme.isDark,
                      onSelected: (_) => theme.setMode(AppThemeMode.dark),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: Text(s.settingsLight),
                      selected: !theme.isDark,
                      onSelected: (_) => theme.setMode(AppThemeMode.light),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ==== رنگ اصلی ====
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.palette, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  Text(s.settingsColor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _colorBox(context, theme, AppColorScheme.blue, const Color(0xFF2196F3), s.settingsColorBlue)),
                  const SizedBox(width: 8),
                  Expanded(child: _colorBox(context, theme, AppColorScheme.green, const Color(0xFF00DCA0), s.settingsColorGreen)),
                  const SizedBox(width: 8),
                  Expanded(child: _colorBox(context, theme, AppColorScheme.purple, const Color(0xFF9C27B0), s.settingsColorPurple)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ==== زبان ====
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.language, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  Text(s.settingsLanguage, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              RadioListTile<AppLanguage>(
                title: Text(s.settingsFarsi),
                value: AppLanguage.fa,
                groupValue: lang.lang,
                onChanged: (v) => lang.setLanguage(v!),
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<AppLanguage>(
                title: Text(s.settingsEnglish),
                value: AppLanguage.en,
                groupValue: lang.lang,
                onChanged: (v) => lang.setLanguage(v!),
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<AppLanguage>(
                title: Text(s.settingsArabic),
                value: AppLanguage.ar,
                groupValue: lang.lang,
                onChanged: (v) => lang.setLanguage(v!),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ==== امنیت ====
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lock, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  Text(s.settingsSecurity, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: Text(s.settingsPinLock),
                value: false,
                onChanged: (v) => showSnack(context, s.comingSoon),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: Text(s.settingsFingerprint),
                value: false,
                onChanged: (v) => showSnack(context, s.comingSoon),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ==== درباره ====
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  Text(s.settingsAbout, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Text(s.appTitle),
              const SizedBox(height: 4),
              Text('${s.settingsVersion} 3.0.0', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 12),
              PrimaryButton(
                label: s.settingsCheckUpdate,
                icon: Icons.refresh,
                color: theme.secondaryColor,
                onPressed: () => showSnack(context, s.settingsUpToDate),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _colorBox(
    BuildContext context,
    ThemeProvider theme,
    AppColorScheme scheme,
    Color color,
    String label,
  ) {
    final selected = theme.color == scheme;
    return GestureDetector(
      onTap: () => theme.setColor(scheme),
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: selected ? Border.all(color: Colors.white, width: 3) : null,
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}