// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:io';
import '../providers/data_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../l10n/strings.dart';
import '../models/finance_transaction.dart';
import '../models/finance_category.dart';
import '../services/jalali.dart';
import '../widgets/common.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  String _period = 'all';
  final _amountCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final ScreenshotController _screenshotCtrl = ScreenshotController();
  String _formType = 'expense';
  String? _formCategory;
  DateTime _formDate = DateTime.now();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  List<FinanceTransaction> _filtered(DataProvider data) {
    final now = DateTime.now();
    return data.financeTransactions.where((t) {
      final dt = DateTime.parse(t.date);
      switch (_period) {
        case 'today':
          return dt.year == now.year && dt.month == now.month && dt.day == now.day;
        case 'week':
          final start = now.subtract(Duration(days: now.weekday - 1));
          final s = DateTime(start.year, start.month, start.day);
          return dt.isAfter(s) || dt.isAtSameMomentAs(s);
        case 'month':
          return dt.year == now.year && dt.month == now.month;
        case 'year':
          return dt.year == now.year;
        default:
          return true;
      }
    }).toList();
  }

  Future<void> _add() async {
    final s = S(context.read<LanguageProvider>().lang);
    if (_amountCtrl.text.isEmpty || _formCategory == null || _titleCtrl.text.isEmpty) {
      showSnack(context, s.errorOccurred, color: AppColors.danger);
      return;
    }
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) return;

    final data = context.read<DataProvider>();
    final newId = data.financeTransactions.isEmpty ? 1 : (data.financeTransactions.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
    data.financeTransactions.add(FinanceTransaction(
      id: newId,
      type: _formType,
      category: _formCategory!,
      amount: amount,
      title: _titleCtrl.text,
      note: _noteCtrl.text,
      date: _formDate.toIso8601String(),
    ));
    await data.saveFinanceTransactions();
    if (!mounted) return;
    setState(() {
      _amountCtrl.clear();
      _titleCtrl.clear();
      _noteCtrl.clear();
    });
    showSnack(context, s.saved, color: AppColors.primary);
  }

  Future<void> _addCategory() async {
    final nameCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    String newType = _formType;
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('افزودن دسته جدید'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'نام دسته', filled: true)),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: newType,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'income', child: Text('درآمد')),
                  DropdownMenuItem(value: 'expense', child: Text('هزینه')),
                ],
                onChanged: (v) => setDlg(() => newType = v!),
              ),
              const SizedBox(height: 8),
              TextField(controller: budgetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'بودجه ماهانه (اختیاری)', filled: true)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('لغو')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ذخیره')),
          ],
        ),
      ),
    );
    if (res == true && nameCtrl.text.isNotEmpty) {
      final data = context.read<DataProvider>();
      final newId = data.financeCategories.isEmpty ? 1 : (data.financeCategories.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
      data.financeCategories.add(FinanceCategory(
        id: newId,
        name: nameCtrl.text,
        type: newType,
        color: '#FF9800',
        monthlyBudget: double.tryParse(budgetCtrl.text) ?? 0,
      ));
      await data.saveFinanceCategories();
    }
  }

  Future<void> _editBudget(FinanceCategory c) async {
    _budgetCtrl.text = c.monthlyBudget.toStringAsFixed(0);
    final res = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('بودجه ماهانه: ${c.name}'),
        content: TextField(controller: _budgetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'مبلغ بودجه', filled: true)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو')),
          TextButton(onPressed: () => Navigator.pop(context, double.tryParse(_budgetCtrl.text)), child: const Text('ذخیره')),
        ],
      ),
    );
    if (res != null) {
      final data = context.read<DataProvider>();
      final idx = data.financeCategories.indexWhere((x) => x.id == c.id);
      if (idx >= 0) {
        data.financeCategories[idx] = c.copyWith(monthlyBudget: res);
        await data.saveFinanceCategories();
      }
    }
  }

  Future<void> _shareReport(String text) async {
    try {
      final dir = Directory.systemTemp;
      final file = File('${dir.path}/finance_${DateTime.now().millisecondsSinceEpoch}.txt');
      await file.writeAsString(text);
      await Share.shareXFiles([XFile(file.path)], text: 'گزارش مالی');
    } catch (_) {}
  }

  Future<void> _takeScreenshot() async {
    final s = S(context.read<LanguageProvider>().lang);
    try {
      final bytes = await _screenshotCtrl.capture();
      if (bytes == null) return;
      final dir = Directory.systemTemp;
      final file = File('${dir.path}/finance_shot_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'اسکرین‌شات مالی');
    } catch (_) {
      if (!mounted) return;
      showSnack(context, s.errorOccurred, color: AppColors.danger);
    }
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final theme = context.watch<ThemeProvider>();
    final s = S(context.watch<LanguageProvider>().lang);

    final cats = data.financeCategories.where((c) => c.type == _formType).toList();
    if (_formCategory == null && cats.isNotEmpty) {
      _formCategory = cats.first.name;
    }

    final filtered = _filtered(data);
    final income = filtered.where((t) => t.isIncome).fold<double>(0, (s, t) => s + t.amount);
    final expense = filtered.where((t) => t.isExpense).fold<double>(0, (s, t) => s + t.amount);
    final balance = income - expense;
    final positive = balance >= 0;

    final byCat = <String, double>{};
    for (final t in filtered.where((x) => x.isExpense)) {
      byCat[t.category] = (byCat[t.category] ?? 0) + t.amount;
    }

    final now = DateTime.now();
    final thisMonthExpense = <String, double>{};
    for (final t in data.financeTransactions.where((x) =>
        x.isExpense && DateTime.parse(x.date).year == now.year && DateTime.parse(x.date).month == now.month)) {
      thisMonthExpense[t.category] = (thisMonthExpense[t.category] ?? 0) + t.amount;
    }

    return Screenshot(
      controller: _screenshotCtrl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet, color: theme.primaryColor),
                      const SizedBox(width: 8),
                      Text('💰 ${s.financialBalance}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(icon: const Icon(Icons.screenshot, size: 20), onPressed: _takeScreenshot, tooltip: 'اسکرین‌شات'),
                      IconButton(
                        icon: const Icon(Icons.share, size: 20),
                        onPressed: () {
                          final buf = StringBuffer();
                          buf.writeln('گزارش مالی');
                          buf.writeln('درآمد: ${income.toStringAsFixed(0)}');
                          buf.writeln('هزینه: ${expense.toStringAsFixed(0)}');
                          buf.writeln('تراز: ${balance.toStringAsFixed(0)}');
                          _shareReport(buf.toString());
                        },
                        tooltip: 'اشتراک',
                      ),
                    ],
                  ),
                  const Divider(),
                  DropdownButton<String>(
                    value: _period,
                    isExpanded: true,
                    dropdownColor: AppColors.input,
                    items: [
                      DropdownMenuItem(value: 'today', child: Text(s.today)),
                      DropdownMenuItem(value: 'week', child: Text(s.thisWeek)),
                      DropdownMenuItem(value: 'month', child: Text(s.thisMonth)),
                      DropdownMenuItem(value: 'year', child: Text(s.thisYear)),
                      DropdownMenuItem(value: 'all', child: Text(s.all)),
                    ],
                    onChanged: (v) => setState(() => _period = v!),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _statBox(s.income, income, const Color(0xFF4CAF50))),
                      const SizedBox(width: 8),
                      Expanded(child: _statBox(s.expense, expense, const Color(0xFFF44336))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: positive ? const Color(0xFF4CAF50).withOpacity(0.2) : const Color(0xFFF44336).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(positive ? Icons.trending_up : Icons.trending_down, color: positive ? const Color(0xFF4CAF50) : const Color(0xFFF44336)),
                        const SizedBox(width: 8),
                        Text('${s.netBalance}: '),
                        Text(balance.abs().toStringAsFixed(0), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: positive ? const Color(0xFF4CAF50) : const Color(0xFFF44336))),
                        const Spacer(),
                        Text(positive ? s.positive : s.negative),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (income > 0 || expense > 0)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📊 ${s.income} vs ${s.expense}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (income > expense ? income : expense) * 1.2,
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) {
                                  if (v == 0) return Text(s.income, style: const TextStyle(fontSize: 11));
                                  if (v == 1) return Text(s.expense, style: const TextStyle(fontSize: 11));
                                  return const Text('');
                                },
                              ),
                            ),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: [
                            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: income, color: const Color(0xFF4CAF50), width: 50, borderRadius: BorderRadius.circular(6))]),
                            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: expense, color: const Color(0xFFF44336), width: 50, borderRadius: BorderRadius.circular(6))]),
                          ],
                        ),
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
                    const Text('🥧 سهم هزینه‌ها', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: byCat.entries.map((e) {
                            final cat = data.financeCategories.firstWhere(
                              (c) => c.name == e.key,
                              orElse: () => FinanceCategory(id: 0, name: e.key, type: 'expense', color: '#888888'),
                            );
                            final pct = expense > 0 ? (e.value / expense * 100) : 0;
                            return PieChartSectionData(
                              color: _hexToColor(cat.color),
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
                  Text('➕ ${s.add}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: ChoiceChip(label: Text(s.income), selected: _formType == 'income', onSelected: (_) => setState(() { _formType = 'income'; _formCategory = null; }), selectedColor: const Color(0xFF4CAF50))),
                      const SizedBox(width: 8),
                      Expanded(child: ChoiceChip(label: Text(s.expense), selected: _formType == 'expense', onSelected: (_) => setState(() { _formType = 'expense'; _formCategory = null; }), selectedColor: const Color(0xFFF44336))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _formCategory,
                          decoration: InputDecoration(labelText: s.category, filled: true, fillColor: AppColors.input),
                          dropdownColor: AppColors.input,
                          items: cats.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                          onChanged: (v) => setState(() => _formCategory = v),
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.add_circle, color: AppColors.primary), onPressed: _addCategory, tooltip: s.addCategory),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AppTextField(controller: _amountCtrl, label: s.amount, keyboardType: TextInputType.number, icon: Icons.attach_money),
                  const SizedBox(height: 8),
                  AppTextField(controller: _titleCtrl, label: s.transactionTitle, icon: Icons.title),
                  const SizedBox(height: 8),
                  AppTextField(controller: _noteCtrl, label: s.note, maxLines: 2),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(toJalaliDate(_formDate)),
                    onPressed: () async {
                      final d = await pickDate(context, _formDate);
                      if (d != null) setState(() => _formDate = d);
                    },
                  ),
                  const SizedBox(height: 8),
                  PrimaryButton(
                    label: s.add,
                    icon: Icons.check,
                    color: _formType == 'income' ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
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
                  Text('🎯 ${s.budget}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const Divider(),
                  ...data.financeCategories.where((c) => c.type == 'expense').map((c) {
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
                                c.monthlyBudget > 0 ? '${spent.toStringAsFixed(0)} / ${c.monthlyBudget.toStringAsFixed(0)}' : s.noBudget,
                                style: TextStyle(fontSize: 11, color: over ? const Color(0xFFF44336) : Colors.white70),
                              ),
                              IconButton(icon: const Icon(Icons.edit, size: 16, color: AppColors.warning), onPressed: () => _editBudget(c), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                            ],
                          ),
                          if (c.monthlyBudget > 0) ...[
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: pct.clamp(0.0, 1.0),
                              backgroundColor: Colors.white12,
                              color: over ? const Color(0xFFF44336) : (pct > 0.8 ? AppColors.warning : theme.primaryColor),
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
                  Text('📋 ${s.transactions}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (filtered.isEmpty)
                    Padding(padding: const EdgeInsets.all(20), child: Center(child: Text(s.noTransactions, style: const TextStyle(color: Colors.white54)))),
                  if (filtered.isNotEmpty)
                    ...filtered.reversed.take(30).map((t) => _txTile(t, s, theme)),
                ],
              ),
            ),
          ],
        ),
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
          Text(amount.toStringAsFixed(0), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _txTile(FinanceTransaction t, S s, ThemeProvider theme) {
    final color = t.isIncome ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.input, borderRadius: BorderRadius.circular(8), border: Border(right: BorderSide(color: color, width: 3))),
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
                    Text('${t.isIncome ? "+" : "-"}${t.amount.toStringAsFixed(0)}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                Text('${t.category} • ${toJalaliDate(DateTime.parse(t.date))}', style: const TextStyle(fontSize: 11, color: Colors.white60)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: AppColors.danger, size: 18),
            onPressed: () async {
              final data = context.read<DataProvider>();
              data.financeTransactions.removeWhere((x) => x.id == t.id);
              await data.saveFinanceTransactions();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}