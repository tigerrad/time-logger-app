import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/domain.dart';
import '../models/time_entry.dart';
import '../models/goal.dart';
import '../models/saving.dart';
import '../models/meeting.dart';
import '../models/finance_category.dart';
import '../models/finance_transaction.dart';

class Store {
  static const _kDomains = 'domains';
  static const _kEntries = 'entries';
  static const _kGoals = 'goals';
  static const _kSavings = 'savings';
  static const _kMeetings = 'meetings';
  static const _kFinanceTx = 'finance_transactions';
  static const _kFinanceCat = 'finance_categories';
  static const _kTimerRunning = 'timer_running';
  static const _kTimerStart = 'timer_start';
  static const _kTimerDomain = 'timer_domain';
  static const _kTimerNote = 'timer_note';
  static const _kTimerPaused = 'timer_paused';
  static const _kTimerPausedAt = 'timer_paused_at';
  static const _kTimerTotalPaused = 'timer_total_paused';

  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ===== DOMAINS =====
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

  // ===== ENTRIES =====
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

  // ===== GOALS =====
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

  // ===== SAVINGS =====
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

  // ===== MEETINGS =====
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

  // ===== FINANCE =====
  static Future<List<FinanceTransaction>> loadFinanceTransactions() async {
    final p = await _prefs;
    final raw = p.getString(_kFinanceTx);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => FinanceTransaction.fromJson(e)).toList();
  }

  static Future<void> saveFinanceTransactions(List<FinanceTransaction> t) async {
    final p = await _prefs;
    await p.setString(_kFinanceTx, jsonEncode(t.map((e) => e.toJson()).toList()));
  }

  static Future<List<FinanceCategory>> loadFinanceCategories() async {
    final p = await _prefs;
    final raw = p.getString(_kFinanceCat);
    if (raw == null) {
      final defaults = [
        FinanceCategory(id: 1, name: 'حقوق', type: 'income', color: '#4CAF50'),
        FinanceCategory(id: 2, name: 'فروش', type: 'income', color: '#8BC34A'),
        FinanceCategory(id: 3, name: 'هدیه دریافتی', type: 'income', color: '#CDDC39'),
        FinanceCategory(id: 4, name: 'سرمایه‌گذاری', type: 'income', color: '#009688'),
        FinanceCategory(id: 5, name: 'سایر درآمد', type: 'income', color: '#607D8B'),
        FinanceCategory(id: 10, name: 'بخشش یا اعانه', type: 'expense', color: '#E91E63'),
        FinanceCategory(id: 11, name: 'مسکن', type: 'expense', color: '#9C27B0'),
        FinanceCategory(id: 12, name: 'خوراک', type: 'expense', color: '#FF9800'),
        FinanceCategory(id: 13, name: 'حمل و نقل', type: 'expense', color: '#2196F3'),
        FinanceCategory(id: 14, name: 'پوشاک', type: 'expense', color: '#00BCD4'),
        FinanceCategory(id: 15, name: 'قبض‌ها', type: 'expense', color: '#795548'),
        FinanceCategory(id: 16, name: 'مراقبت فردی و ورزش', type: 'expense', color: '#FF5722'),
        FinanceCategory(id: 17, name: 'بهداشت و درمان', type: 'expense', color: '#F44336'),
        FinanceCategory(id: 18, name: 'هزینه افراد تحت تکفل', type: 'expense', color: '#E91E63'),
        FinanceCategory(id: 19, name: 'سرگرمی و تفریح', type: 'expense', color: '#FFC107'),
        FinanceCategory(id: 20, name: 'آموزش', type: 'expense', color: '#3F51B5'),
        FinanceCategory(id: 21, name: 'تعطیلات و مسافرت', type: 'expense', color: '#03A9F4'),
        FinanceCategory(id: 22, name: 'کسب و کار شخصی', type: 'expense', color: '#673AB7'),
        FinanceCategory(id: 23, name: 'هدیه', type: 'expense', color: '#F06292'),
        FinanceCategory(id: 24, name: 'سرمایه‌گذاری', type: 'expense', color: '#4DB6AC'),
        FinanceCategory(id: 25, name: 'مالیات و بیمه', type: 'expense', color: '#455A64'),
        FinanceCategory(id: 26, name: 'پرداخت بدهی', type: 'expense', color: '#8D6E63'),
        FinanceCategory(id: 27, name: 'سایر', type: 'expense', color: '#9E9E9E'),
      ];
      await saveFinanceCategories(defaults);
      return defaults;
    }
    final list = jsonDecode(raw) as List;
    return list.map((e) => FinanceCategory.fromJson(e)).toList();
  }

  static Future<void> saveFinanceCategories(List<FinanceCategory> c) async {
    final p = await _prefs;
    await p.setString(_kFinanceCat, jsonEncode(c.map((e) => e.toJson()).toList()));
  }

  // ===== TIMER STATE =====
  static Future<void> saveTimerState({
    required bool running,
    required DateTime? start,
    required String? domain,
    required String? note,
    required bool paused,
    required DateTime? pausedAt,
    required int totalPausedSeconds,
  }) async {
    final p = await _prefs;
    await p.setBool(_kTimerRunning, running);
    if (start != null) {
      await p.setString(_kTimerStart, start.toIso8601String());
    } else {
      await p.remove(_kTimerStart);
    }
    if (domain != null) {
      await p.setString(_kTimerDomain, domain);
    } else {
      await p.remove(_kTimerDomain);
    }
    await p.setString(_kTimerNote, note ?? '');
    await p.setBool(_kTimerPaused, paused);
    if (pausedAt != null) {
      await p.setString(_kTimerPausedAt, pausedAt.toIso8601String());
    } else {
      await p.remove(_kTimerPausedAt);
    }
    await p.setInt(_kTimerTotalPaused, totalPausedSeconds);
  }

  static Future<Map<String, dynamic>> loadTimerState() async {
    final p = await _prefs;
    return {
      'running': p.getBool(_kTimerRunning) ?? false,
      'start': p.getString(_kTimerStart),
      'domain': p.getString(_kTimerDomain),
      'note': p.getString(_kTimerNote) ?? '',
      'paused': p.getBool(_kTimerPaused) ?? false,
      'pausedAt': p.getString(_kTimerPausedAt),
      'totalPausedSeconds': p.getInt(_kTimerTotalPaused) ?? 0,
    };
  }

  static Future<void> clearTimerState() async {
    final p = await _prefs;
    await p.remove(_kTimerRunning);
    await p.remove(_kTimerStart);
    await p.remove(_kTimerDomain);
    await p.remove(_kTimerNote);
    await p.remove(_kTimerPaused);
    await p.remove(_kTimerPausedAt);
    await p.remove(_kTimerTotalPaused);
  }
}