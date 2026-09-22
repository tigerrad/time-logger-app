// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import '../providers/data_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../l10n/strings.dart';
import '../models/meeting.dart';
import '../services/jalali.dart';
import '../widgets/common.dart';

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  final _titleCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _durCtrl = TextEditingController(text: '60');
  final _alarmCtrl = TextEditingController(text: '15');
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  final Set<int> _selectedWeekdays = {};

  @override
  void dispose() {
    _titleCtrl.dispose();
    _linkCtrl.dispose();
    _durCtrl.dispose();
    _alarmCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final s = S(context.read<LanguageProvider>().lang);
    if (_titleCtrl.text.isEmpty || _linkCtrl.text.isEmpty) {
      showSnack(context, s.meetingTitle, color: AppColors.danger);
      return;
    }
    final data = context.read<DataProvider>();
    final dt = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    final newId = data.meetings.isEmpty ? 1 : (data.meetings.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
    final alarmMin = int.tryParse(_alarmCtrl.text) ?? 0;
    final alarmAt = alarmMin > 0 ? dt.subtract(Duration(minutes: alarmMin)).toIso8601String() : null;

    data.meetings.add(Meeting(
      id: newId,
      title: _titleCtrl.text,
      link: _linkCtrl.text,
      time: dt.toIso8601String(),
      duration: int.tryParse(_durCtrl.text) ?? 60,
      repeatWeekdays: _selectedWeekdays.toList(),
      alarmAt: alarmAt,
    ));
    await data.saveMeetings();
    if (!mounted) return;
    setState(() {
      _titleCtrl.clear();
      _linkCtrl.clear();
      _selectedWeekdays.clear();
    });
    showSnack(context, s.saved, color: AppColors.primary);
  }

  Future<void> _openLink(String link) async {
    try {
      final uri = Uri.parse(link);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _addToCalendar(Meeting m) async {
    try {
      final dt = DateTime.parse(m.time);
      final event = Event(
        title: m.title,
        description: m.link,
        location: m.link,
        startDate: dt,
        endDate: dt.add(Duration(minutes: m.duration)),
      );
      Add2Calendar.addEvent2Cal(event);
    } catch (_) {}
  }

  Future<void> _delete(Meeting m) async {
    final ok = await confirmDialog(context, title: 'حذف جلسه');
    if (!ok) return;
    final data = context.read<DataProvider>();
    data.meetings.removeWhere((x) => x.id == m.id);
    await data.saveMeetings();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final theme = context.watch<ThemeProvider>();
    final s = S(context.watch<LanguageProvider>().lang);
    final sorted = [...data.meetings]..sort((a, b) => b.time.compareTo(a.time));

    final weekdays = [
      {'idx': 6, 'name': 'شنبه'},
      {'idx': 7, 'name': 'یکشنبه'},
      {'idx': 1, 'name': 'دوشنبه'},
      {'idx': 2, 'name': 'سه‌شنبه'},
      {'idx': 3, 'name': 'چهارشنبه'},
      {'idx': 4, 'name': 'پنج‌شنبه'},
      {'idx': 5, 'name': 'جمعه'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('📅 ${s.addMeeting}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                AppTextField(controller: _titleCtrl, label: s.meetingTitle, icon: Icons.title),
                const SizedBox(height: 8),
                AppTextField(controller: _linkCtrl, label: s.link, icon: Icons.link),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(toJalaliDate(_date)),
                        onPressed: () async {
                          final d = await pickDate(context, _date);
                          if (d != null) setState(() => _date = d);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time, size: 16),
                        label: Text('${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}'),
                        onPressed: () async {
                          final t = await pickTime(context, _time);
                          if (t != null) setState(() => _time = t);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppTextField(controller: _durCtrl, label: s.durationMin, keyboardType: TextInputType.number, icon: Icons.timer),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.alarm, color: AppColors.warning),
                    const SizedBox(width: 8),
                    const Text('یادآور (دقیقه قبل):'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _alarmCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '15',
                          filled: true,
                          fillColor: AppColors.input,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('${s.weekdays}:', style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: weekdays.map((w) {
                    final idx = w['idx'] as int;
                    final selected = _selectedWeekdays.contains(idx);
                    return FilterChip(
                      label: Text(w['name'] as String),
                      selected: selected,
                      selectedColor: theme.primaryColor.withOpacity(0.3),
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _selectedWeekdays.add(idx);
                          } else {
                            _selectedWeekdays.remove(idx);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                PrimaryButton(label: s.add, icon: Icons.add, color: AppColors.accentPurple, onPressed: _add),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('📋 ${s.meetingsList}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (sorted.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(child: Text(s.noMeetings, style: const TextStyle(color: Colors.white54))),
                  )
                else
                  ...sorted.map((m) => _meetingTile(m, s, theme)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _meetingTile(Meeting m, S s, ThemeProvider theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.input, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event, color: AppColors.accentPurple, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(m.title, style: const TextStyle(fontWeight: FontWeight.bold))),
              IconButton(icon: const Icon(Icons.calendar_month, color: AppColors.warning, size: 20), onPressed: () => _addToCalendar(m), padding: EdgeInsets.zero, constraints: const BoxConstraints(), tooltip: s.addToCalendar),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.open_in_new, color: AppColors.secondary, size: 20), onPressed: () => _openLink(m.link), padding: EdgeInsets.zero, constraints: const BoxConstraints(), tooltip: s.openLink),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.delete, color: AppColors.danger, size: 20), onPressed: () => _delete(m), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ],
          ),
          const SizedBox(height: 4),
          Text('${toJalaliDateTime(DateTime.parse(m.time))} — ${m.duration} ${s.minute}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          if (m.repeatWeekdays.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('🔁 ${m.repeatWeekdays.length} روز', style: const TextStyle(color: Colors.white60, fontSize: 11)),
            ),
          if (m.alarmAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('⏰ یادآور تنظیم شده', style: TextStyle(color: theme.primaryColor, fontSize: 11)),
            ),
          const SizedBox(height: 4),
          Text('🔗 ${m.link}', style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 11)),
        ],
      ),
    );
  }
}