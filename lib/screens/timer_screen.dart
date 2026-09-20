import 'dart:async';
import 'package:flutter/material.dart';
import '../models/domain.dart';
import '../models/time_entry.dart';
import '../services/store.dart';
import '../services/jalali.dart';
import '../services/notification_service.dart';
import '../widgets/common.dart';

class TimerScreen extends StatefulWidget {
  final List<Domain> domains;
  final List<TimeEntry> entries;
  final Future<void> Function() onChanged;

  const TimerScreen({
    super.key,
    required this.domains,
    required this.entries,
    required this.onChanged,
  });

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  // ÃƒËœÃ‚Â­ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Âª ÃƒËœÃ‚ÂªÃƒËœÃ‚Â§Ãƒâ€ºÃ…â€™Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â±
  bool _isRunning = false;
  bool _isPaused = false;
  DateTime? _startTime;
  DateTime? _pausedAt;
  int _totalPausedSeconds = 0;
  String? _selectedDomain;
  final TextEditingController _noteCtrl = TextEditingController();
  Timer? _ticker;
  int? _alarmAtSeconds; // ÃƒËœÃ‚Â²Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Â  ÃƒËœÃ‚Â¢Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Â§ÃƒËœÃ‚Â±Ãƒâ„¢Ã¢â‚¬Â¦ ÃƒËœÃ‚Â¨Ãƒâ„¢Ã¢â‚¬Â¡ ÃƒËœÃ‚Â«ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Â Ãƒâ€ºÃ…â€™Ãƒâ„¢Ã¢â‚¬Â¡
  bool _alarmFired = false;

