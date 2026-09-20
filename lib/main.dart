import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart' hide TextDirection;

void main() {
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
        scaffoldBackgroundColor: const Color(0xFF1C1C20),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00DCA0),
          secondary: Color(0xFF3C82C8),
          surface: Color(0xFF2D2D34),
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

// ============================================================
// مدل‌های داده
// ============================================================

class Domain {
  final int id;
  final String name;
  final String nameEn;
  final String color;
  Domain({required this.id, required this.name, required this.nameEn, required this.color});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'nameEn': nameEn, 'color': color};
  factory Domain.fromJson(Map<String, dynamic> j) => Domain(
    id: j['id'] ?? 0,
    name: j['name'] ?? '',
    nameEn: j['nameEn'] ?? '',
    color: j['color'] ?? '#888888',
  );
}

class TimeEntry {
  final int id;
  final String domain;
  final String start;
  final String end;
  final int minutes;
  final String note;
  TimeEntry({required this.id, required this.domain, required this.start, required this.end, required this.minutes, required this.note});

  Map<String, dynamic> toJson() => {'id': id, 'domain': domain, 'start': start, 'end': end, 'minutes': minutes, 'note': note};
  factory TimeEntry.fromJson(Map<String, dynamic> j) => TimeEntry(
    id: j['id'] ?? 0,
    domain: j['domain'] ?? '',
    start: j['start'] ?? '',
    end: j['end'] ?? '',
    minutes: j['minutes'] ?? 0,
    note: j['note'] ?? '',
  );
}

class Goal {
  final int id;
  String title;
  String level;
  String domain;
  int progress;
  Goal({required this.id, required this.title, required this.level, required this.domain, required this.progress});

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'level': level, 'domain': domain, 'progress': progress};
  factory Goal.fromJson(Map<String, dynamic> j) => Goal(
    id: j['id'] ?? 0,
    title: j['title'] ?? '',
    level: j['level'] ?? '',
    domain: j['domain'] ?? '',
    progress: j['progress'] ?? 0,
  );
}

class Saving {
  final int id;
  String title;
  double target;
  double current;
  Saving({required this.id, required this.title, required this.target, required this.current});

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'target': target, 'current': current};
  factory Saving.fromJson(Map<String, dynamic> j) => Saving(
    id: j['id'] ?? 0,
    title: j['title'] ?? '',
    target: (j['target'] ?? 0).toDouble(),
    current: (j['current'] ?? 0).toDouble(),
  );
}

class Meeting {
  final int id;
  String title;
  String link;
  String time;
  int duration;
  Meeting({required this.id, required this.title, required this.link, required this.time, required this.duration});

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'link': link, 'time': time, 'duration': duration};
  factory Meeting.fromJson(Map<String, dynamic> j) => Meeting(
    id: j['id'] ?? 0,
    title: j['title'] ?? '',
    link: j['link'] ?? '',
    time: j['time'] ?? '',
    duration: j['duration'] ?? 0,
  );
}

// ============================================================
// ذخیره‌سازی
// ============================================================

class Store {
  static const _kDomains = 'domains';
  static const _kEntries = 'entries';
  static const _kGoals = 'goals';
  static const _kSavings = 'savings';
  static const _kMeetings = 'meetings';

  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  static Future<List<Domain>> loadDomains() async {
    final p = await _prefs;
    final raw = p.getString(_kDomains);
    if (raw == null) {
      final defaults = [
        Domain(id: 1, name: 'خواب', nameEn: 'Sleep', color: '#7B8FA1'),
        Domain(id: 2, name: 'خانواده', nameEn: 'Family', color: '#C85A3C'),
        Domain(id: 3, name: 'تفریح و سرگرمی', nameEn: 'Leisure', color: '#E6A0AA'),
        Domain(id: 4, name: 'مراقبت از خود', nameEn: 'Self-Care', color: '#A878D2'),
        Domain(id: 5, name: 'خدمت و بهبودی', nameEn: 'Service', color: '#6EA05A'),
        Domain(id: 6, name: 'چشم انداز', nameEn: 'Vision', color: '#D2AA28'),
        Domain(id: 7, name: 'کسب و کار', nameEn: 'Work', color: '#3C82C8'),
        Domain(id: 8, name: 'ابهام در زمان', nameEn: 'Unknown', color: '#78503C'),
      ];
      await saveDomains(defaults);
      return defaults;
    }
    final list = jsonDecode(raw) as List;
    return list.map((e) => Domain.fromJson(e)).toList();
  }

