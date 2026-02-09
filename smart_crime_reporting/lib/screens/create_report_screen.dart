import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/report.dart';
import '../services/report_service.dart';
import '../services/storage_service.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _reportService = ReportService();
  final _storage = StorageService();
  final _picker = ImagePicker();

  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _location = TextEditingController();

  String _category = 'theft';
  bool _anonymous = false;
  bool _isPublic = false;

  final List<File> _evidenceFiles = [];
  bool _loading = false;
  String? _err;

  Future<void> _pickImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x != null) setState(() => _evidenceFiles.add(File(x.path)));
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _err = null; });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final id = const Uuid().v4();

      final urls = <String>[];
      for (int i = 0; i < _evidenceFiles.length; i++) {
        final file = _evidenceFiles[i];
        final url = await _storage.uploadEvidence(
          userId: user.uid,
          fileName: '${id}_$i.jpg',
          file: file,
        );
        urls.add(url);
      }

      final report = CrimeReport(
        id: id,
        userId: user.uid,
        title: _title.text.trim(),
        description: _desc.text.trim(),
        category: _category,
        locationText: _location.text.trim(),
        anonymous: _anonymous,
        isPublic: _isPublic,
        status: 'submitted',
        evidenceUrls: urls,
        createdAt: DateTime.now(),
      );

      await _reportService.createReport(report);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Report')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'If you are in immediate danger, contact local emergency services.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _category,
              items: const [
                DropdownMenuItem(value: 'theft', child: Text('Theft')),
                DropdownMenuItem(value: 'harassment', child: Text('Harassment')),
                DropdownMenuItem(value: 'violence', child: Text('Violence')),
                DropdownMenuItem(value: 'suspicious', child: Text('Suspicious Activity')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (v) => setState(() => _category = v ?? 'other'),
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _location,
              decoration: const InputDecoration(labelText: 'Location (text)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _desc,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 10),

            SwitchListTile(
              title: const Text('Submit anonymously'),
              value: _anonymous,
              onChanged: (v) => setState(() => _anonymous = v),
            ),
            SwitchListTile(
              title: const Text('Make report public (others can read)'),
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
            ),

            const SizedBox(height: 10),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _loading ? null : _pickImage,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Add evidence'),
                ),
                const SizedBox(width: 12),
                Text('${_evidenceFiles.length} file(s)'),
              ],
            ),

            const SizedBox(height: 12),
            if (_err != null) Text(_err!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Submit report'),
            ),
          ],
        ),
      ),
    );
  }
}
