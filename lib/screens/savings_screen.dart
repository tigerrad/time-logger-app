import 'package:flutter/material.dart';
import '../models/saving.dart';
import '../widgets/common.dart';

class SavingsScreen extends StatefulWidget {
  final List<Saving> savings;
  final Future<void> Function() onChanged;

  const SavingsScreen({
    super.key,
    required this.savings,
    required this.onChanged,
  });

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
    if (_titleCtrl.text.isEmpty) {
      showSnack(context, 'عنوان را وارد کنید', color: AppColors.danger);
      return;
    }
    final newId = widget.savings.isEmpty
        ? 1
        : (widget.savings.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
    widget.savings.add(Saving(
      id: newId,
      title: _titleCtrl.text,
      target: double.tryParse(_targetCtrl.text) ?? 0,
      current: double.tryParse(_currentCtrl.text) ?? 0,
    ));
    await widget.onChanged();
    if (!mounted) return;
    setState(() {
      _titleCtrl.clear();
      _targetCtrl.clear();
      _currentCtrl.clear();
    });
    showSnack(context, 'پس‌انداز اضافه شد', color: AppColors.primary);
  }

  Future<void> _addAmount(Saving s) async {
    final ctrl = TextEditingController();
    final res = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('مبلغ افزودنی', style: TextStyle(color: Colors.white)),
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
            onPressed: () => Navigator.pop(context, double.tryParse(ctrl.text)),
            child: const Text('افزودن', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
    if (res != null) {
      s.current += res;
      await widget.onChanged();
      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> _withdraw(Saving s) async {
    final ctrl = TextEditingController();
    final res = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('برداشت از پس‌انداز', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.input,
            helperText: 'موجودی: ${s.current.toStringAsFixed(0)}',
            helperStyle: const TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, double.tryParse(ctrl.text)),
            child: const Text('برداشت', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (res != null && res > 0 && res <= s.current) {
      s.current -= res;
      await widget.onChanged();
      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> _delete(Saving s) async {
    final ok = await confirmDialog(
      context,
      title: 'حذف پس‌انداز',
      message: '«${s.title}» حذف شود؟',
    );
    if (!ok) return;
    widget.savings.removeWhere((x) => x.id == s.id);
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
                const Text('💰 افزودن پس‌انداز', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                AppTextField(controller: _titleCtrl, label: 'عنوان', icon: Icons.savings),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _targetCtrl,
                  label: 'مبلغ هدف',
                  keyboardType: TextInputType.number,
                  icon: Icons.flag,
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _currentCtrl,
                  label: 'مبلغ فعلی',
                  keyboardType: TextInputType.number,
                  icon: Icons.attach_money,
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'افزودن',
                  icon: Icons.add,
                  color: AppColors.warning,
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
                    const Text('📋 لیست پس‌اندازها', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('${widget.savings.length} مورد', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                if (widget.savings.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('هنوز پس‌اندازی ثبت نشده', style: TextStyle(color: Colors.white54))),
                  )
                else
                  ...widget.savings.map((s) => _savingTile(s)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _savingTile(Saving s) {
    final pct = s.target > 0 ? (s.current / s.target * 100) : 0.0;
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
              Expanded(child: Text(s.title, style: const TextStyle(fontWeight: FontWeight.bold))),
              IconButton(
                icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 20),
                onPressed: () => _addAmount(s),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.remove_circle, color: AppColors.warning, size: 20),
                onPressed: () => _withdraw(s),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.danger, size: 20),
                onPressed: () => _delete(s),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${s.current.toStringAsFixed(0)} / ${s.target.toStringAsFixed(0)} (${pct.toStringAsFixed(1)}%)',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: (pct / 100).clamp(0.0, 1.0),
            backgroundColor: Colors.white12,
            color: pct >= 100 ? AppColors.primary : AppColors.warning,
            minHeight: 6,
          ),
        ],
      ),
    );
  }
}