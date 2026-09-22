// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/data_provider.dart';
import '../providers/language_provider.dart';
import '../l10n/strings.dart';
import '../models/publication.dart';
import '../services/jalali.dart';
import '../widgets/common.dart';

class PublicationsScreen extends StatefulWidget {
  const PublicationsScreen({super.key});

  @override
  State<PublicationsScreen> createState() => _PublicationsScreenState();
}

class _PublicationsScreenState extends State<PublicationsScreen> {
  final _searchCtrl = TextEditingController();
  String _search = ''; // ignore: prefer_final_fields

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final s = S(context.read<LanguageProvider>().lang);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'xlsx', 'xls'],
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final ext = (file.extension ?? '').toLowerCase();

      final data = context.read<DataProvider>();
      final newId = data.publications.isEmpty ? 1 : (data.publications.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
      data.publications.add(Publication(
        id: newId,
        title: file.name,
        filePath: file.path ?? '',
        fileType: ext,
        date: DateTime.now().toIso8601String(),
      ));
      await data.savePublications();
      if (!mounted) return;
      showSnack(context, s.saved, color: AppColors.primary);
    } catch (e) {
      if (!mounted) return;
      showSnack(context, s.errorOccurred, color: AppColors.danger);
    }
  }

  Future<void> _delete(Publication p) async {
    final ok = await confirmDialog(context, title: 'حذف');
    if (!ok) return;
    final data = context.read<DataProvider>();
    data.publications.removeWhere((x) => x.id == p.id);
    await data.savePublications();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final s = S(context.watch<LanguageProvider>().lang);

    final filtered = data.publications.where((p) => p.title.toLowerCase().contains(_search.toLowerCase())).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('📚 ${s.addPublication}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(s.supportedFormats, style: const TextStyle(fontSize: 12, color: Colors.white60)),
                const SizedBox(height: 12),
                PrimaryButton(label: s.uploadFile, icon: Icons.upload_file, color: AppColors.secondary, onPressed: _pickFile),
                const SizedBox(height: 12),
                AppTextField(controller: _searchCtrl, label: s.searchPublications, icon: Icons.search),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('📋 ${s.publicationsList}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (filtered.isEmpty)
                  Padding(padding: const EdgeInsets.all(20), child: Center(child: Text(s.noPublications, style: const TextStyle(color: Colors.white54)))),
                if (filtered.isNotEmpty)
                  ...filtered.map((p) => _pubTile(p, s)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pubTile(Publication p, S s) {
    IconData icon;
    Color color;
    if (p.fileType == 'pdf') {
      icon = Icons.picture_as_pdf;
      color = Colors.red;
    } else if (p.fileType == 'txt') {
      icon = Icons.text_snippet;
      color = Colors.blue;
    } else if (p.fileType == 'xlsx' || p.fileType == 'xls') {
      icon = Icons.table_chart;
      color = Colors.green;
    } else {
      icon = Icons.insert_drive_file;
      color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.input, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${p.fileType.toUpperCase()} • ${toJalaliDate(DateTime.parse(p.date))}', style: const TextStyle(fontSize: 11, color: Colors.white60)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.delete, color: AppColors.danger, size: 20), onPressed: () => _delete(p), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ],
      ),
    );
  }
}