import 'package:flutter/material.dart';
import '../models/domain.dart';
import '../models/goal.dart';
import '../widgets/common.dart';

class GoalsScreen extends StatefulWidget {
  final List<Domain> domains;
  final List<Goal> goals;
  final Future<void> Function() onChanged;

  const GoalsScreen({
    super.key,
    required this.domains,
    required this.goals,
    required this.onChanged,
  });

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _titleCtrl = TextEditingController();
  String _level = 'روزانه';
  String? _domain;

  final _levels = [
    'روزانه',
    'هفتگی',
    'ماهانه',
    'فصلی',
    'سالانه',
    'چشم‌انداز ۲ ساله',
    'چشم‌انداز ۳ ساله',
    'چشم‌انداز ۴ ساله',
    'چشم‌انداز ۵ ساله',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.domains.isNotEmpty) _domain = widget.domains.first.name;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_titleCtrl.text.isEmpty || _domain == null) {
      showSnack(context, 'عنوان هدف را وارد کنید', color: AppColors.danger);
      return;
    }
    final newId = widget.goals.isEmpty
        ? 1
        : (widget.goals.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
    widget.goals.add(Goal(
      id: newId,
      title: _titleCtrl.text,
      level: _level,
      domain: _domain!,
      progress: 0,
    ));
    await widget.onChanged();
    if (!mounted) return;
    setState(() => _titleCtrl.clear());
    showSnack(context, 'هدف اضافه شد', color: AppColors.primary);
  }

  Color _levelColor(String level) {
    if (level.contains('روزانه')) return const Color(0xFF4CAF50);
    if (level.contains('هفتگی')) return const Color(0xFF2196F3);
    if (level.contains('ماهانه')) return const Color(0xFFFF9800);
    if (level.contains('فصلی')) return const Color(0xFF9C27B0);
    if (level.contains('سالانه')) return const Color(0xFFE91E63);
    return const Color(0xFF607D8B);
  }

  Future<void> _editProgress(Goal g) async {
    final ctrl = TextEditingController(text: g.progress.toString());
    final res = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('درصد پیشرفت', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(filled: true, fillColor: AppColors.input),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, int.tryParse(ctrl.text)),
            child: const Text('ذخیره', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
    if (res != null && res >= 0 && res <= 100) {
      g.progress = res;
      await widget.onChanged();
      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> _delete(Goal g) async {
    final ok = await confirmDialog(context, title: 'حذف هدف', message: '«${g.title}» حذف شود؟');
    if (!ok) return;
    widget.goals.removeWhere((x) => x.id == g.id);
    await widget.onChanged();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('🎯 افزودن هدف', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('سطح:'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _level,
                        isExpanded: true,
                        dropdownColor: AppColors.input,
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
                        dropdownColor: AppColors.input,
                        items: widget.domains.map((d) => DropdownMenuItem(value: d.name, child: Text(d.name))).toList(),
                        onChanged: (v) => setState(() => _domain = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppTextField(controller: _titleCtrl, label: 'عنوان هدف', icon: Icons.flag),
                const SizedBox(height: 8),
                PrimaryButton(label: 'افزودن', icon: Icons.add, color: AppColors.secondary, onPressed: _add),
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
                    const Text('📋 لیست اهداف', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('${widget.goals.length} مورد', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                if (widget.goals.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('هنوز هدفی ثبت نشده', style: TextStyle(color: Colors.white54))),
                  )
                else
                  ...widget.goals.reversed.map((g) => _goalTile(g)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _goalTile(Goal g) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: _levelColor(g.level), width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(g.title, style: const TextStyle(fontWeight: FontWeight.bold))),
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.warning, size: 20),
                onPressed: () => _editProgress(g),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.danger, size: 20),
                onPressed: () => _delete(g),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _levelColor(g.level).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(g.level, style: TextStyle(color: _levelColor(g.level), fontSize: 11)),
              ),
              const SizedBox(width: 8),
              Text('حوزه: ${g.domain}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: g.progress / 100,
                  backgroundColor: Colors.white12,
                  color: AppColors.primary,
                  minHeight: 6,
                ),
              ),
              const SizedBox(width: 8),
              Text('${g.progress}%', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}