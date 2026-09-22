// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../providers/language_provider.dart';
import '../l10n/strings.dart';
import '../models/goal.dart';
import '../widgets/common.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _level = 'daily';
  String? _domain;
  DateTime? _deadline;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String _levelLabel(S s) {
    switch (_level) {
      case 'daily': return s.daily;
      case 'weekly': return s.weekly;
      case 'monthly': return s.monthly;
      case 'seasonal': return s.seasonal;
      case 'yearly': return s.yearly;
      case 'v2': return s.vision2;
      case 'v3': return s.vision3;
      case 'v4': return s.vision4;
      case 'v5': return s.vision5;
    }
    return _level;
  }

  Color _levelColor() {
    switch (_level) {
      case 'daily': return const Color(0xFF4CAF50);
      case 'weekly': return const Color(0xFF2196F3);
      case 'monthly': return const Color(0xFFFF9800);
      case 'seasonal': return const Color(0xFF9C27B0);
      case 'yearly': return const Color(0xFFE91E63);
      default: return const Color(0xFF607D8B);
    }
  }

  Future<void> _add() async {
    final s = S(context.read<LanguageProvider>().lang);
    if (_titleCtrl.text.isEmpty || _domain == null) {
      showSnack(context, s.goalTitle, color: AppColors.danger);
      return;
    }
    final data = context.read<DataProvider>();
    final newId = data.goals.isEmpty ? 1 : (data.goals.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
    data.goals.add(Goal(
      id: newId,
      title: _titleCtrl.text,
      level: _level,
      domain: _domain!,
      progress: 0,
      note: _noteCtrl.text,
      deadline: _deadline?.toIso8601String(),
    ));
    await data.saveGoals();
    if (!mounted) return;
    setState(() {
      _titleCtrl.clear();
      _noteCtrl.clear();
      _deadline = null;
    });
    showSnack(context, s.saved, color: AppColors.primary);
  }

  Future<void> _editProgress(Goal g) async {
    final ctrl = TextEditingController(text: g.progress.toString());
    final res = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('درصد پیشرفت'),
        content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(filled: true)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو')),
          TextButton(onPressed: () => Navigator.pop(context, int.tryParse(ctrl.text)), child: const Text('ذخیره')),
        ],
      ),
    );
    if (res != null && res >= 0 && res <= 100) {
      g.progress = res;
      if (!mounted) return;
      await context.read<DataProvider>().saveGoals();
    }
  }

  Future<void> _delete(Goal g) async {
    final ok = await confirmDialog(context, title: 'حذف هدف');
    if (!ok) return;
    final data = context.read<DataProvider>();
    data.goals.removeWhere((x) => x.id == g.id);
    await data.saveGoals();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final s = S(context.watch<LanguageProvider>().lang);

    if (_domain == null && data.domains.isNotEmpty) {
      _domain = data.domains.first.name;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('🎯 ${s.addGoal}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('${s.level}:'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _level,
                        isExpanded: true,
                        dropdownColor: AppColors.input,
                        items: [
                          DropdownMenuItem(value: 'daily', child: Text(s.daily)),
                          DropdownMenuItem(value: 'weekly', child: Text(s.weekly)),
                          DropdownMenuItem(value: 'monthly', child: Text(s.monthly)),
                          DropdownMenuItem(value: 'seasonal', child: Text(s.seasonal)),
                          DropdownMenuItem(value: 'yearly', child: Text(s.yearly)),
                          DropdownMenuItem(value: 'v2', child: Text(s.vision2)),
                          DropdownMenuItem(value: 'v3', child: Text(s.vision3)),
                          DropdownMenuItem(value: 'v4', child: Text(s.vision4)),
                          DropdownMenuItem(value: 'v5', child: Text(s.vision5)),
                        ],
                        onChanged: (v) => setState(() => _level = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('${s.domain}:'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _domain,
                        isExpanded: true,
                        dropdownColor: AppColors.input,
                        items: data.domains.map((d) => DropdownMenuItem(value: d.name, child: Text(d.name))).toList(),
                        onChanged: (v) => setState(() => _domain = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppTextField(controller: _titleCtrl, label: s.goalTitle, icon: Icons.flag),
                const SizedBox(height: 8),
                AppTextField(controller: _noteCtrl, label: s.goalNote, icon: Icons.note),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_deadline == null ? s.deadline : _deadline.toString().substring(0, 10)),
                  onPressed: () async {
                    final d = await pickDate(context, DateTime.now());
                    if (d != null) setState(() => _deadline = d);
                  },
                ),
                const SizedBox(height: 8),
                PrimaryButton(label: s.add, icon: Icons.add, color: AppColors.secondary, onPressed: _add),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('📋 ${s.goalList}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (data.goals.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(child: Text(s.noGoals, style: const TextStyle(color: Colors.white54))),
                  )
                else
                  ...data.goals.reversed.map((g) => _goalTile(g, s)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _goalTile(Goal g, S s) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: _levelColor(), width: 4)),
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
                  color: _levelColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(_levelLabel(s), style: TextStyle(color: _levelColor(), fontSize: 11)),
              ),
              const SizedBox(width: 8),
              Text(g.domain, style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
          if (g.note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('📝 ${g.note}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: g.progress / 100,
                  backgroundColor: Colors.white12,
                  color: _levelColor(),
                  minHeight: 6,
                ),
              ),
              const SizedBox(width: 8),
              Text('${g.progress}%', style: TextStyle(color: _levelColor(), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}