  static Future<void> saveDomains(List<Domain> d) async {
    final p = await _prefs;
    await p.setString(_kDomains, jsonEncode(d.map((e) => e.toJson()).toList()));
  }

  static Future<List<TimeEntry>> loadEntries() async {
    final p = await _prefs;
    final raw = p.getString(_kEntries);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => TimeEntry.fromJson(e)).toList();
  }

  static Future<void> saveEntries(List<TimeEntry> e) async {
    final p = await _prefs;
    await p.setString(_kEntries, jsonEncode(e.map((x) => x.toJson()).toList()));
  }

  static Future<List<Goal>> loadGoals() async {
    final p = await _prefs;
    final raw = p.getString(_kGoals);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Goal.fromJson(e)).toList();
  }

  static Future<void> saveGoals(List<Goal> g) async {
    final p = await _prefs;
    await p.setString(_kGoals, jsonEncode(g.map((e) => e.toJson()).toList()));
  }

  static Future<List<Saving>> loadSavings() async {
    final p = await _prefs;
    final raw = p.getString(_kSavings);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Saving.fromJson(e)).toList();
  }

  static Future<void> saveSavings(List<Saving> s) async {
    final p = await _prefs;
    await p.setString(_kSavings, jsonEncode(s.map((e) => e.toJson()).toList()));
  }

  static Future<List<Meeting>> loadMeetings() async {
    final p = await _prefs;
    final raw = p.getString(_kMeetings);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Meeting.fromJson(e)).toList();
  }

  static Future<void> saveMeetings(List<Meeting> m) async {
    final p = await _prefs;
    await p.setString(_kMeetings, jsonEncode(m.map((e) => e.toJson()).toList()));
  }
}

// ============================================================
// ابزار تاریخ شمسی
// ============================================================

String toJalali(DateTime dt) {
  final f = DateFormat('yyyy/MM/dd HH:mm');
  try {
    final g = gregorianToJalali(dt);
    return '${g[0]}/${g[1].toString().padLeft(2, '0')}/${g[2].toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return f.format(dt);
  }
}

List<int> gregorianToJalali(DateTime g) {
  final gy = g.year, gm = g.month, gd = g.day;
  final gDaysInMonth = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  var gy2 = (gm > 2) ? (gy + 1) : gy;
  var days = 355666 + (365 * gy) + ((gy2 + 3) ~/ 4) - ((gy2 + 99) ~/ 100) + ((gy2 + 399) ~/ 400) + gd + gDaysInMonth.sublist(0, gm).reduce((a, b) => a + b);
  var jy = -1595 + (33 * (days ~/ 12053));
  days %= 12053;
  jy += 4 * (days ~/ 1461);
  days %= 1461;
  if (days > 365) {
    jy += ((days - 1) ~/ 365);
    days = (days - 1) % 365;
  }
  int jm, jd;
  if (days < 186) {
    jm = 1 + (days ~/ 31);
    jd = 1 + (days % 31);
  } else {
    jm = 7 + ((days - 186) ~/ 30);
    jd = 1 + ((days - 186) % 30);
  }
  return [jy, jm, jd];
}

