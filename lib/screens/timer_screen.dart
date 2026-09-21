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
  bool _isRunning = false;
  bool _isPaused = false;
  DateTime? _startTime;
  DateTime? _pausedAt;
  int _totalPausedSeconds = 0;
  String? _selectedDomain;
  final TextEditingController _noteCtrl = TextEditingController();
  Timer? _ticker;
  int? _alarmAtSeconds;
  bool _alarmFired = false;

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
        title: '⏰ زمان تمام شد!',
        body: 'تایمر $_selectedDomain به پایان رسید',
      );
      if (mounted) {
        showSnack(context, '⏰ آلارم! زمان تمام شد', color: AppColors.primary);
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
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _start() async {
    if (_selectedDomain == null) {
      showSnack(context, 'ابتدا یک حوزه انتخاب کنید', color: AppColors.danger);
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
      _alarmMinCtrl.clear();
      _alarmAtSeconds = null;
      _alarmFired = false;
    });
    if (mounted) {
      showSnack(context, 'ثبت شد: $finalMins دقیقه', color: AppColors.primary);
    }
  }

  Future<void> _manualAdd() async {
    final m = int.tryParse(_manualMinCtrl.text);
    if (m == null || m < 1) {
      showSnack(context, 'مدت معتبر وارد کنید', color: AppColors.danger);
      return;
    }
    if (_selectedDomain == null) {
      showSnack(context, 'ابتدا حوزه انتخاب کنید', color: AppColors.danger);
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
    showSnack(context, 'ثبت دستی انجام شد: $m دقیقه', color: AppColors.secondary);
  }

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
          title: const Text('ویرایش ورودی', style: TextStyle(color: Colors.white)),
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
                    labelText: 'مدت (دقیقه)',
                    filled: true,
                    fillColor: AppColors.input,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'یادداشت',
                    filled: true,
                    fillColor: AppColors.input,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('لغو', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ذخیره', style: TextStyle(color: AppColors.primary)),
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
        showSnack(context, 'ویرایش شد', color: AppColors.primary);
      }
    }
  }

  Future<void> _deleteEntry(TimeEntry entry) async {
    final ok = await confirmDialog(
      context,
      title: 'حذف ورودی',
      message: 'این ورودی حذف شود؟',
    );
    if (!ok) return;
    widget.entries.removeWhere((e) => e.id == entry.id);
    await widget.onChanged();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.entries]..sort((a, b) => b.id.compareTo(a.id));
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
                    const Text('حوزه:', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedDomain,
                        isExpanded: true,
                        dropdownColor: AppColors.input,
                        items: widget.domains
                            .map((d) => DropdownMenuItem(value: d.name, child: Text(d.name)))
                            .toList(),
                        onChanged: _isRunning ? null : (v) => setState(() => _selectedDomain = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _noteCtrl,
                  label: 'یادداشت',
                  icon: Icons.edit_note,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.alarm, color: AppColors.warning),
                    const SizedBox(width: 8),
                    const Text('آلارم (دقیقه):', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _alarmMinCtrl,
                        keyboardType: TextInputType.number,
                        enabled: !_isRunning,
                        decoration: const InputDecoration(
                          hintText: 'مثلاً ۲۵',
                          filled: true,
                          fillColor: AppColors.input,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                  const Text('⏸ متوقف شده', style: TextStyle(color: AppColors.warning, fontSize: 14)),
                const SizedBox(height: 12),
                if (!_isRunning) ...[
                  PrimaryButton(
                    label: 'شروع',
                    icon: Icons.play_arrow,
                    color: const Color(0xFF009664),
                    onPressed: _start,
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: _isPaused ? 'ادامه' : 'توقف موقت',
                          icon: _isPaused ? Icons.play_arrow : Icons.pause,
                          color: _isPaused ? AppColors.primary : AppColors.warning,
                          onPressed: _isPaused ? _resume : _pause,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PrimaryButton(
                          label: 'پایان و ذخیره',
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
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('✍️ ثبت دستی', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _manualMinCtrl,
                  label: 'مدت (دقیقه)',
                  keyboardType: TextInputType.number,
                  icon: Icons.timer,
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'ثبت دستی',
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
                    const Text('📋 ورودی‌ها', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('${sorted.length} مورد', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                if (sorted.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('هنوز ورودی ثبت نشده', style: TextStyle(color: Colors.white54))),
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
                child: Text('${e.domain} — ${e.minutes} دقیقه',
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
            '${toJalaliDateTime(start)} → ${timeOnly(end)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if (e.note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('📝 ${e.note}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}