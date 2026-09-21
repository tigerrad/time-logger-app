import 'package:flutter/material.dart';
import 'models/domain.dart';
import 'models/time_entry.dart';
import 'models/goal.dart';
import 'models/saving.dart';
import 'models/meeting.dart';
import 'models/finance_transaction.dart';
import 'models/finance_category.dart';
import 'services/store.dart';
import 'services/notification_service.dart';
import 'screens/timer_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/savings_screen.dart';
import 'screens/meetings_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/reports_screen.dart';
import 'widgets/common.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const TimeLoggerApp());
}

class TimeLoggerApp extends StatelessWidget {
  const TimeLoggerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تایم لاگر — کورش شیراز',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF26262E),
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const HomePage(),
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

  List<Domain> domains = [];
  List<TimeEntry> entries = [];
  List<Goal> goals = [];
  List<Saving> savings = [];
  List<Meeting> meetings = [];
  List<FinanceTransaction> financeTx = [];
  List<FinanceCategory> financeCat = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    domains = await Store.loadDomains();
    entries = await Store.loadEntries();
    goals = await Store.loadGoals();
    savings = await Store.loadSavings();
    meetings = await Store.loadMeetings();
    financeTx = await Store.loadFinanceTransactions();
    financeCat = await Store.loadFinanceCategories();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _saveEntries() async => await Store.saveEntries(entries);
  Future<void> _saveGoals() async => await Store.saveGoals(goals);
  Future<void> _saveSavings() async => await Store.saveSavings(savings);
  Future<void> _saveMeetings() async => await Store.saveMeetings(meetings);
  Future<void> _saveFinance() async {
    await Store.saveFinanceTransactions(financeTx);
    await Store.saveFinanceCategories(financeCat);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = [
      TimerScreen(
        domains: domains,
        entries: entries,
        onChanged: () async {
          await _saveEntries();
          if (!mounted) return;
          setState(() {});
        },
      ),
      GoalsScreen(
        domains: domains,
        goals: goals,
        onChanged: () async {
          await _saveGoals();
          if (!mounted) return;
          setState(() {});
        },
      ),
      SavingsScreen(
        savings: savings,
        onChanged: () async {
          await _saveSavings();
          if (!mounted) return;
          setState(() {});
        },
      ),
      MeetingsScreen(
        meetings: meetings,
        onChanged: () async {
          await _saveMeetings();
          if (!mounted) return;
          setState(() {});
        },
      ),
      FinanceScreen(
        transactions: financeTx,
        categories: financeCat,
        onChanged: () async {
          await _saveFinance();
          if (!mounted) return;
          setState(() {});
        },
      ),
      ReportsScreen(entries: entries),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تایم لاگر — سازنده: کورش شیراز',
          style: TextStyle(fontSize: 14),
        ),
        centerTitle: true,
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: const Color(0xFF26262E),
        indicatorColor: AppColors.primary.withOpacity(0.3),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.timer), label: 'تایم'),
          NavigationDestination(icon: Icon(Icons.flag), label: 'اهداف'),
          NavigationDestination(icon: Icon(Icons.savings), label: 'پس‌انداز'),
          NavigationDestination(icon: Icon(Icons.event), label: 'جلسات'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'مالی'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'گزارش'),
        ],
      ),
    );
  }
}