import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../models/finance_transaction.dart';
import '../models/finance_category.dart';
import '../services/jalali.dart';
import '../widgets/common.dart';

class FinanceScreen extends StatefulWidget {
  final List<FinanceTransaction> transactions;
  final List<FinanceCategory> categories;
  final Future<void> Function() onChanged;

  const FinanceScreen({
    super.key,
    required this.transactions,
    required this.categories,
    required this.onChanged,
  });

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  String _period = 'Ø§ÛŒÙ† Ù…Ø§Ù‡';
  final _periods = ['Ø§Ù…Ø±ÙˆØ²', 'Ø§ÛŒÙ† Ù‡ÙØªÙ‡', 'Ø§ÛŒÙ† Ù…Ø§Ù‡', 'Ø§Ù…Ø³Ø§Ù„', 'Ú©Ù„'];

  final _amountCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  String _formType = 'expense';
  String? _formCategory;
  final DateTime _formDate = DateTime.now();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  List<FinanceTransaction> _filtered() {
    final now = DateTime.now();
    return widget.transactions.where((t) {
      final dt = DateTime.parse(t.date);
      switch (_period) {
        case 'Ø§Ù…Ø±ÙˆØ²':
          return dt.year == now.year && dt.month == now.month && dt.day == now.day;
        case 'Ø§ÛŒÙ† Ù‡ÙØªÙ‡':
          final start = now.subtract(Duration(days: now.weekday - 1));
          final s = DateTime(start.year, start.month, start.day);
          return dt.isAfter(s) || dt.isAtSameMomentAs(s);
        case 'Ø§ÛŒÙ† Ù…Ø§Ù‡':
          return dt.year == now.year && dt.month == now.month;
        case 'Ø§Ù…Ø³Ø§Ù„':
          return dt.year == now.year;
        default:
          return true;
      }
    }).toList();
  }

  List<FinanceCategory> _catsFor(String type) =>
      widget.categories.where((c) => c.type == type).toList();

