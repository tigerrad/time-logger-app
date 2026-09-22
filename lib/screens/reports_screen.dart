// ignore_for_file: prefer_const_constructors
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
import '../services/jalali.dart';
import '../widgets/common.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _range = 'all';
  final ScreenshotController _screenshotCtrl = ScreenshotController();

  List<MapEntry<String, int>> _byDomain(List entries) {
    final map = <String, int>{};
    for (final e in entries) {
      map[e.domain] = (map[e.domain] ?? 0) + (e.minutes as int);
    }
    final list = map.entries.toList();
    list.sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  Future<void> _shareReport(String text) async {
    try {
      final dir = Directory.systemTemp;
      final file = File('${dir.path}/report_${DateTime.now().millisecondsSinceEpoch}.txt');
      await file.writeAsString(text);
      await Share.shareXFiles([XFile(file.path)], text: 'گزارش تایم لاگر');
    } catch (_) {}
  }

  Future<void> _takeScreenshot() async {
    final s = S(context.read<LanguageProvider>().lang);
    try {
      final bytes = await _screenshotCtrl.capture();
      if (bytes == null) return;
      final dir = Directory.systemTemp;
      final file = File('${dir.path}/report_shot_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'اسکرین‌شات گزارش');
    } catch (_) {
      if (!mounted) return;
      showSnack(context, s.errorOccurred, color: AppColors.danger);
    }
  }

  Color _colorFor(int index) {
    const colors = [
      Color(0xFF00DCA0), Color(0xFF2196F3), Color(0xFFFF9800),
      Color(0xFFE91E63), Color(0xFF9C27B0), Color(0xFF4CAF50),
      Color(0xFFFFC107), Color(0xFF03A9F4), Color(0xFF795548), Color(0xFF607D8B),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final theme = context.watch<ThemeProvider>();
    final s = S(context.watch<LanguageProvider>().lang);
    final now = DateTime.now();

    final filtered = data.entries.where((e) {
      final dt = DateTime.parse(e.start);
      switch (_range) {
        case 'today':
          return dt.year == now.year && dt.month == now.month && dt.day == now.day;
        case 'week':
          final start = now.subtract(Duration(days: now.weekday - 1));
          final s0 = DateTime(start.year, start.month, start.day);
          return dt.isAfter(s0) || dt.isAtSameMomentAs(s0);
        case 'month':
          return dt.year == now.year && dt.month == now.month;
        case 'year':
          return dt.year == now.year;
        default:
          return true;
      }
    }).toList();

    final totalMin = filtered.fold<int>(0, (s0, e) => s0 + e.minutes);
    final byDomain = _byDomain(filtered);

    return Screenshot(
      controller: _screenshotCtrl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Row(
                children: [
                  Icon(Icons.bar_chart, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _range,
                      isExpanded: true,
                      dropdownColor: AppColors.input,
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(value: 'today', child: Text(s.today)),
                        DropdownMenuItem(value: 'week', child: Text(s.thisWeek)),
                        DropdownMenuItem(value: 'month', child: Text(s.thisMonth)),
                        DropdownMenuItem(value: 'year', child: Text(s.thisYear)),
                        DropdownMenuItem(value: 'all', child: Text(s.all)),
                      ],
                      onChanged: (v) => setState(() => _range = v!),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.screenshot, size: 20), onPressed: _takeScreenshot, tooltip: s.screenshot),
                  IconButton(
                    icon: const Icon(Icons.share, size: 20),
                    onPressed: () {
                      final buf = StringBuffer();
                      buf.writeln('گزارش تایم لاگر');
                      buf.writeln('تاریخ: ${toJalaliDateTime(DateTime.now())}');
                      buf.writeln('─' * 30);
                      buf.writeln('تعداد ورودی: ${filtered.length}');
                      buf.writeln('مجموع: $totalMin دقیقه (${(totalMin / 60).toStringAsFixed(2)} ساعت)');
                      buf.writeln('');
                      for (final e in byDomain) {
                        buf.writeln('${e.key}: ${e.value} دقیقه');
                      }
                      _shareReport(buf.toString());
                    },
                    tooltip: s.share,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📊 ${s.hourlyReport}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  Text('${s.entriesCount}: ${filtered.length}'),
                  const SizedBox(height: 8),
                  if (byDomain.isEmpty)
                    Text(s.noData, style: const TextStyle(color: Colors.white54))
                  else
                    ...byDomain.map((e) {
                      final hours = (e.value / 60).toStringAsFixed(2);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('${e.key}: ${e.value} ${s.minute} ($hours ${s.hour})'),
                      );
                    }),
                  const Divider(),
                  Text(
                    '${s.total}: $totalMin ${s.minute} (${(totalMin / 60).toStringAsFixed(2)} ${s.hour})',
                    style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (byDomain.isNotEmpty)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🥧 سهم هر حوزه', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: byDomain.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final e = entry.value;
                            final pct = totalMin > 0 ? (e.value / totalMin * 100) : 0.0;
                            return PieChartSectionData(
                              color: _colorFor(idx),
                              value: e.value.toDouble(),
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
                      children: byDomain.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final e = entry.value;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 10, height: 10, decoration: BoxDecoration(color: _colorFor(idx), shape: BoxShape.circle)),
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
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📈 ${s.percentReport}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  if (byDomain.isEmpty)
                    Text(s.noData, style: const TextStyle(color: Colors.white54))
                  else
                    ...byDomain.map((e) {
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
                              color: theme.primaryColor,
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
                  Text('🕐 ${s.latestEntries}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  if (filtered.isEmpty)
                    Text(s.noData, style: const TextStyle(color: Colors.white54))
                  else
                    ...filtered.reversed.take(10).map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '${toJalaliDateTime(DateTime.parse(e.start))} — ${e.domain} (${e.minutes}${s.minute})',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}