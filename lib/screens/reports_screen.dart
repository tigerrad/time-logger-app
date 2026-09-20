import 'package:flutter/material.dart';
import '../models/time_entry.dart';
import '../services/jalali.dart';
import '../widgets/common.dart';

class ReportsScreen extends StatefulWidget {
  final List<TimeEntry> entries;

  const ReportsScreen({super.key, required this.entries});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _range = 'کل';
  final _ranges = ['امروز', 'این هفته', 'این ماه', 'امسال', 'کل'];

  List<TimeEntry> _filtered() {
    final now = DateTime.now();
    return widget.entries.where((e) {
      final dt = DateTime.parse(e.start);
      switch (_range) {
        case 'امروز':
          return dt.year == now.year && dt.month == now.month && dt.day == now.day;
        case 'این هفته':
          final start = now.subtract(Duration(days: now.weekday - 1));
          final startOfDay = DateTime(start.year, start.month, start.day);
          return dt.isAfter(startOfDay) || dt.isAtSameMomentAs(startOfDay);
        case 'این ماه':
          return dt.year == now.year && dt.month == now.month;
        case 'امسال':
          return dt.year == now.year;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered();
    final totalMin = filtered.fold<int>(0, (s, e) => s + e.minutes);
    final byDomain = <String, int>{};
    for (final e in filtered) {
      byDomain[e.domain] = (byDomain[e.domain] ?? 0) + e.minutes;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Row(
              children: [
                const Text('بازه:', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _range,
                    isExpanded: true,
                    dropdownColor: AppColors.input,
                    items: _ranges.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (v) => setState(() => _range = v!),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📊 گزارش ساعتی', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Divider(),
                Text('تعداد ورودی: ${filtered.length}', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                if (byDomain.isEmpty)
                  const Text('داده‌ای نیست', style: TextStyle(color: Colors.white54))
                else
                  ...byDomain.entries.map((e) {
                    final hours = (e.value / 60).toStringAsFixed(2);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('${e.key}: ${e.value} دقیقه ($hours ساعت)'),
                    );
                  }),
                const Divider(),
                Text(
                  'مجموع: $totalMin دقیقه (${(totalMin / 60).toStringAsFixed(2)} ساعت)',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📈 گزارش درصدی', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Divider(),
                if (byDomain.isEmpty)
                  const Text('داده‌ای نیست', style: TextStyle(color: Colors.white54))
                else
                  ...byDomain.entries.map((e) {
                    final pct = totalMin > 0 ? (e.value / totalMin * 100) : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${e.key}: ${pct.toStringAsFixed(1)}%'),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: pct / 100,
                            backgroundColor: Colors.white12,
                            color: AppColors.primary,
                            minHeight: 6,
                          ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🕐 آخرین ورودی‌ها', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Divider(),
                if (filtered.isEmpty)
                  const Text('داده‌ای نیست', style: TextStyle(color: Colors.white54))
                else
                  ...filtered.reversed.take(10).map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '${toJalaliDateTime(DateTime.parse(e.start))} — ${e.domain} (${e.minutes}د)',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}