// ============================================================
// صفحه اصلی
// ============================================================

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
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final pages = [
      TimerTab(
        domains: domains,
        entries: entries,
        onEntriesChanged: () async {
          await Store.saveEntries(entries);
          setState(() {});
        },
      ),
      GoalsTab(
        domains: domains,
        goals: goals,
        onChanged: () async {
          await Store.saveGoals(goals);
          setState(() {});
        },
      ),
      SavingsTab(
        savings: savings,
        onChanged: () async {
          await Store.saveSavings(savings);
          setState(() {});
        },
      ),
      MeetingsTab(
        meetings: meetings,
        onChanged: () async {
          await Store.saveMeetings(meetings);
          setState(() {});
        },
      ),
      ReportsTab(entries: entries),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('تایم لاگر — سازنده: کورش شیراز', style: TextStyle(fontSize: 16)),
        centerTitle: true,
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: const Color(0xFF26262E),
        indicatorColor: const Color(0xFF00DCA0).withOpacity(0.3),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.timer), label: 'تایم'),
          NavigationDestination(icon: Icon(Icons.flag), label: 'اهداف'),
          NavigationDestination(icon: Icon(Icons.savings), label: 'پس‌انداز'),
          NavigationDestination(icon: Icon(Icons.event), label: 'جلسات'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'گزارش'),
        ],
      ),
    );
  }
}

// ============================================================
// تب ۱: تایم‌ترکینگ
// ============================================================

class TimerTab extends StatefulWidget {
  final List<Domain> domains;
  final List<TimeEntry> entries;
  final Future<void> Function() onEntriesChanged;

  const TimerTab({super.key, required this.domains, required this.entries, required this.onEntriesChanged});

  @override
  State<TimerTab> createState() => _TimerTabState();
}

