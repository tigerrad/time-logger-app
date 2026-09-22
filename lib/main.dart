import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'models/domain.dart';
import 'models/time_entry.dart';
import 'models/goal.dart';
import 'models/saving.dart';
import 'models/meeting.dart';
import 'services/store.dart';
import 'services/theme_service.dart';
import 'services/language_service.dart';
import 'services/locale_strings.dart';
import 'screens/timer_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/savings_screen.dart';
import 'screens/meetings_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const TimeLoggerApp());
}

class TimeLoggerApp extends StatefulWidget {
  const TimeLoggerApp({super.key});

  @override
  State<TimeLoggerApp> createState() => _TimeLoggerAppState();
}

class _TimeLoggerAppState extends State<TimeLoggerApp> {
  final ThemeService _themeService = ThemeService();
  final LanguageService _languageService = LanguageService();

  @override
  void initState() {
    super.initState();
    _themeService.addListener(_onChange);
    _languageService.addListener(_onChange);
  }

  @override
  void dispose() {
    _themeService.removeListener(_onChange);
    _languageService.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = L(_languageService.lang);
    return MaterialApp(
      title: l.appTitle,
      debugShowCheckedModeBanner: false,
      theme: _themeService.theme,
      locale: _languageService.locale,
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
          textDirection: _languageService.direction,
          child: child!,
        );
      },
      home: HomePage(
        themeService: _themeService,
        languageService: _languageService,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final ThemeService themeService;
  final LanguageService languageService;

  const HomePage({
    super.key,
    required this.themeService,
    required this.languageService,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  List<Domain> domains = [];
  List<TimeEntry> entries = [];
  List<Goal> goals = [];
  List<Saving> savings = [];
  List<Meeting> meetings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
    widget.languageService.addListener(_onLangChange);
  }

  @override
  void dispose() {
    widget.languageService.removeListener(_onLangChange);
    super.dispose();
  }

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  Future<void> _loadAll() async {
    domains = await Store.loadDomains();
    entries = await Store.loadEntries();
    goals = await Store.loadGoals();
    savings = await Store.loadSavings();
    meetings = await Store.loadMeetings();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final l = L(widget.languageService.lang);

    final pages = [
      TimerScreen(
        domains: domains,
        entries: entries,
        onChanged: () async {
          await Store.saveEntries(entries);
          if (!mounted) return;
          setState(() {});
        },
      ),
      GoalsScreen(
        domains: domains,
        goals: goals,
        onChanged: () async {
          await Store.saveGoals(goals);
          if (!mounted) return;
          setState(() {});
        },
      ),
      SavingsScreen(
        savings: savings,
        onChanged: () async {
          await Store.saveSavings(savings);
          if (!mounted) return;
          setState(() {});
        },
      ),
      MeetingsScreen(
        meetings: meetings,
        onChanged: () async {
          await Store.saveMeetings(meetings);
          if (!mounted) return;
          setState(() {});
        },
      ),
      ReportsScreen(entries: entries),
      SettingsScreen(
        themeService: widget.themeService,
        languageService: widget.languageService,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle, style: const TextStyle(fontSize: 14)),
        centerTitle: true,
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Theme.of(context).cardColor,
        indicatorColor: widget.themeService.primaryColor.withOpacity(0.3),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.timer), label: l.tabTimer),
          NavigationDestination(icon: const Icon(Icons.flag), label: l.tabGoals),
          NavigationDestination(icon: const Icon(Icons.savings), label: l.tabSavings),
          NavigationDestination(icon: const Icon(Icons.event), label: l.tabMeetings),
          NavigationDestination(icon: const Icon(Icons.bar_chart), label: l.tabReports),
          NavigationDestination(icon: const Icon(Icons.settings), label: l.tabSettings),
        ],
      ),
    );
  }
}