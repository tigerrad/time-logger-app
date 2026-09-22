import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'providers/data_provider.dart';
import 'l10n/strings.dart';
import 'screens/timer_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/savings_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/publications_screen.dart';
import 'screens/meetings_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TimeLoggerApp());
}

class TimeLoggerApp extends StatelessWidget {
  const TimeLoggerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, theme, lang, _) {
          final s = S(lang.lang);
          return MaterialApp(
            title: s.appTitle,
            debugShowCheckedModeBanner: false,
            theme: theme.theme,
            locale: lang.locale,
            supportedLocales: const [
              Locale('fa', 'IR'),
              Locale('en', 'US'),
              Locale('ar', 'SA'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              return Directionality(
                textDirection: lang.direction,
                child: child!,
              );
            },
            home: const HomePage(),
          );
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final theme = context.watch<ThemeProvider>();
    final lang = context.watch<LanguageProvider>();
    final s = S(lang.lang);

    if (data.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = [
      const TimerScreen(),
      const GoalsScreen(),
      const SavingsScreen(),
      const FinanceScreen(),
      const PublicationsScreen(),
      const MeetingsScreen(),
      const ReportsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(s.appTitle, style: const TextStyle(fontSize: 14)),
        centerTitle: true,
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: theme.isDark ? const Color(0xFF26262E) : Colors.white,
        indicatorColor: theme.primaryColor.withOpacity(0.3),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.timer), label: s.tabTimer),
          NavigationDestination(icon: const Icon(Icons.flag), label: s.tabGoals),
          NavigationDestination(icon: const Icon(Icons.savings), label: s.tabSavings),
          NavigationDestination(icon: const Icon(Icons.account_balance_wallet), label: s.tabFinance),
          NavigationDestination(icon: const Icon(Icons.menu_book), label: s.tabPublications),
          NavigationDestination(icon: const Icon(Icons.event), label: s.tabMeetings),
          NavigationDestination(icon: const Icon(Icons.bar_chart), label: s.tabReports),
          NavigationDestination(icon: const Icon(Icons.settings), label: s.tabSettings),
        ],
      ),
    );
  }
}