class _TimerTabState extends State<TimerTab> {
  bool _isRunning = false;
  DateTime? _startTime;
  String? _selectedDomain;
  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _manualMinCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.domains.isNotEmpty) _selectedDomain = widget.domains.first.name;
    _tick();
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {});
        _tick();
      }
    });
  }

  String _elapsedText() {
    if (!_isRunning || _startTime == null) return '00:00:00';
    final d = DateTime.now().difference(_startTime!);
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _start() async {
    if (_selectedDomain == null) return;
    setState(() {
      _isRunning = true;
      _startTime = DateTime.now();
    });
  }

  Future<void> _stop() async {
    if (_startTime == null) return;
    final end = DateTime.now();
    final mins = end.difference(_startTime!).inMinutes;
    final newId = widget.entries.isEmpty ? 1 : (widget.entries.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
    widget.entries.add(TimeEntry(
      id: newId,
      domain: _selectedDomain!,
      start: _startTime!.toIso8601String(),
      end: end.toIso8601String(),
      minutes: mins < 1 ? 1 : mins,
      note: _noteCtrl.text,
    ));
    await widget.onEntriesChanged();
    setState(() {
      _isRunning = false;
      _startTime = null;
      _noteCtrl.clear();
    });
  }

  Future<void> _manualAdd() async {
    final m = int.tryParse(_manualMinCtrl.text);
    if (m == null || m < 1 || _selectedDomain == null) return;
    final now = DateTime.now();
    final start = now.subtract(Duration(minutes: m));
    final newId = widget.entries.isEmpty ? 1 : (widget.entries.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
    widget.entries.add(TimeEntry(
      id: newId,
      domain: _selectedDomain!,
      start: start.toIso8601String(),
      end: now.toIso8601String(),
      minutes: m,
      note: _noteCtrl.text,
    ));
    await widget.onEntriesChanged();
    setState(() {
      _manualMinCtrl.clear();
      _noteCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.entries]..sort((a, b) => b.id.compareTo(a.id));
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // انتخاب حوزه
          Row(
            children: [
              const Text('حوزه:', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedDomain,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF373741),
                  items: widget.domains.map((d) => DropdownMenuItem(value: d.name, child: Text(d.name))).toList(),
                  onChanged: (v) => setState(() => _selectedDomain = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // یادداشت
          TextField(
            controller: _noteCtrl,
            decoration: InputDecoration(
              labelText: 'یادداشت',
              filled: true,
              fillColor: const Color(0xFF373741),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
          // تایمر بزرگ
          Text(
            _elapsedText(),
            style: const TextStyle(fontSize: 56, fontFamily: 'monospace', color: Color(0xFF00DCA0), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // دکمه‌ها
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _isRunning ? null : _start,
                icon: const Icon(Icons.play_arrow),
                label: const Text('شروع'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009664), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isRunning ? _stop : null,
                icon: const Icon(Icons.stop),
                label: const Text('توقف و ذخیره'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB43232), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ثبت دستی
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manualMinCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'مدت (دقیقه)',
                    filled: true,
                    fillColor: const Color(0xFF373741),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _manualAdd,
                icon: const Icon(Icons.add),
                label: const Text('ثبت دستی'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4664A0), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // جدول
          Expanded(
            child: Card(
              color: const Color(0xFF2D2D34),
              child: sorted.isEmpty
                  ? const Center(child: Text('هنوز ورودی ثبت نشده'))
                  : ListView.builder(
                      itemCount: sorted.length,
                      itemBuilder: (_, i) {
                        final e = sorted[i];
                        return ListTile(
                          dense: true,
                          title: Text('${e.domain} — ${e.minutes} دقیقه'),
                          subtitle: Text('${toJalali(DateTime.parse(e.start))} → ${toJalali(DateTime.parse(e.end))}\n${e.note}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () async {
                              widget.entries.removeWhere((x) => x.id == e.id);
                              await widget.onEntriesChanged();
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// تب ۲: اهداف
// ============================================================

class GoalsTab extends StatefulWidget {
  final List<Domain> domains;
  final List<Goal> goals;
  final Future<void> Function() onChanged;
  const GoalsTab({super.key, required this.domains, required this.goals, required this.onChanged});

  @override
  State<GoalsTab> createState() => _GoalsTabState();
}

class _GoalsTabState extends State<GoalsTab> {
  final _titleCtrl = TextEditingController();
  String _level = 'روزانه';
  String? _domain;
  final _levels = ['روزانه', 'هفتگی', 'ماهانه', 'فصلی', 'سالانه', 'چشم‌انداز ۲ ساله', 'چشم‌انداز ۳ ساله', 'چشم‌انداز ۴ ساله', 'چشم‌انداز ۵ ساله'];

  @override
  void initState() {
    super.initState();
    if (widget.domains.isNotEmpty) _domain = widget.domains.first.name;
  }

  Future<void> _add() async {
    if (_titleCtrl.text.isEmpty || _domain == null) return;
    final newId = widget.goals.isEmpty ? 1 : (widget.goals.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
    widget.goals.add(Goal(id: newId, title: _titleCtrl.text, level: _level, domain: _domain!, progress: 0));
    await widget.onChanged();
    setState(() => _titleCtrl.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              const Text('سطح:'),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  value: _level,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF373741),
                  items: _levels.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                  onChanged: (v) => setState(() => _level = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('حوزه:'),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  value: _domain,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF373741),
                  items: widget.domains.map((d) => DropdownMenuItem(value: d.name, child: Text(d.name))).toList(),
                  onChanged: (v) => setState(() => _domain = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              labelText: 'عنوان هدف',
              filled: true,
              fillColor: const Color(0xFF373741),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.add),
            label: const Text('افزودن هدف'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0078C8), minimumSize: const Size.fromHeight(45)),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              color: const Color(0xFF2D2D34),
              child: widget.goals.isEmpty
                  ? const Center(child: Text('هنوز هدفی ثبت نشده'))
                  : ListView.builder(
                      itemCount: widget.goals.length,
                      itemBuilder: (_, i) {
                        final g = widget.goals[i];
                        return ListTile(
                          title: Text(g.title),
                          subtitle: Text('[${g.level}] حوزه: ${g.domain}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${g.progress}%'),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.amberAccent),
                                onPressed: () async {
                                  final ctrl = TextEditingController(text: g.progress.toString());
                                  final res = await showDialog<int>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('درصد پیشرفت جدید'),
                                      content: TextField(controller: ctrl, keyboardType: TextInputType.number),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو')),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, int.tryParse(ctrl.text)),
                                          child: const Text('ذخیره'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (res != null && res >= 0 && res <= 100) {
                                    g.progress = res;
                                    await widget.onChanged();
                                    setState(() {});
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () async {
                                  widget.goals.removeWhere((x) => x.id == g.id);
                                  await widget.onChanged();
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// تب ۳: پس‌انداز
// ============================================================

class SavingsTab extends StatefulWidget {
  final List<Saving> savings;
  final Future<void> Function() onChanged;
  const SavingsTab({super.key, required this.savings, required this.onChanged});

  @override
  State<SavingsTab> createState() => _SavingsTabState();
}

class _SavingsTabState extends State<SavingsTab> {
  final _titleCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _currentCtrl = TextEditingController();

  Future<void> _add() async {
    if (_titleCtrl.text.isEmpty) return;
    final newId = widget.savings.isEmpty ? 1 : (widget.savings.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
    widget.savings.add(Saving(
      id: newId,
      title: _titleCtrl.text,
      target: double.tryParse(_targetCtrl.text) ?? 0,
      current: double.tryParse(_currentCtrl.text) ?? 0,
    ));
    await widget.onChanged();
    setState(() {
      _titleCtrl.clear();
      _targetCtrl.clear();
      _currentCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(controller: _titleCtrl, decoration: _dec('عنوان')),
          const SizedBox(height: 8),
          TextField(controller: _targetCtrl, keyboardType: TextInputType.number, decoration: _dec('مبلغ هدف')),
          const SizedBox(height: 8),
          TextField(controller: _currentCtrl, keyboardType: TextInputType.number, decoration: _dec('مبلغ فعلی')),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.add),
            label: const Text('افزودن پس‌انداز'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC89600), minimumSize: const Size.fromHeight(45)),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              color: const Color(0xFF2D2D34),
              child: widget.savings.isEmpty
                  ? const Center(child: Text('هنوز پس‌اندازی ثبت نشده'))
                  : ListView.builder(
                      itemCount: widget.savings.length,
                      itemBuilder: (_, i) {
                        final s = widget.savings[i];
                        final pct = s.target > 0 ? (s.current / s.target * 100) : 0.0;
                        return ListTile(
                          title: Text(s.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${s.current.toStringAsFixed(0)} / ${s.target.toStringAsFixed(0)} (${pct.toStringAsFixed(1)}%)'),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(value: (pct / 100).clamp(0.0, 1.0), backgroundColor: Colors.white12, color: const Color(0xFF00DCA0)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: Colors.tealAccent),
                                onPressed: () async {
                                  final ctrl = TextEditingController();
                                  final res = await showDialog<double>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('مبلغ افزودنی'),
                                      content: TextField(controller: ctrl, keyboardType: TextInputType.number),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو')),
                                        TextButton(onPressed: () => Navigator.pop(context, double.tryParse(ctrl.text)), child: const Text('افزودن')),
                                      ],
                                    ),
                                  );
                                  if (res != null) {
                                    s.current += res;
                                    await widget.onChanged();
                                    setState(() {});
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () async {
                                  widget.savings.removeWhere((x) => x.id == s.id);
                                  await widget.onChanged();
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: const Color(0xFF373741),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );
}

// ============================================================
// تب ۴: جلسات
// ============================================================

class MeetingsTab extends StatefulWidget {
  final List<Meeting> meetings;
  final Future<void> Function() onChanged;
  const MeetingsTab({super.key, required this.meetings, required this.onChanged});

  @override
  State<MeetingsTab> createState() => _MeetingsTabState();
}

class _MeetingsTabState extends State<MeetingsTab> {
  final _titleCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _durCtrl = TextEditingController(text: '60');
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();

  Future<void> _add() async {
    if (_titleCtrl.text.isEmpty || _linkCtrl.text.isEmpty) return;
    final dt = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    final newId = widget.meetings.isEmpty ? 1 : (widget.meetings.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
    widget.meetings.add(Meeting(
      id: newId,
      title: _titleCtrl.text,
      link: _linkCtrl.text,
      time: dt.toIso8601String(),
      duration: int.tryParse(_durCtrl.text) ?? 60,
    ));
    await widget.onChanged();
    setState(() {
      _titleCtrl.clear();
      _linkCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.meetings]..sort((a, b) => b.time.compareTo(a.time));
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(controller: _titleCtrl, decoration: _dec('عنوان جلسه')),
          const SizedBox(height: 8),
          TextField(controller: _linkCtrl, decoration: _dec('لینک')),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(DateFormat('yyyy/MM/dd').format(_date)),
                  onPressed: () async {
                    final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2100));
                    if (d != null) setState(() => _date = d);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.access_time),
                  label: Text('${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}'),
                  onPressed: () async {
                    final t = await showTimePicker(context: context, initialTime: _time);
                    if (t != null) setState(() => _time = t);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(controller: _durCtrl, keyboardType: TextInputType.number, decoration: _dec('مدت (دقیقه)')),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.add),
            label: const Text('افزودن جلسه'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF960096), minimumSize: const Size.fromHeight(45)),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              color: const Color(0xFF2D2D34),
              child: sorted.isEmpty
                  ? const Center(child: Text('هنوز جلسه‌ای ثبت نشده'))
                  : ListView.builder(
                      itemCount: sorted.length,
                      itemBuilder: (_, i) {
                        final m = sorted[i];
                        return ListTile(
                          leading: const Icon(Icons.event, color: Colors.purpleAccent),
                          title: Text(m.title),
                          subtitle: Text('${toJalali(DateTime.parse(m.time))} — ${m.duration} دقیقه'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.open_in_new, color: Colors.lightBlueAccent),
                                onPressed: () {
                                  // باز کردن لینک در مرورگر - در نسخه بعدی با url_launcher
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('لینک: ${m.link}')));
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () async {
                                  widget.meetings.removeWhere((x) => x.id == m.id);
                                  await widget.onChanged();
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: const Color(0xFF373741),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );
}

// ============================================================
// تب ۵: گزارش‌ها
// ============================================================

class ReportsTab extends StatelessWidget {
  final List<TimeEntry> entries;
  const ReportsTab({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final totalMin = entries.fold<int>(0, (s, e) => s + e.minutes);
    final byDomain = <String, int>{};
    for (final e in entries) {
      byDomain[e.domain] = (byDomain[e.domain] ?? 0) + e.minutes;
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: ListView(
        children: [
          Card(
            color: const Color(0xFF2D2D34),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📊 گزارش ساعتی به تفکیک حوزه', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  if (byDomain.isEmpty)
                    const Text('هنوز داده‌ای نیست')
                  else
                    ...byDomain.entries.map((e) {
                      final hours = (e.value / 60).toStringAsFixed(2);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('${e.key}: ${e.value} دقیقه ($hours ساعت)'),
                      );
                    }),
                  const Divider(),
                  Text('مجموع کل: $totalMin دقیقه (${(totalMin / 60).toStringAsFixed(2)} ساعت)', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00DCA0))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFF2D2D34),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📈 گزارش درصدی سهم هر حوزه', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  if (byDomain.isEmpty)
                    const Text('هنوز داده‌ای نیست')
                  else
                    ...byDomain.entries.map((e) {
                      final pct = totalMin > 0 ? (e.value / totalMin * 100) : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${e.key}: ${pct.toStringAsFixed(1)}%'),
                            const SizedBox(height: 2),
                            LinearProgressIndicator(value: pct / 100, backgroundColor: Colors.white12, color: const Color(0xFF00DCA0)),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
