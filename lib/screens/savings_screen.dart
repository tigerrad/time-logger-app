// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../providers/language_provider.dart';
import '../l10n/strings.dart';
import '../models/saving.dart';
import '../widgets/common.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final _titleCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _currentCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    _currentCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final s = S(context.read<LanguageProvider>().lang);
    if (_titleCtrl.text.isEmpty) {
      showSnack(context, s.savingTitle, color: AppColors.danger);
      return;
    }
    final data = context.read<DataProvider>();
    final newId = data.savings.isEmpty ? 1 : (data.savings.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
    data.savings.add(Saving(
      id: newId,
      title: _titleCtrl.text,
      target: double.tryParse(_targetCtrl.text) ?? 0,
      current: double.tryParse(_currentCtrl.text) ?? 0,
    ));
    await data.saveSavings();
    if (!mounted) return;
    setState(() {
      _titleCtrl.clear();
      _targetCtrl.clear();
      _currentCtrl.clear();
    });
    showSnack(context, s.saved, color: AppColors.primary);
  }

  Future<void> _addAmount(Saving s) async {
    final ctrl = TextEditingController();
    final res = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('مبلغ افزودنی'),
        content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(filled: true)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو')),
          TextButton(onPressed: () => Navigator.pop(context, double.tryParse(ctrl.text)), child: const Text('افزودن')),
        ],
      ),
    );
    if (res != null && res > 0) {
      s.history.add(SavingTransaction(
        id: s.history.length + 1,
        amount: res,
        type: 'deposit',
        date: DateTime.now().toIso8601String(),
      ));
      s.current += res;
      if (!mounted) return;
      await context.read<DataProvider>().saveSavings();
    }
  }

  Future<void> _withdraw(Saving s) async {
    final ctrl = TextEditingController();
    final res = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('برداشت از پس‌انداز'),
        content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: InputDecoration(filled: true, helperText: 'موجودی: ${s.current}')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو')),
          TextButton(onPressed: () => Navigator.pop(context, double.tryParse(ctrl.text)), child: const Text('برداشت')),
        ],
      ),
    );
    if (res != null && res > 0 && res <= s.current) {
      s.history.add(SavingTransaction(
        id: s.history.length + 1,
        amount: res,
        type: 'withdraw',
        date: DateTime.now().toIso8601String(),
      ));
      s.current -= res;
      if (!mounted) return;
      await context.read<DataProvider>().saveSavings();
    }
  }

  Future<void> _delete(Saving s) async {
    final ok = await confirmDialog(context, title: 'حذف پس‌انداز');
    if (!ok) return;
    final data = context.read<DataProvider>();
    data.savings.removeWhere((x) => x.id == s.id);
    await data.saveSavings();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final s = S(context.watch<LanguageProvider>().lang);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('💰 ${s.addSaving}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                AppTextField(controller: _titleCtrl, label: s.savingTitle, icon: Icons.savings),
                const SizedBox(height: 8),
                AppTextField(controller: _targetCtrl, label: s.targetAmount, keyboardType: TextInputType.number, icon: Icons.flag),
                const SizedBox(height: 8),
                AppTextField(controller: _currentCtrl, label: s.currentAmount, keyboardType: TextInputType.number, icon: Icons.attach_money),
                const SizedBox(height: 8),
                PrimaryButton(label: s.add, icon: Icons.add, color: AppColors.warning, onPressed: _add),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('📋 ${s.savingsList}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (data.savings.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(child: Text(s.noSavings, style: const TextStyle(color: Colors.white54))),
                  )
                else
                  ...data.savings.map((sv) => _savingTile(sv, s)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _savingTile(Saving sv, S s) {
    final pct = sv.target > 0 ? (sv.current / sv.target * 100) : 0.0;
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
              Expanded(child: Text(sv.title, style: const TextStyle(fontWeight: FontWeight.bold))),
              IconButton(icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 20), onPressed: () => _addAmount(sv), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.remove_circle, color: AppColors.warning, size: 20), onPressed: () => _withdraw(sv), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.delete, color: AppColors.danger, size: 20), onPressed: () => _delete(sv), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ],
          ),
          const SizedBox(height: 4),
          Text('${sv.current.toStringAsFixed(0)} / ${sv.target.toStringAsFixed(0)} (${pct.toStringAsFixed(1)}%)', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: (pct / 100).clamp(0.0, 1.0),
            backgroundColor: Colors.white12,
            color: pct >= 100 ? AppColors.primary : AppColors.warning,
            minHeight: 6,
          ),
          if (sv.history.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('${s.share}: ${sv.history.length}', style: const TextStyle(fontSize: 11, color: Colors.white54)),
            ),
        ],
      ),
    );
  }
}