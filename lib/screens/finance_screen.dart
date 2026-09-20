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
  String _period = 'این ماه';
  final _periods = ['امروز', 'این هفته', 'این ماه', 'امسال', 'کل'];

  // فیلدهای فرم
  final _amountCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
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

  List<FinanceTransaction> _filtered() {
    final now = DateTime.now();
    return widget.transactions.where((t) {
      final dt = DateTime.parse(t.date);
      switch (_period) {
        case 'امروز':
          return dt.year == now.year && dt.month == now.month && dt.day == now.day;
        case 'این هفته':
          final start = now.subtract(Duration(days: now.weekday - 1));
          final s = DateTime(start.year, start.month, start.day);
          return dt.isAfter(s) || dt.isAtSameMomentAs(s);
        case 'این ماه':
          return dt.year == now.year && dt.month == now.month;
        case 'امسال':
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
      showSnack(context, 'مبلغ، دسته و عنوان را وارد کنید', color: AppColors.danger);
      return;
    }
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) {
      showSnack(context, 'مبلغ معتبر وارد کنید', color: AppColors.danger);
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
    showSnack(
      context,
      'ثبت شد: ${_formType == 'income' ? 'درآمد' : 'هزینه'} ${amount.toStringAsFixed(0)} تومان',
      color: AppColors.primary,
    );
  }

  Future<void> _delete(FinanceTransaction t) async {
    final ok = await confirmDialog(context, title: 'حذف تراکنش', message: '«${t.title}» حذف شود؟');
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
        title: Text('بودجه ماهانه: ${c.name}', style: const TextStyle(color: Colors.white, fontSize: 14)),
        content: TextField(
          controller: _budgetCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'مبلغ بودجه (تومان)',
            filled: true,
            fillColor: AppColors.input,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو', style: TextStyle(color: Colors.white70))),
          TextButton(
            onPressed: () => Navigator.pop(context, double.tryParse(_budgetCtrl.text)),
            child: const Text('ذخیره', style: TextStyle(color: AppColors.primary)),
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

  Future<void> _addCategory() async {
    final nameCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    String newType = _formType;
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('افزودن دسته جدید', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'نام دسته', filled: true, fillColor: AppColors.input),
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: newType,
                isExpanded: true,
                dropdownColor: AppColors.input,
                items: const [
                  DropdownMenuItem(value: 'income', child: Text('درآمد')),
                  DropdownMenuItem(value: 'expense', child: Text('هزینه')),
                ],
                onChanged: (v) => setDlg(() => newType = v!),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: budgetCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'بودجه ماهانه (اختیاری)', filled: true, fillColor: AppColors.input),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('لغو', style: TextStyle(color: Colors.white70))),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ذخیره', style: TextStyle(color: AppColors.primary))),
          ],
        ),
      ),
    );
    if (res == true && nameCtrl.text.isNotEmpty) {
      final newId = widget.categories.isEmpty
          ? 1
          : (widget.categories.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
      widget.categories.add(FinanceCategory(
        id: newId,
        name: nameCtrl.text,
        type: newType,
        color: '#FF9800',
        monthlyBudget: double.tryParse(budgetCtrl.text) ?? 0,
      ));
      await widget.onChanged();
      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> _exportReport() async {
    final list = _filtered();
    final income = _sumIncome(list);
    final expense = _sumExpense(list);
    final balance = income - expense;

    final buf = StringBuffer();
    buf.writeln('گزارش مالی — ${_period}');
    buf.writeln('تاریخ: ${toJalaliDateTime(DateTime.now())}');
    buf.writeln('─' * 30);
    buf.writeln('جمع درآمد: ${income.toStringAsFixed(0)} تومان');
    buf.writeln('جمع هزینه: ${expense.toStringAsFixed(0)} تومان');
    buf.writeln('تراز: ${balance.toStringAsFixed(0)} تومان (${balance >= 0 ? "مثبت" : "منفی"})');
    buf.writeln('');
    buf.writeln('تراکنش‌ها:');
    for (final t in list) {
      buf.writeln('${t.isIncome ? "➕" : "➖"} ${toJalaliDate(DateTime.parse(t.date))} | ${t.category} | ${t.title} | ${t.amount.toStringAsFixed(0)}');
    }

    try {
      final dir = Directory.systemTemp;
      final file = File('${dir.path}/finance_report_${DateTime.now().millisecondsSinceEpoch}.txt');
      await file.writeAsString(buf.toString());
      await Share.shareXFiles([XFile(file.path)], text: 'گزارش مالی');
    } catch (e) {
      if (!mounted) return;
      showSnack(context, 'خطا در اشتراک‌گذاری', color: AppColors.danger);
    }
  }

  Future<void> _pickFormDate() async {
    final d = await pickDate(context, _formDate);
    if (d == null) return;
    if (!mounted) return;
    setState(() => _formDate = d);
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered();
    final income = _sumIncome(list);
    final expense = _sumExpense(list);
    final balance = income - expense;
    final isPositive = balance >= 0;

    // محاسبه هزینه هر دسته
    final byCat = <String, double>{};
    for (final t in list.where((x) => x.isExpense)) {
      byCat[t.category] = (byCat[t.category] ?? 0) + t.amount;
    }

    // بودجه: هزینه این ماه هر دسته
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
          // ==== کارت تراز ====
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text('💰 تراز مالی', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                    Expanded(child: _statBox('درآمد', income, const Color(0xFF4CAF50))),
                    const SizedBox(width: 8),
                    Expanded(child: _statBox('هزینه', expense, const Color(0xFFF44336))),
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
                      Text('تراز: ', style: const TextStyle(fontSize: 14)),
                      Text(
                        '${balance.abs().toStringAsFixed(0)} تومان',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isPositive ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                        ),
                      ),
                      const Spacer(),
                      Text(isPositive ? 'مثبت ✓' : 'منفی ✗', style: TextStyle(color: isPositive ? const Color(0xFF4CAF50) : const Color(0xFFF44336))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ==== نمودار میله‌ای درآمد/هزینه ====
          if (income > 0 || expense > 0)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📊 درآمد vs هزینه', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
                                if (v == 0) return const Text('درآمد', style: TextStyle(fontSize: 11));
                                if (v == 1) return const Text('هزینه', style: TextStyle(fontSize: 11));
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          BarChartGroupData(x: 0, barRods: [
                            BarChartRodData(toY: income, color: const Color(0xFF4CAF50), width: 50, borderRadius: BorderRadius.circular(6)),
                          ]),
                          BarChartGroupData(x: 1, barRods: [
                            BarChartRodData(toY: expense, color: const Color(0xFFF44336), width: 50, borderRadius: BorderRadius.circular(6)),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // ==== نمودار دایره‌ای هزینه‌ها ====
          if (byCat.isNotEmpty)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🥧 سهم هر دسته از هزینه', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: byCat.entries.map((e) {
                      final cat = widget.categories.firstWhere(
                        (c) => c.name == e.key,
                        orElse: () => FinanceCategory(id: 0, name: e.key, type: 'expense', color: '#888888'),
                      );
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 10, height: 10, decoration: BoxDecoration(color: _hexToColor(cat.color), shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text(e.key, style: const TextStyle(fontSize: 11)),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // ==== فرم ثبت تراکنش ====
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('➕ ثبت تراکنش جدید', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('درآمد'),
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
                        label: const Text('هزینه'),
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
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _formCategory,
                        decoration: const InputDecoration(
                          labelText: 'دسته‌بندی',
                          filled: true,
                          fillColor: AppColors.input,
                        ),
                        dropdownColor: AppColors.input,
                        items: _catsFor(_formType).map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                        onChanged: (v) => setState(() => _formCategory = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.primary),
                      onPressed: _addCategory,
                      tooltip: 'افزودن دسته جدید',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppTextField(controller: _amountCtrl, label: 'مبلغ (تومان)', keyboardType: TextInputType.number, icon: Icons.attach_money),
                const SizedBox(height: 8),
                AppTextField(controller: _titleCtrl, label: 'عنوان / توضیح کوتاه', icon: Icons.title),
                const SizedBox(height: 8),
                AppTextField(controller: _noteCtrl, label: 'یادداشت (اختیاری)', maxLines: 2),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(toJalaliDate(_formDate)),
                        onPressed: _pickFormDate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'ثبت',
                  icon: Icons.check,
                  color: _formType == 'income' ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                  onPressed: _addTransaction,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ==== بودجه ماهانه ====
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('🎯 بودجه ماهانه دسته‌ها', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const Divider(),
                if (_catsFor('expense').isEmpty)
                  const Text('دسته‌ای وجود ندارد', style: TextStyle(color: Colors.white54))
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
                                c.monthlyBudget > 0
                                    ? '${spent.toStringAsFixed(0)} / ${c.monthlyBudget.toStringAsFixed(0)}'
                                    : 'بدون بودجه',
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
                              color: over ? const Color(0xFFF44336) : (pct > 0.8 ? AppColors.warning : AppColors.primary),
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

          // ==== لیست تراکنش‌ها ====
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text('📋 تراکنش‌ها', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('${list.length} مورد', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.share, color: AppColors.secondary, size: 20),
                      onPressed: _exportReport,
                      tooltip: 'اشتراک‌گذاری گزارش',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('تراکنشی در این بازه نیست', style: TextStyle(color: Colors.white54))),
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
          Text(
            amount.toStringAsFixed(0),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const Text('تومان', style: TextStyle(fontSize: 10, color: Colors.white54)),
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
                Text('${t.category} • ${toJalaliDate(DateTime.parse(t.date))}', style: const TextStyle(fontSize: 11, color: Colors.white60)),
                if (t.note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('📝 ${t.note}', style: const TextStyle(fontSize: 11, color: Colors.white54)),
                  ),
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