  double _sumIncome(List<FinanceTransaction> list) =>
      list.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);

  double _sumExpense(List<FinanceTransaction> list) =>
      list.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount);

  Future<void> _addTransaction() async {
    if (_amountCtrl.text.isEmpty || _formCategory == null || _titleCtrl.text.isEmpty) {
      showSnack(context, 'Ù…Ø¨Ù„ØºØŒ Ø¯Ø³ØªÙ‡ Ùˆ Ø¹Ù†ÙˆØ§Ù† Ø±Ø§ ÙˆØ§Ø±Ø¯ Ú©Ù†ÛŒØ¯', color: AppColors.danger);
      return;
    }
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) {
      showSnack(context, 'Ù…Ø¨Ù„Øº Ù…Ø¹ØªØ¨Ø± ÙˆØ§Ø±Ø¯ Ú©Ù†ÛŒØ¯', color: AppColors.danger);
      return;
    }
    final newId = widget.transactions.isEmpty
        ? 1
        : (widget.transactions.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
    widget.transactions.add(FinanceTransaction(
      id: newId,
      type: _formType,
      category: _formCategory!,
      amount: amount,
      title: _titleCtrl.text,
      note: _noteCtrl.text,
      date: _formDate.toIso8601String(),
    ));
    await widget.onChanged();
    if (!mounted) return;
    setState(() {
      _amountCtrl.clear();
      _titleCtrl.clear();
      _noteCtrl.clear();
    });
    showSnack(context, 'Ø«Ø¨Øª Ø´Ø¯: $amount ØªÙˆÙ…Ø§Ù†', color: AppColors.primary);
  }

  Future<void> _delete(FinanceTransaction t) async {
    final ok = await confirmDialog(context, title: 'Ø­Ø°Ù ØªØ±Ø§Ú©Ù†Ø´', message: 'Â«${t.title}Â» Ø­Ø°Ù Ø´ÙˆØ¯ØŸ');
    if (!ok) return;
    widget.transactions.removeWhere((x) => x.id == t.id);
    await widget.onChanged();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _editBudget(FinanceCategory c) async {
    _budgetCtrl.text = c.monthlyBudget.toStringAsFixed(0);
    final res = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Ø¨ÙˆØ¯Ø¬Ù‡ Ù…Ø§Ù‡Ø§Ù†Ù‡: ${c.name}', style: const TextStyle(color: Colors.white, fontSize: 14)),
        content: TextField(
          controller: _budgetCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Ù…Ø¨Ù„Øº Ø¨ÙˆØ¯Ø¬Ù‡ (ØªÙˆÙ…Ø§Ù†)',
            filled: true,
            fillColor: AppColors.input,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ù„ØºÙˆ', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, double.tryParse(_budgetCtrl.text)),
            child: const Text('Ø°Ø®ÛŒØ±Ù‡', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
    if (res != null) {
      final idx = widget.categories.indexWhere((x) => x.id == c.id);
      if (idx >= 0) {
        widget.categories[idx] = c.copyWith(monthlyBudget: res);
        await widget.onChanged();
        if (!mounted) return;
        setState(() {});
      }
    }
  }

  Future<void> _exportReport() async {
    final list = _filtered();
    final income = _sumIncome(list);
    final expense = _sumExpense(list);
    final balance = income - expense;
    final buf = StringBuffer();
    buf.writeln('Ú¯Ø²Ø§Ø±Ø´ Ù…Ø§Ù„ÛŒ â€” $_period');
    buf.writeln('ØªØ§Ø±ÛŒØ®: ${toJalaliDateTime(DateTime.now())}');
    buf.writeln('â”€' * 30);
    buf.writeln('Ø¬Ù…Ø¹ Ø¯Ø±Ø¢Ù…Ø¯: ${income.toStringAsFixed(0)} ØªÙˆÙ…Ø§Ù†');
    buf.writeln('Ø¬Ù…Ø¹ Ù‡Ø²ÛŒÙ†Ù‡: ${expense.toStringAsFixed(0)} ØªÙˆÙ…Ø§Ù†');
    buf.writeln('ØªØ±Ø§Ø²: ${balance.toStringAsFixed(0)} ØªÙˆÙ…Ø§Ù†');
    try {
      final dir = Directory.systemTemp;
      final file = File('${dir.path}/finance_report_${DateTime.now().millisecondsSinceEpoch}.txt');
      await file.writeAsString(buf.toString());
      await Share.shareXFiles([XFile(file.path)], text: 'Ú¯Ø²Ø§Ø±Ø´ Ù…Ø§Ù„ÛŒ');
    } catch (e) {
      if (!mounted) return;
      showSnack(context, 'Ø®Ø·Ø§ Ø¯Ø± Ø§Ø´ØªØ±Ø§Ú©â€ŒÚ¯Ø°Ø§Ø±ÛŒ', color: AppColors.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered();
    final income = _sumIncome(list);
    final expense = _sumExpense(list);
    final balance = income - expense;
    final isPositive = balance >= 0;
    final byCat = <String, double>{};
    for (final t in list.where((x) => x.isExpense)) {
      byCat[t.category] = (byCat[t.category] ?? 0) + t.amount;
    }
    final now = DateTime.now();
    final thisMonthExpense = <String, double>{};
    for (final t in widget.transactions.where((x) =>
        x.isExpense &&
        DateTime.parse(x.date).year == now.year &&
        DateTime.parse(x.date).month == now.month)) {
      thisMonthExpense[t.category] = (thisMonthExpense[t.category] ?? 0) + t.amount;
    }

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
                    const Icon(Icons.account_balance_wallet, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text('ðŸ’° ØªØ±Ø§Ø² Ù…Ø§Ù„ÛŒ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    DropdownButton<String>(
                      value: _period,
                      dropdownColor: AppColors.input,
                      underline: const SizedBox(),
                      items: _periods.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 12)))).toList(),
                      onChanged: (v) => setState(() => _period = v!),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(child: _statBox('Ø¯Ø±Ø¢Ù…Ø¯', income, const Color(0xFF4CAF50))),
                    const SizedBox(width: 8),
                    Expanded(child: _statBox('Ù‡Ø²ÛŒÙ†Ù‡', expense, const Color(0xFFF44336))),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isPositive ? const Color(0xFF4CAF50).withOpacity(0.2) : const Color(0xFFF44336).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(isPositive ? Icons.trending_up : Icons.trending_down, color: isPositive ? const Color(0xFF4CAF50) : const Color(0xFFF44336)),
                      const SizedBox(width: 8),
                      Text('ØªØ±Ø§Ø²: ${balance.abs().toStringAsFixed(0)} ØªÙˆÙ…Ø§Ù†', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isPositive ? const Color(0xFF4CAF50) : const Color(0xFFF44336))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (byCat.isNotEmpty)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ðŸ¥§ Ø³Ù‡Ù… Ù‡Ø± Ø¯Ø³ØªÙ‡ Ø§Ø² Ù‡Ø²ÛŒÙ†Ù‡', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: byCat.entries.map((e) {
                          final cat = widget.categories.firstWhere(
                            (c) => c.name == e.key,
                            orElse: () => FinanceCategory(id: 0, name: e.key, type: 'expense', color: '#888888'),
                          );
                          final color = _hexToColor(cat.color);
                          final pct = expense > 0 ? (e.value / expense * 100) : 0;
                          return PieChartSectionData(
                            color: color,
                            value: e.value,
                            title: '${pct.toStringAsFixed(0)}%',
                            radius: 70,
                            titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('âž• Ø«Ø¨Øª ØªØ±Ø§Ú©Ù†Ø´ Ø¬Ø¯ÛŒØ¯', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Ø¯Ø±Ø¢Ù…Ø¯'),
                        selected: _formType == 'income',
                        onSelected: (_) => setState(() {
                          _formType = 'income';
                          _formCategory = null;
                        }),
                        selectedColor: const Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Ù‡Ø²ÛŒÙ†Ù‡'),
                        selected: _formType == 'expense',
                        onSelected: (_) => setState(() {
                          _formType = 'expense';
                          _formCategory = null;
                        }),
                        selectedColor: const Color(0xFFF44336),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _formCategory,
                  decoration: const InputDecoration(
                    labelText: 'Ø¯Ø³ØªÙ‡â€ŒØ¨Ù†Ø¯ÛŒ',
                    filled: true,
                    fillColor: AppColors.input,
                  ),
                  dropdownColor: AppColors.input,
                  items: _catsFor(_formType).map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                  onChanged: (v) => setState(() => _formCategory = v),
                ),
                const SizedBox(height: 8),
                AppTextField(controller: _amountCtrl, label: 'Ù…Ø¨Ù„Øº (ØªÙˆÙ…Ø§Ù†)', keyboardType: TextInputType.number, icon: Icons.attach_money),
                const SizedBox(height: 8),
                AppTextField(controller: _titleCtrl, label: 'Ø¹Ù†ÙˆØ§Ù† / ØªÙˆØ¶ÛŒØ­ Ú©ÙˆØªØ§Ù‡', icon: Icons.title),
                const SizedBox(height: 8),
                AppTextField(controller: _noteCtrl, label: 'ÛŒØ§Ø¯Ø¯Ø§Ø´Øª (Ø§Ø®ØªÛŒØ§Ø±ÛŒ)', maxLines: 2),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Ø«Ø¨Øª',
                  icon: Icons.check,
                  color: _formType == 'income' ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                  onPressed: _addTransaction,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('ðŸŽ¯ Ø¨ÙˆØ¯Ø¬Ù‡ Ù…Ø§Ù‡Ø§Ù†Ù‡ Ø¯Ø³ØªÙ‡â€ŒÙ‡Ø§', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const Divider(),
                if (_catsFor('expense').isEmpty)
                  const Text('Ø¯Ø³ØªÙ‡â€ŒØ§ÛŒ ÙˆØ¬ÙˆØ¯ Ù†Ø¯Ø§Ø±Ø¯', style: TextStyle(color: Colors.white54))
                else
                  ..._catsFor('expense').map((c) {
                    final spent = thisMonthExpense[c.name] ?? 0;
                    final pct = c.monthlyBudget > 0 ? (spent / c.monthlyBudget) : 0.0;
                    final over = c.monthlyBudget > 0 && spent > c.monthlyBudget;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(c.name, style: const TextStyle(fontSize: 13))),
                              Text(
                                c.monthlyBudget > 0 ? '${spent.toStringAsFixed(0)} / ${c.monthlyBudget.toStringAsFixed(0)}' : 'Ø¨Ø¯ÙˆÙ† Ø¨ÙˆØ¯Ø¬Ù‡',
                                style: TextStyle(fontSize: 11, color: over ? const Color(0xFFF44336) : Colors.white70),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 16, color: AppColors.warning),
                                onPressed: () => _editBudget(c),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          if (c.monthlyBudget > 0) ...[
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: pct.clamp(0.0, 1.0),
                              backgroundColor: Colors.white12,
                              color: over ? const Color(0xFFF44336) : AppColors.primary,
                              minHeight: 6,
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text('ðŸ“‹ ØªØ±Ø§Ú©Ù†Ø´â€ŒÙ‡Ø§', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('${list.length} Ù…ÙˆØ±Ø¯', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.share, color: AppColors.secondary, size: 20),
                      onPressed: _exportReport,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('ØªØ±Ø§Ú©Ù†Ø´ÛŒ Ø¯Ø± Ø§ÛŒÙ† Ø¨Ø§Ø²Ù‡ Ù†ÛŒØ³Øª', style: TextStyle(color: Colors.white54))),
                  )
                else
                  ...list.reversed.map((t) => _txTile(t)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: color)),
          const SizedBox(height: 4),
          Text(amount.toStringAsFixed(0), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const Text('ØªÙˆÙ…Ø§Ù†', style: TextStyle(fontSize: 10, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _txTile(FinanceTransaction t) {
    final color = t.isIncome ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(8),
        border: Border(right: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        children: [
          Icon(t.isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    Text(
                      '${t.isIncome ? "+" : "-"}${t.amount.toStringAsFixed(0)}',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text('${t.category} â€¢ ${toJalaliDate(DateTime.parse(t.date))}', style: const TextStyle(fontSize: 11, color: Colors.white60)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: AppColors.danger, size: 18),
            onPressed: () => _delete(t),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    if (h.length == 6) {
      return Color(int.parse('FF$h', radix: 16));
    }
    return Colors.grey;
  }
}