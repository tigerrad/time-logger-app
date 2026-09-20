import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/meeting.dart';
import '../services/jalali.dart';
import '../widgets/common.dart';

class MeetingsScreen extends StatefulWidget {
  final List<Meeting> meetings;
  final Future<void> Function() onChanged;

  const MeetingsScreen({
    super.key,
    required this.meetings,
    required this.onChanged,
  });

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  final _titleCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _durCtrl = TextEditingController(text: '60');
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _linkCtrl.dispose();
    _durCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_titleCtrl.text.isEmpty || _linkCtrl.text.isEmpty) {
      showSnack(context, 'عنوان و لینک را وارد کنید', color: AppColors.danger);
      return;
    }
    final dt = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    final newId = widget.meetings.isEmpty
        ? 1
        : (widget.meetings.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
    widget.meetings.add(Meeting(
      id: newId,
      title: _titleCtrl.text,
      link: _linkCtrl.text,
      time: dt.toIso8601String(),
      duration: int.tryParse(_durCtrl.text) ?? 60,
    ));
    await widget.onChanged();
    if (!mounted) return;
    setState(() {
      _titleCtrl.clear();
      _linkCtrl.clear();
    });
    showSnack(context, 'جلسه اضافه شد', color: AppColors.primary);
  }

  Future<void> _openLink(String link) async {
    try {
      final uri = Uri.parse(link);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        showSnack(context, 'نمی‌توان لینک را باز کرد', color: AppColors.danger);
      }
    } catch (e) {
      if (!mounted) return;
      showSnack(context, 'خطا در باز کردن لینک', color: AppColors.danger);
    }
  }

  Future<void> _delete(Meeting m) async {
    final ok = await confirmDialog(
      context,
      title: 'حذف جلسه',
      message: '«${m.title}» حذف شود؟',
    );
    if (!ok) return;
    widget.meetings.removeWhere((x) => x.id == m.id);
    await widget.onChanged();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.meetings]..sort((a, b) => b.time.compareTo(a.time));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('📅 افزودن جلسه', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                AppTextField(controller: _titleCtrl, label: 'عنوان جلسه', icon: Icons.title),
                const SizedBox(height: 8),
                AppTextField(controller: _linkCtrl, label: 'لینک', icon: Icons.link),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(toJalaliDate(_date)),
                        onPressed: () async {
                          final d = await pickDate(context, _date);
                          if (d == null) return;
                          if (!mounted) return;
                          setState(() => _date = d);
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
                          if (t == null) return;
                          if (!mounted) return;
                          setState(() => _time = t);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _durCtrl,
                  label: 'مدت (دقیقه)',
                  keyboardType: TextInputType.number,
                  icon: Icons.timer,
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'افزودن',
                  icon: Icons.add,
                  color: AppColors.accentPurple,
                  onPressed: _add,
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
                    const Text('📋 لیست جلسات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('${sorted.length} مورد', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                if (sorted.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('هنوز جلسه‌ای ثبت نشده', style: TextStyle(color: Colors.white54))),
                  )
                else
                  ...sorted.map((m) => _meetingTile(m)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _meetingTile(Meeting m) {
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
              const Icon(Icons.event, color: AppColors.accentPurple, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(m.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new, color: AppColors.secondary, size: 20),
                onPressed: () => _openLink(m.link),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.danger, size: 20),
                onPressed: () => _delete(m),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${toJalaliDateTime(DateTime.parse(m.time))} — ${m.duration} دقیقه',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text('🔗 ${m.link}', style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 11)),
        ],
      ),
    );
  }
}