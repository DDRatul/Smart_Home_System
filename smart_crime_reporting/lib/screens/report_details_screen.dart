import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/report.dart';
import '../services/report_service.dart';

class ReportDetailsScreen extends StatefulWidget {
  final CrimeReport report;
  final bool isAdmin;

  const ReportDetailsScreen({
    super.key,
    required this.report,
    required this.isAdmin,
  });

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  final _rs = ReportService();
  bool _updating = false;

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'under_review':
      case 'under review':
        return Colors.orange;
      case 'submitted':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _prettyStatus(String s) => s.replaceAll('_', ' ').trim();

  Future<void> _setStatus(String status) async {
    setState(() => _updating = true);
    try {
      await _rs.updateStatus(widget.report.id, status);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Status updated to: ${_prettyStatus(status)}")),
      );

      Navigator.pop(context); // same behavior as your original
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e")),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  void _openEvidenceViewer(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EvidenceViewer(
          urls: widget.report.evidenceUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _showAdminActions() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.22)),
              boxShadow: [
                BoxShadow(
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                  color: Colors.black.withOpacity(0.28),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.visibility_outlined, color: Colors.white),
                  title: const Text("Mark Under Review", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  subtitle: Text("Admin will investigate this report", style: TextStyle(color: Colors.white.withOpacity(0.75))),
                  onTap: _updating
                      ? null
                      : () {
                          Navigator.pop(context);
                          _setStatus('under_review');
                        },
                ),
                Divider(color: Colors.white.withOpacity(0.14), height: 10),
                ListTile(
                  leading: const Icon(Icons.verified_outlined, color: Colors.white),
                  title: const Text("Mark Resolved", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  subtitle: Text("Close the report as resolved", style: TextStyle(color: Colors.white.withOpacity(0.75))),
                  onTap: _updating
                      ? null
                      : () {
                          Navigator.pop(context);
                          _setStatus('resolved');
                        },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy-MM-dd HH:mm');
    final r = widget.report;
    final statusColor = _statusColor(r.status);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Report Details"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          if (widget.isAdmin)
            IconButton(
              tooltip: "Admin actions",
              onPressed: _updating ? null : _showAdminActions,
              icon: _updating
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.admin_panel_settings_outlined),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient (same as other screens)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF1D4ED8),
                  Color(0xFF9333EA),
                ],
              ),
            ),
          ),

          // Decorative bubbles
          const Positioned(top: -80, left: -60, child: _Bubble(size: 220, opacity: 0.16)),
          const Positioned(bottom: -90, right: -70, child: _Bubble(size: 260, opacity: 0.12)),
          const Positioned(top: 160, right: -40, child: _Bubble(size: 140, opacity: 0.10)),

          // Content
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => Future.delayed(const Duration(milliseconds: 350)),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                children: [
                  // Title card
                  _GlassCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.18)),
                          ),
                          child: const Icon(Icons.description_outlined, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.anonymous ? "[Anonymous] ${r.title}" : r.title,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _DarkChip(icon: Icons.category_outlined, label: r.category),
                                  _DarkChip(
                                    icon: Icons.circle,
                                    label: _prettyStatus(r.status),
                                    bg: statusColor.withOpacity(0.22),
                                    fg: statusColor,
                                  ),
                                  if (r.anonymous)
                                    const _DarkChip(icon: Icons.person_off_outlined, label: "Anonymous"),
                                  if (r.isPublic) const _DarkChip(icon: Icons.public, label: "Public"),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Info card
                  _GlassCard(
                    child: Column(
                      children: [
                        _DarkInfoRow(icon: Icons.place_outlined, title: "Location", value: r.locationText.isEmpty ? "Unknown" : r.locationText),
                        Divider(height: 18, color: Colors.white.withOpacity(0.16)),
                        _DarkInfoRow(icon: Icons.schedule_outlined, title: "Created", value: fmt.format(r.createdAt.toLocal())),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Description card
                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Description",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          r.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                height: 1.45,
                                color: Colors.white.withOpacity(0.85),
                              ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Evidence gallery
                  if (r.evidenceUrls.isNotEmpty)
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Evidence",
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              Text("(${r.evidenceUrls.length})", style: TextStyle(color: Colors.white.withOpacity(0.7))),
                              const Spacer(),
                              IconButton(
                                tooltip: "View all",
                                onPressed: () => _openEvidenceViewer(0),
                                icon: const Icon(Icons.open_in_full_outlined, color: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 130,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: r.evidenceUrls.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 10),
                              itemBuilder: (_, i) {
                                final url = r.evidenceUrls[i];
                                return GestureDetector(
                                  onTap: () => _openEvidenceViewer(i),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: AspectRatio(
                                      aspectRatio: 1.4,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.network(url, fit: BoxFit.cover),
                                          Positioned(
                                            right: 8,
                                            bottom: 8,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.55),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(Icons.zoom_in, color: Colors.white, size: 18),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Admin actions CTA
                  if (widget.isAdmin)
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Admin actions",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _updating ? null : () => _setStatus('under_review'),
                                  icon: const Icon(Icons.visibility_outlined, color: Colors.white),
                                  label: const Text("Under review", style: TextStyle(color: Colors.white)),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.white.withOpacity(0.35)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _updating ? null : () => _setStatus('resolved'),
                                  icon: const Icon(Icons.verified_outlined),
                                  label: const Text("Resolved"),
                                  style: FilledButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          if (_updating)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(color: Colors.black.withOpacity(0.06)),
              ),
            ),
        ],
      ),
      floatingActionButton: (!widget.isAdmin)
          ? null
          : FloatingActionButton.extended(
              onPressed: _updating ? null : _showAdminActions,
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: const Text("Actions"),
            ),
    );
  }
}

// ---------- Evidence fullscreen viewer ----------
class EvidenceViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const EvidenceViewer({
    super.key,
    required this.urls,
    required this.initialIndex,
  });

  @override
  State<EvidenceViewer> createState() => _EvidenceViewerState();
}

class _EvidenceViewerState extends State<EvidenceViewer> {
  late final PageController _pc;

  @override
  void initState() {
    super.initState();
    _pc = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF1D4ED8),
                  Color(0xFF9333EA),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                AppBar(
                  title: const Text("Evidence"),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  foregroundColor: Colors.white,
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pc,
                    itemCount: widget.urls.length,
                    itemBuilder: (_, i) {
                      return InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        child: Center(
                          child: Image.network(widget.urls[i], fit: BoxFit.contain),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Small UI helpers ----------
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            blurRadius: 28,
            offset: const Offset(0, 16),
            color: Colors.black.withOpacity(0.22),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _DarkChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? bg;
  final Color? fg;

  const _DarkChip({
    required this.icon,
    required this.label,
    this.bg,
    this.fg,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = bg ?? Colors.white.withOpacity(0.12);
    final fgColor = fg ?? Colors.white.withOpacity(0.85);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fgColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w800, color: fgColor),
          ),
        ],
      ),
    );
  }
}

class _DarkInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DarkInfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white.withOpacity(0.95)),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(color: Colors.white.withOpacity(0.78)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final double size;
  final double opacity;
  const _Bubble({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}