  // ÃƒËœÃ‚Â«ÃƒËœÃ‚Â¨ÃƒËœÃ‚Âª ÃƒËœÃ‚Â¯ÃƒËœÃ‚Â³ÃƒËœÃ‚ÂªÃƒâ€ºÃ…â€™
  final TextEditingController _manualMinCtrl = TextEditingController();
  final TextEditingController _alarmMinCtrl = TextEditingController();
  DateTime _manualDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.domains.isNotEmpty) {
      _selectedDomain = widget.domains.first.name;
    }
    _restoreTimerState();
    _startTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _noteCtrl.dispose();
    _manualMinCtrl.dispose();
    _alarmMinCtrl.dispose();
    super.dispose();
  }

  // ============ ÃƒËœÃ‚Â¨ÃƒËœÃ‚Â§ÃƒËœÃ‚Â²Ãƒâ€ºÃ…â€™ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¨Ãƒâ€ºÃ…â€™ ÃƒËœÃ‚Â­ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Âª ÃƒËœÃ‚ÂªÃƒËœÃ‚Â§Ãƒâ€ºÃ…â€™Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â± ============
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
        _selectedDomain = state['domain'] ?? _selectedDomain;
        _noteCtrl.text = state['note'] ?? '';
      });
    }
  }

  // ============ ÃƒËœÃ‚Â°ÃƒËœÃ‚Â®Ãƒâ€ºÃ…â€™ÃƒËœÃ‚Â±Ãƒâ„¢Ã¢â‚¬Â¡ ÃƒËœÃ‚Â­ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚Âª ÃƒËœÃ‚ÂªÃƒËœÃ‚Â§Ãƒâ€ºÃ…â€™Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â± ============
  Future<void> _persistTimerState() async {
    await Store.saveTimerState(
      running: _isRunning,
      start: _startTime,
      domain: _selectedDomain,
      note: _noteCtrl.text,
      paused: _isPaused,
      pausedAt: _pausedAt,
      totalPausedSeconds: _totalPausedSeconds,
    );
  }

  // ============ ÃƒËœÃ‚ÂªÃƒâ€ºÃ…â€™ÃƒÅ¡Ã‚Â©ÃƒËœÃ‚Â± ============
  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isRunning && !_isPaused) {
        setState(() {});
        _checkAlarm();
      }
    });
  }

  void _checkAlarm() {
    if (_alarmAtSeconds == null || _alarmFired) return;
    final elapsed = _elapsed().inSeconds;
    if (elapsed >= _alarmAtSeconds!) {
      _alarmFired = true;
      NotificationService.show(
        id: 200,
        title: 'Ã¢ÂÂ° Ã˜Â²Ã™â€¦Ã˜Â§Ã™â€  Ã˜ÂªÃ™â€¦Ã˜Â§Ã™â€¦ Ã˜Â´Ã˜Â¯!',
        body: 'Ã˜ÂªÃ˜Â§Ã›Å’Ã™â€¦Ã˜Â± "${_selectedDomain}" Ã˜Â¨Ã™â€¡ Ã™Â¾Ã˜Â§Ã›Å’Ã˜Â§Ã™â€  Ã˜Â±Ã˜Â³Ã›Å’Ã˜Â¯',
      );
      if (mounted) {
        showSnack(context, 'Ã¢ÂÂ° Ã˜Â¢Ã™â€žÃ˜Â§Ã˜Â±Ã™â€¦! Ã˜Â²Ã™â€¦Ã˜Â§Ã™â€  Ã˜ÂªÃ™â€¦Ã˜Â§Ã™â€¦ Ã˜Â´Ã˜Â¯', color: AppColors.primary);
      }
    }
  }

  // ============ Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â­ÃƒËœÃ‚Â§ÃƒËœÃ‚Â³ÃƒËœÃ‚Â¨Ãƒâ„¢Ã¢â‚¬Â¡ ÃƒËœÃ‚Â²Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Â  ÃƒËœÃ‚Â³Ãƒâ„¢Ã‚Â¾ÃƒËœÃ‚Â±Ãƒâ€ºÃ…â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…â€™ÃƒËœÃ‚Â´ÃƒËœÃ‚Â¯Ãƒâ„¢Ã¢â‚¬Â¡ ============
  Duration _elapsed() {
    if (_startTime == null) return Duration.zero;
    final now = _isPaused && _pausedAt != null ? _pausedAt! : DateTime.now();
    final total = now.difference(_startTime!);
    return total - Duration(seconds: _totalPausedSeconds);
  }

  String _elapsedText() {
    if (!_isRunning || _startTime == null) return '00:00:00';
    final d = _elapsed();
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  // ============ ÃƒËœÃ‚Â´ÃƒËœÃ‚Â±Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¹ ============
  Future<void> _start() async {
    if (_selectedDomain == null) {
      showSnack(context, 'ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¨ÃƒËœÃ‚ÂªÃƒËœÃ‚Â¯ÃƒËœÃ‚Â§ Ãƒâ€ºÃ…â€™ÃƒÅ¡Ã‚Â© ÃƒËœÃ‚Â­Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â²Ãƒâ„¢Ã¢â‚¬Â¡ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Â ÃƒËœÃ‚ÂªÃƒËœÃ‚Â®ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¨ ÃƒÅ¡Ã‚Â©Ãƒâ„¢Ã¢â‚¬Â Ãƒâ€ºÃ…â€™ÃƒËœÃ‚Â¯', color: AppColors.danger);
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

  // ============ Pause ============
  Future<void> _pause() async {
    if (!_isRunning || _isPaused) return;
    setState(() {
      _isPaused = true;
      _pausedAt = DateTime.now();
    });
    await _persistTimerState();
  }

  // ============ Resume ============
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

  // ============ ÃƒËœÃ‚ÂªÃƒâ„¢Ã‹â€ Ãƒâ„¢Ã¢â‚¬Å¡Ãƒâ„¢Ã‚Â Ãƒâ„¢Ã‹â€  ÃƒËœÃ‚Â°ÃƒËœÃ‚Â®Ãƒâ€ºÃ…â€™ÃƒËœÃ‚Â±Ãƒâ„¢Ã¢â‚¬Â¡ ============
  Future<void> _stop() async {
    if (_startTime == null) return;
    final now = DateTime.now();
    final elapsed = _elapsed();
    final mins = elapsed.inMinutes;
    final finalMins = mins < 1 ? 1 : mins;

    final newId = widget.entries.isEmpty
        ? 1
        : (widget.entries.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);

    widget.entries.add(TimeEntry(
      id: newId,
      domain: _selectedDomain!,
      start: _startTime!.toIso8601String(),
      end: now.toIso8601String(),
      minutes: finalMins,
      note: _noteCtrl.text,
    ));

    await widget.onChanged();
    await Store.clearTimerState();

    if (!mounted) return;
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _startTime = null;
      _pausedAt = null;
      _totalPausedSeconds = 0;
      _noteCtrl.clear();
    });

    if (mounted) showSnack(context, 'ÃƒËœÃ‚Â«ÃƒËœÃ‚Â¨ÃƒËœÃ‚Âª ÃƒËœÃ‚Â´ÃƒËœÃ‚Â¯: $finalMins ÃƒËœÃ‚Â¯Ãƒâ„¢Ã¢â‚¬Å¡Ãƒâ€ºÃ…â€™Ãƒâ„¢Ã¢â‚¬Å¡Ãƒâ„¢Ã¢â‚¬Â¡', color: AppColors.primary);
  }

  // ============ ÃƒËœÃ‚Â«ÃƒËœÃ‚Â¨ÃƒËœÃ‚Âª ÃƒËœÃ‚Â¯ÃƒËœÃ‚Â³ÃƒËœÃ‚ÂªÃƒâ€ºÃ…â€™ ============
  Future<void> _manualAdd() async {
    final m = int.tryParse(_manualMinCtrl.text);
    if (m == null || m < 1) {
      showSnack(context, 'Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â¯ÃƒËœÃ‚Âª Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â¹ÃƒËœÃ‚ÂªÃƒËœÃ‚Â¨ÃƒËœÃ‚Â± Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â§ÃƒËœÃ‚Â±ÃƒËœÃ‚Â¯ ÃƒÅ¡Ã‚Â©Ãƒâ„¢Ã¢â‚¬Â Ãƒâ€ºÃ…â€™ÃƒËœÃ‚Â¯', color: AppColors.danger);
      return;
    }
    if (_selectedDomain == null) {
      showSnack(context, 'ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¨ÃƒËœÃ‚ÂªÃƒËœÃ‚Â¯ÃƒËœÃ‚Â§ ÃƒËœÃ‚Â­Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â²Ãƒâ„¢Ã¢â‚¬Â¡ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Â ÃƒËœÃ‚ÂªÃƒËœÃ‚Â®ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¨ ÃƒÅ¡Ã‚Â©Ãƒâ„¢Ã¢â‚¬Â Ãƒâ€ºÃ…â€™ÃƒËœÃ‚Â¯', color: AppColors.danger);
      return;
    }

    final end = _manualDate;
    final start = end.subtract(Duration(minutes: m));

    final newId = widget.entries.isEmpty
        ? 1
        : (widget.entries.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);

    widget.entries.add(TimeEntry(
      id: newId,
      domain: _selectedDomain!,
      start: start.toIso8601String(),
      end: end.toIso8601String(),
      minutes: m,
      note: _noteCtrl.text,
    ));

    await widget.onChanged();
    if (!mounted) return;
    setState(() {
      _manualMinCtrl.clear();
      _noteCtrl.clear();
    });
    showSnack(context, 'ÃƒËœÃ‚Â«ÃƒËœÃ‚Â¨ÃƒËœÃ‚Âª ÃƒËœÃ‚Â¯ÃƒËœÃ‚Â³ÃƒËœÃ‚ÂªÃƒâ€ºÃ…â€™ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Â ÃƒËœÃ‚Â¬ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Â¦ ÃƒËœÃ‚Â´ÃƒËœÃ‚Â¯: $m ÃƒËœÃ‚Â¯Ãƒâ„¢Ã¢â‚¬Å¡Ãƒâ€ºÃ…â€™Ãƒâ„¢Ã¢â‚¬Å¡Ãƒâ„¢Ã¢â‚¬Â¡', color: AppColors.secondary);
  }

  // ============ Ãƒâ„¢Ã‹â€ Ãƒâ€ºÃ…â€™ÃƒËœÃ‚Â±ÃƒËœÃ‚Â§Ãƒâ€ºÃ…â€™ÃƒËœÃ‚Â´ Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â±Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¯Ãƒâ€ºÃ…â€™ ============
  Future<void> _editEntry(TimeEntry entry) async {
    final minCtrl = TextEditingController(text: entry.minutes.toString());
    final noteCtrl = TextEditingController(text: entry.note);
    String domain = entry.domain;
    DateTime startDate = DateTime.parse(entry.start);
    DateTime endDate = DateTime.parse(entry.end);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Ãƒâ„¢Ã‹â€ Ãƒâ€ºÃ…â€™ÃƒËœÃ‚Â±ÃƒËœÃ‚Â§Ãƒâ€ºÃ…â€™ÃƒËœÃ‚Â´ Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â±Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¯Ãƒâ€ºÃ…â€™', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: domain,
                  isExpanded: true,
                  dropdownColor: AppColors.input,
                  items: widget.domains
                      .map((d) => DropdownMenuItem(value: d.name, child: Text(d.name)))
                      .toList(),
                  onChanged: (v) => setDlgState(() => domain = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: minCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â¯ÃƒËœÃ‚Âª (ÃƒËœÃ‚Â¯Ãƒâ„¢Ã¢â‚¬Å¡Ãƒâ€ºÃ…â€™Ãƒâ„¢Ã¢â‚¬Å¡Ãƒâ„¢Ã¢â‚¬Â¡)',
                    filled: true,
                    fillColor: AppColors.input,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ãƒâ€ºÃ…â€™ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¯ÃƒËœÃ‚Â¯ÃƒËœÃ‚Â§ÃƒËœÃ‚Â´ÃƒËœÃ‚Âª',
                    filled: true,
                    fillColor: AppColors.input,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(toJalaliDate(startDate), style: const TextStyle(fontSize: 12)),
                        onPressed: () async {
                          final d = await pickDate(ctx, startDate);
                          if (d != null) setDlgState(() => startDate = d);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(toJalaliDate(endDate), style: const TextStyle(fontSize: 12)),
                        onPressed: () async {
                          final d = await pickDate(ctx, endDate);
                          if (d != null) setDlgState(() => endDate = d);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Ãƒâ„¢Ã¢â‚¬Å¾ÃƒËœÃ‚ÂºÃƒâ„¢Ã‹â€ ', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ÃƒËœÃ‚Â°ÃƒËœÃ‚Â®Ãƒâ€ºÃ…â€™ÃƒËœÃ‚Â±Ãƒâ„¢Ã¢â‚¬Â¡', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final idx = widget.entries.indexWhere((e) => e.id == entry.id);
      if (idx >= 0) {
        widget.entries[idx] = entry.copyWith(
          domain: domain,
          minutes: int.tryParse(minCtrl.text) ?? entry.minutes,
          note: noteCtrl.text,
          start: startDate.toIso8601String(),
          end: endDate.toIso8601String(),
        );
        await widget.onChanged();
        if (!mounted) return;
        setState(() {});
        showSnack(context, 'Ãƒâ„¢Ã‹â€ Ãƒâ€ºÃ…â€™ÃƒËœÃ‚Â±ÃƒËœÃ‚Â§Ãƒâ€ºÃ…â€™ÃƒËœÃ‚Â´ ÃƒËœÃ‚Â´ÃƒËœÃ‚Â¯', color: AppColors.primary);
      }
    }
  }

  // ============ ÃƒËœÃ‚Â­ÃƒËœÃ‚Â°Ãƒâ„¢Ã‚Â Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â±Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¯Ãƒâ€ºÃ…â€™ ============
  Future<void> _deleteEntry(TimeEntry entry) async {
    final ok = await confirmDialog(
      context,
      title: 'ÃƒËœÃ‚Â­ÃƒËœÃ‚Â°Ãƒâ„¢Ã‚Â Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â±Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¯Ãƒâ€ºÃ…â€™',
      message: 'ÃƒËœÃ‚Â§Ãƒâ€ºÃ…â€™Ãƒâ„¢Ã¢â‚¬Â  Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â±Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¯Ãƒâ€ºÃ…â€™ ÃƒËœÃ‚Â­ÃƒËœÃ‚Â°Ãƒâ„¢Ã‚Â ÃƒËœÃ‚Â´Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¯ÃƒËœÃ…Â¸',
    );
    if (!ok) return;
    widget.entries.removeWhere((e) => e.id == entry.id);
    await widget.onChanged();
    if (!mounted) return;
    setState(() {});
  }

  // ============ ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Â ÃƒËœÃ‚ÂªÃƒËœÃ‚Â®ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¨ ÃƒËœÃ‚ÂªÃƒËœÃ‚Â§ÃƒËœÃ‚Â±Ãƒâ€ºÃ…â€™ÃƒËœÃ‚Â® ÃƒËœÃ‚Â¨ÃƒËœÃ‚Â±ÃƒËœÃ‚Â§Ãƒâ€ºÃ…â€™ ÃƒËœÃ‚Â«ÃƒËœÃ‚Â¨ÃƒËœÃ‚Âª ÃƒËœÃ‚Â¯ÃƒËœÃ‚Â³ÃƒËœÃ‚ÂªÃƒâ€ºÃ…â€™ ============
  Future<void> _pickManualDate() async {
    final d = await pickDate(context, _manualDate);
    if (d == null) return;
    if (!mounted) return;
    final t = await pickTime(context, TimeOfDay.fromDateTime(_manualDate));
    if (!mounted) return;
    setState(() {
      _manualDate = DateTime(
        d.year,
        d.month,
        d.day,
        t?.hour ?? _manualDate.hour,
        t?.minute ?? _manualDate.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.entries]..sort((a, b) => b.id.compareTo(a.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ===== ÃƒÅ¡Ã‚Â©ÃƒËœÃ‚Â§ÃƒËœÃ‚Â±ÃƒËœÃ‚Âª ÃƒËœÃ‚ÂªÃƒËœÃ‚Â§Ãƒâ€ºÃ…â€™Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â± =====
          AppCard(
            child: Column(
              children: [
                // ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Â ÃƒËœÃ‚ÂªÃƒËœÃ‚Â®ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¨ ÃƒËœÃ‚Â­Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â²Ãƒâ„¢Ã¢â‚¬Â¡
                Row(
                  children: [
                    const Text('ÃƒËœÃ‚Â­Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â²Ãƒâ„¢Ã¢â‚¬Â¡:', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedDomain,
                        isExpanded: true,
                        dropdownColor: AppColors.input,
                        items: widget.domains
                            .map((d) => DropdownMenuItem(value: d.name, child: Text(d.name)))
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
                  controller: _noteCtrl,
                  label: 'Ãƒâ€ºÃ…â€™ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¯ÃƒËœÃ‚Â¯ÃƒËœÃ‚Â§ÃƒËœÃ‚Â´ÃƒËœÃ‚Âª',
                  icon: Icons.edit_note,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.alarm, color: AppColors.warning),
                    const SizedBox(width: 8),
                    const Text('Ø¢Ù„Ø§Ø±Ù… (Ø¯Ù‚ÛŒÙ‚Ù‡):', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _alarmMinCtrl,
                        keyboardType: TextInputType.number,
                        enabled: !_isRunning,
                        decoration: const InputDecoration(
                          hintText: 'Ù…Ø«Ù„Ø§Ù‹ Û²Ûµ',
                          filled: true,
                          fillColor: AppColors.input,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ÃƒËœÃ‚ÂªÃƒËœÃ‚Â§Ãƒâ€ºÃ…â€™Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â± ÃƒËœÃ‚Â¨ÃƒËœÃ‚Â²ÃƒËœÃ‚Â±ÃƒÅ¡Ã‚Â¯
                Text(
                  _elapsedText(),
                  style: const TextStyle(
                    fontSize: 56,
                    fontFamily: 'monospace',
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isPaused)
                  const Text('ÃƒÂ¢Ã‚ÂÃ‚Â¸ Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚ÂªÃƒâ„¢Ã‹â€ Ãƒâ„¢Ã¢â‚¬Å¡Ãƒâ„¢Ã‚Â ÃƒËœÃ‚Â´ÃƒËœÃ‚Â¯Ãƒâ„¢Ã¢â‚¬Â¡', style: TextStyle(color: AppColors.warning, fontSize: 14)),
                const SizedBox(height: 12),

                // ÃƒËœÃ‚Â¯ÃƒÅ¡Ã‚Â©Ãƒâ„¢Ã¢â‚¬Â¦Ãƒâ„¢Ã¢â‚¬Â¡ÃƒÂ¢Ã¢â€šÂ¬Ã…â€™Ãƒâ„¢Ã¢â‚¬Â¡ÃƒËœÃ‚Â§
                if (!_isRunning) ...[
                  PrimaryButton(
                    label: 'ÃƒËœÃ‚Â´ÃƒËœÃ‚Â±Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¹',
                    icon: Icons.play_arrow,
                    color: const Color(0xFF009664),
                    onPressed: _start,
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: _isPaused ? 'ÃƒËœÃ‚Â§ÃƒËœÃ‚Â¯ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Â¦Ãƒâ„¢Ã¢â‚¬Â¡' : 'ÃƒËœÃ‚ÂªÃƒâ„¢Ã‹â€ Ãƒâ„¢Ã¢â‚¬Å¡Ãƒâ„¢Ã‚Â Ãƒâ„¢Ã¢â‚¬Â¦Ãƒâ„¢Ã‹â€ Ãƒâ„¢Ã¢â‚¬Å¡ÃƒËœÃ‚Âª',
                          icon: _isPaused ? Icons.play_arrow : Icons.pause,
                          color: _isPaused ? AppColors.primary : AppColors.warning,
                          onPressed: _isPaused ? _resume : _pause,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Ãƒâ„¢Ã‚Â¾ÃƒËœÃ‚Â§Ãƒâ€ºÃ…â€™ÃƒËœÃ‚Â§Ãƒâ„¢Ã¢â‚¬Â  Ãƒâ„¢Ã‹â€  ÃƒËœÃ‚Â°ÃƒËœÃ‚Â®Ãƒâ€ºÃ…â€™ÃƒËœÃ‚Â±Ãƒâ„¢Ã¢â‚¬Â¡',
                          icon: Icons.stop,
                          color: AppColors.danger,
                          onPressed: _stop,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ===== ÃƒÅ¡Ã‚Â©ÃƒËœÃ‚Â§ÃƒËœÃ‚Â±ÃƒËœÃ‚Âª ÃƒËœÃ‚Â«ÃƒËœÃ‚Â¨ÃƒËœÃ‚Âª ÃƒËœÃ‚Â¯ÃƒËœÃ‚Â³ÃƒËœÃ‚ÂªÃƒâ€ºÃ…â€™ =====
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('ÃƒÂ¢Ã…â€œÃ‚ÂÃƒÂ¯Ã‚Â¸Ã‚Â ÃƒËœÃ‚Â«ÃƒËœÃ‚Â¨ÃƒËœÃ‚Âª ÃƒËœÃ‚Â¯ÃƒËœÃ‚Â³ÃƒËœÃ‚ÂªÃƒâ€ºÃ…â€™', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _manualMinCtrl,
                  label: 'Ãƒâ„¢Ã¢â‚¬Â¦ÃƒËœÃ‚Â¯ÃƒËœÃ‚Âª (ÃƒËœÃ‚Â¯Ãƒâ„¢Ã¢â‚¬Å¡Ãƒâ€ºÃ…â€™Ãƒâ„¢Ã¢â‚¬Å¡Ãƒâ„¢Ã¢â‚¬Â¡)',
                  keyboardType: TextInputType.number,
                  icon: Icons.timer,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(toJalaliDateTime(_manualDate), style: const TextStyle(fontSize: 12)),
                        onPressed: _pickManualDate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'ÃƒËœÃ‚Â«ÃƒËœÃ‚Â¨ÃƒËœÃ‚Âª ÃƒËœÃ‚Â¯ÃƒËœÃ‚Â³ÃƒËœÃ‚ÂªÃƒâ€ºÃ…â€™',
                  icon: Icons.add,
                  color: AppColors.secondary,
                  onPressed: _manualAdd,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ===== ÃƒËœÃ‚Â¬ÃƒËœÃ‚Â¯Ãƒâ„¢Ã‹â€ Ãƒâ„¢Ã¢â‚¬Å¾ Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â±Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¯Ãƒâ€ºÃ…â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…â€™Ãƒâ„¢Ã¢â‚¬Â¡ÃƒËœÃ‚Â§ =====
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ÃƒÂ°Ã…Â¸Ã¢â‚¬Å“Ã¢â‚¬Â¹ Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â±Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¯Ãƒâ€ºÃ…â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…â€™Ãƒâ„¢Ã¢â‚¬Â¡ÃƒËœÃ‚Â§', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('${sorted.length} Ãƒâ„¢Ã¢â‚¬Â¦Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â±ÃƒËœÃ‚Â¯', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                if (sorted.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('Ãƒâ„¢Ã¢â‚¬Â¡Ãƒâ„¢Ã¢â‚¬Â Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â² Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â±Ãƒâ„¢Ã‹â€ ÃƒËœÃ‚Â¯Ãƒâ€ºÃ…â€™ ÃƒËœÃ‚Â«ÃƒËœÃ‚Â¨ÃƒËœÃ‚Âª Ãƒâ„¢Ã¢â‚¬Â ÃƒËœÃ‚Â´ÃƒËœÃ‚Â¯Ãƒâ„¢Ã¢â‚¬Â¡', style: TextStyle(color: Colors.white54))),
                  )
                else
                  ...sorted.map((e) => _entryTile(e)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _entryTile(TimeEntry e) {
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
                child: Text('${e.domain} ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â ${e.minutes} ÃƒËœÃ‚Â¯Ãƒâ„¢Ã¢â‚¬Å¡Ãƒâ€ºÃ…â€™Ãƒâ„¢Ã¢â‚¬Å¡Ãƒâ„¢Ã¢â‚¬Â¡',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.warning, size: 20),
                onPressed: () => _editEntry(e),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.danger, size: 20),
                onPressed: () => _deleteEntry(e),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${toJalaliDateTime(start)} ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ ${timeOnly(end)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if (e.note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('ÃƒÂ°Ã…Â¸Ã¢â‚¬Å“Ã‚Â ${e.note}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}