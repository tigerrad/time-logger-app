// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../l10n/strings.dart';
import '../models/time_entry.dart';
import '../services/jalali.dart';
import '../services/store.dart';
import '../services/notification_service.dart';
import '../widgets/common.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  bool _isRunning = false;
  bool _isPaused = false;
  DateTime? _startTime;
  DateTime? _pausedAt;
  int _totalPausedSeconds = 0;
  String? _selectedDomain;
  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _manualMinCtrl = TextEditingController();
  final TextEditingController _alarmMinCtrl = TextEditingController();
  Timer? _ticker;
  int? _alarmAtSeconds;
  bool _alarmFired = false;
  AlarmType _alarmType = AlarmType.both;
  DateTime _manualDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _restoreTimerState();
    _startTicker();
    NotificationService().init();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _noteCtrl.dispose();
    _manualMinCtrl.dispose();
    _alarmMinCtrl.dispose();
    super.dispose();
  }

  Future<void> _restoreTimerState() async {
    final state = await Store.loadTimerState();
    if (!mounted) return;
    if (state['running'] == true) {
      setState(() {
        _isRunning = true;
        _isPaused = state['paused'] == true;
        _startTime = state['start'] != null ? DateTime.parse(state['start']) : null;
        _pausedAt = state['pausedAt'] != null ? DateTime.parse(state['pausedAt']) : null;
        _totalPausedSeconds = state['totalPausedSeconds'] ?? 0;
        _selectedDomain = state['domain'];
        _noteCtrl.text = state['note'] ?? '';
        _alarmAtSeconds = state['alarmAtSeconds'];
      });
    }
  }

  Future<void> _persistTimerState() async {
    await Store.saveTimerState(
      running: _isRunning,
      start: _startTime,
      domain: _selectedDomain,
      note: _noteCtrl.text,
      paused: _isPaused,
      pausedAt: _pausedAt,
      totalPausedSeconds: _totalPausedSeconds,
      alarmAtSeconds: _alarmAtSeconds,
    );
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isRunning && !_isPaused) {
        setState(() {});
        _checkAlarm();
      }
    });
  }

  Future<void> _checkAlarm() async {
    if (_alarmAtSeconds == null || _alarmFired) return;
    final elapsed = _elapsed().inSeconds;
    if (elapsed >= _alarmAtSeconds!) {
      _alarmFired = true;

      // پخش صدا و ویبره
      if (_alarmType == AlarmType.sound || _alarmType == AlarmType.both) {
        SystemSound.play(SystemSoundType.alert);
      }
      if (_alarmType == AlarmType.vibrate || _alarmType == AlarmType.both) {
        HapticFeedback.vibrate();
      }

      // اعلان سیستمی
      await NotificationService().showAlarm(
        id: 100,
        title: 'Time Logger',
        body: 'آلارم! زمان تمام شد',
        type: _alarmType,
      );

      // توقف خودکار تایمر
      if (mounted) {
        await _stop(showMessage: true);
      }
    }
  }

  Duration _elapsed() {
    if (_startTime == null) return Duration.zero;
    final now = _isPaused && _pausedAt != null ? _pausedAt! : DateTime.now();
    final total = now.difference(_startTime!);
    return total - Duration(seconds: _totalPausedSeconds);
  }

  String _elapsedText() {
    if (!_isRunning || _startTime == null) return '00:00:00';
    final d = _elapsed();
    return '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _start() async {
    final s = S(context.read<LanguageProvider>().lang);
    if (_selectedDomain == null) {
      showSnack(context, s.selectDomainFirst, color: AppColors.danger);
      return;
    }
    final alarmMin = int.tryParse(_alarmMinCtrl.text);
    setState(() {
      _isRunning = true;
      _isPaused = false;
      _startTime = DateTime.now();
      _pausedAt = null;
      _totalPausedSeconds = 0;
      _alarmAtSeconds = (alarmMin != null && alarmMin > 0) ? alarmMin * 60 : null;
      _alarmFired = false;
    });
    await _persistTimerState();
  }

  Future<void> _pause() async {
    if (!_isRunning || _isPaused) return;
    setState(() {
      _isPaused = true;
      _pausedAt = DateTime.now();
    });
    await _persistTimerState();
  }

  Future<void> _resume() async {
    if (!_isRunning || !_isPaused || _pausedAt == null) return;
    final pausedDuration = DateTime.now().difference(_pausedAt!);
    setState(() {
      _totalPausedSeconds += pausedDuration.inSeconds;
      _isPaused = false;
      _pausedAt = null;
    });
    await _persistTimerState();
  }

  Future<void> _stop({bool showMessage = true}) async {
    if (_startTime == null) return;
    final data = context.read<DataProvider>();
    final s = S(context.read<LanguageProvider>().lang);
    final now = DateTime.now();
    final mins = _elapsed().inMinutes;
    final finalMins = mins < 1 ? 1 : mins;
    final newId = data.entries.isEmpty
        ? 1
        : (data.entries.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);

    data.entries.add(TimeEntry(
      id: newId,
      domain: _selectedDomain!,
      start: _startTime!.toIso8601String(),
      end: now.toIso8601String(),
      minutes: finalMins,
      note: _noteCtrl.text,
      alarmMinutes: _alarmAtSeconds != null ? _alarmAtSeconds! ~/ 60 : null,
    ));

    await data.saveEntries();
    await Store.clearTimerState();

    if (!mounted) return;
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _startTime = null;
      _pausedAt = null;
      _totalPausedSeconds = 0;
      _noteCtrl.clear();
      _alarmMinCtrl.clear();
      _alarmAtSeconds = null;
      _alarmFired = false;
    });
    if (mounted && showMessage) {
      showSnack(context, '${s.registered}: $finalMins ${s.minute}',
          color: AppColors.primary);
    }
  }

  Future<void> _manualAdd() async {
    final s = S(context.read<LanguageProvider>().lang);
    final m = int.tryParse(_manualMinCtrl.text);
    if (m == null || m < 1) {
      showSnack(context, s.durationMin, color: AppColors.danger);
      return;
    }
    if (_selectedDomain == null) {
      showSnack(context, s.selectDomainFirst, color: AppColors.danger);
      return;
    }
    final data = context.read<DataProvider>();
    final end = _manualDate;
    final start = end.subtract(Duration(minutes: m));
    final newId = data.entries.isEmpty
        ? 1
        : (data.entries.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);

    data.entries.add(TimeEntry(
      id: newId,
      domain: _selectedDomain!,
      start: start.toIso8601String(),
      end: end.toIso8601String(),
      minutes: m,
      note: _noteCtrl.text,
    ));

    await data.saveEntries();
    if (!mounted) return;
    setState(() {
      _manualMinCtrl.clear();
      _noteCtrl.clear();
    });
    showSnack(context, '${s.registered}: $m ${s.minute}',
        color: AppColors.secondary);
  }

  Future<void> _deleteEntry(TimeEntry entry) async {
    final s = S(context.read<LanguageProvider>().lang);
    final ok = await confirmDialog(context, title: s.deleteEntry, message: s.areYouSure);
    if (!ok) return;
    final data = context.read<DataProvider>();
    data.entries.removeWhere((e) => e.id == entry.id);
    await data.saveEntries();
  }

  Future<void> _pickManualDate() async {
    final d = await pickDate(context, _manualDate);
    if (d == null) return;
    if (!mounted) return;
    final t = await pickTime(context, TimeOfDay.fromDateTime(_manualDate));
    if (!mounted) return;
    setState(() {
      _manualDate = DateTime(d.year, d.month, d.day,
          t?.hour ?? _manualDate.hour, t?.minute ?? _manualDate.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final theme = context.watch<ThemeProvider>();
    final s = S(context.watch<LanguageProvider>().lang);

    if (_selectedDomain == null && data.domains.isNotEmpty) {
      _selectedDomain = data.domains.first.name;
    }

    final sorted = [...data.entries]..sort((a, b) => b.id.compareTo(a.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Text('${s.domain}:', style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedDomain,
                        isExpanded: true,
                        dropdownColor: AppColors.input,
                        items: data.domains
                            .map((d) =>
                                DropdownMenuItem(value: d.name, child: Text(d.name)))
                            .toList(),
                        onChanged: _isRunning
                            ? null
                            : (v) => setState(() => _selectedDomain = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppTextField(
                    controller: _noteCtrl, label: s.note, icon: Icons.edit_note),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.alarm, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Text('${s.alarm}:', style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _alarmMinCtrl,
                        keyboardType: TextInputType.number,
                        enabled: !_isRunning,
                        decoration: const InputDecoration(
                          hintText: '0',
                          filled: true,
                          fillColor: AppColors.input,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // نوع آلارم
                Row(
                  children: [
                    const Icon(Icons.notifications_active,
                        color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text('نوع آلارم:',
                        style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<AlarmType>(
                        value: _alarmType,
                        isExpanded: true,
                        dropdownColor: AppColors.input,
                        items: const [
                          DropdownMenuItem(
                              value: AlarmType.sound,
                              child: Text('زنگ')),
                          DropdownMenuItem(
                              value: AlarmType.vibrate,
                              child: Text('ویبره')),
                          DropdownMenuItem(
                              value: AlarmType.both,
                              child: Text('زنگ + ویبره')),
                        ],
                        onChanged: _isRunning ? null : (v) => setState(() => _alarmType = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _elapsedText(),
                  style: TextStyle(
                    fontSize: 56,
                    fontFamily: 'monospace',
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isPaused)
                  Text('⏸ ${s.paused}',
                      style: const TextStyle(
                          color: AppColors.warning, fontSize: 14)),
                const SizedBox(height: 12),
                if (!_isRunning)
                  PrimaryButton(
                    label: s.start,
                    icon: Icons.play_arrow,
                    color: const Color(0xFF009664),
                    onPressed: _start,
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: _isPaused ? s.resume : s.pause,
                          icon: _isPaused ? Icons.play_arrow : Icons.pause,
                          color: _isPaused
                              ? theme.primaryColor
                              : AppColors.warning,
                          onPressed: _isPaused ? _resume : _pause,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PrimaryButton(
                          label: s.stop,
                          icon: Icons.stop,
                          color: AppColors.danger,
                          onPressed: _stop,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('✍️ ${s.manualAdd}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _manualMinCtrl,
                  label: s.durationMin,
                  keyboardType: TextInputType.number,
                  icon: Icons.timer,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(toJalaliDateTime(_manualDate),
                            style: const TextStyle(fontSize: 12)),
                        onPressed: _pickManualDate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: s.manualAdd,
                  icon: Icons.add,
                  color: AppColors.secondary,
                  onPressed: _manualAdd,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('📋 ${s.entries}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('${sorted.length}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                if (sorted.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                        child: Text(s.noEntries,
                            style: const TextStyle(color: Colors.white54))),
                  )
                else
                  ...sorted.map((e) => _entryTile(context, e, s)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _entryTile(BuildContext context, TimeEntry e, S s) {
    final start = DateTime.parse(e.start);
    final end = DateTime.parse(e.end);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${e.domain} — ${e.minutes} ${s.minute}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.delete,
                    color: AppColors.danger, size: 20),
                onPressed: () => _deleteEntry(e),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${toJalaliDateTime(start)} → ${timeOnly(end)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if (e.note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('📝 ${e.note}',
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 12)),
            ),
          if (e.alarmMinutes != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('⏰ ${e.alarmMinutes} ${s.minute}',
                  style: const TextStyle(
                      color: AppColors.warning, fontSize: 11)),
            ),
        ],
      ),
    );
  }
}