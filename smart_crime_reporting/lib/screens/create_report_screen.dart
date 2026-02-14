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

  final _formKey = GlobalKey<FormState>();

  String _category = 'theft';
  bool _anonymous = false;
  bool _isPublic = false;

  final List<File> _evidenceFiles = [];
  bool _loading = false;
  String? _err;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x != null) setState(() => _evidenceFiles.add(File(x.path)));
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _err = null;
    });

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

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _removeEvidenceAt(int index) {
    setState(() => _evidenceFiles.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Report'),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              children: [
                // Emergency notice (styled)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.primary.withOpacity(0.18)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: cs.primary),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'If you are in immediate danger, contact local emergency services.',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Title
                _NiceField(
                  controller: _title,
                  label: "Title",
                  hint: "Short summary (e.g., Phone stolen near SLC)",
                  icon: Icons.title,
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return "Title is required";
                    if (s.length < 5) return "Title is too short";
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // Category chips
                Text(
                  "Category",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _CatChip(
                      label: "Theft",
                      value: "theft",
                      selected: _category == "theft",
                      onTap: _loading ? null : () => setState(() => _category = "theft"),
                      icon: Icons.shopping_bag_outlined,
                    ),
                    _CatChip(
                      label: "Harassment",
                      value: "harassment",
                      selected: _category == "harassment",
                      onTap: _loading ? null : () => setState(() => _category = "harassment"),
                      icon: Icons.record_voice_over_outlined,
                    ),
                    _CatChip(
                      label: "Violence",
                      value: "violence",
                      selected: _category == "violence",
                      onTap: _loading ? null : () => setState(() => _category = "violence"),
                      icon: Icons.report_gmailerrorred_outlined,
                    ),
                    _CatChip(
                      label: "Suspicious",
                      value: "suspicious",
                      selected: _category == "suspicious",
                      onTap: _loading ? null : () => setState(() => _category = "suspicious"),
                      icon: Icons.visibility_outlined,
                    ),
                    _CatChip(
                      label: "Other",
                      value: "other",
                      selected: _category == "other",
                      onTap: _loading ? null : () => setState(() => _category = "other"),
                      icon: Icons.more_horiz,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Location
                _NiceField(
                  controller: _location,
                  label: "Location",
                  hint: "Text location (e.g., Waterloo, DC Library)",
                  icon: Icons.place_outlined,
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return "Location is required";
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // Description
                _NiceField(
                  controller: _desc,
                  label: "Description",
                  hint: "Write details (what happened, time, suspects, etc.)",
                  icon: Icons.notes_outlined,
                  maxLines: 6,
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return "Description is required";
                    if (s.length < 15) return "Please add more details";
                    return null;
                  },
                ),

                const SizedBox(height: 6),

                // Switches in cards
                _SwitchCard(
                  title: "Submit anonymously",
                  subtitle: "Your identity will not be shown to others.",
                  value: _anonymous,
                  onChanged: _loading ? null : (v) => setState(() => _anonymous = v),
                  icon: Icons.person_off_outlined,
                ),
                _SwitchCard(
                  title: "Make report public",
                  subtitle: "Others can read this report (good for community safety).",
                  value: _isPublic,
                  onChanged: _loading ? null : (v) => setState(() => _isPublic = v),
                  icon: Icons.public_outlined,
                ),

                const SizedBox(height: 12),

                // Evidence section
                Row(
                  children: [
                    Text(
                      "Evidence",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _loading ? null : _pickImage,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: const Text("Add"),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (_evidenceFiles.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.image_outlined, color: cs.onSurfaceVariant),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "No evidence added yet. Add photos if you have any.",
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _evidenceFiles.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemBuilder: (_, i) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_evidenceFiles[i], fit: BoxFit.cover),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: InkWell(
                                onTap: _loading ? null : () => _removeEvidenceAt(i),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 12),

                if (_err != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.withOpacity(0.35)),
                    ),
                    child: Text(
                      _err!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom submit bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 18,
                      offset: const Offset(0, -8),
                      color: Colors.black.withOpacity(0.10),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _submit,
                    icon: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined),
                    label: Text(_loading ? "Submitting..." : "Submit report"),
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_loading)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black.withOpacity(0.06),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NiceField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final String? Function(String?)? validator;

  const _NiceField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final IconData icon;

  const _SwitchCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        secondary: Icon(icon, color: cs.primary),
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback? onTap;
  final IconData icon;

  const _CatChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      onSelected: onTap == null ? null : (_) => onTap!(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}