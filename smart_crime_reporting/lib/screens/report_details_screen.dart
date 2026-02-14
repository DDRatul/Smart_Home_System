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

  String _prettyStatus(String s) {
    return s.replaceAll('_', ' ').trim();
  }

  Future<void> _setStatus(String status) async {
    setState(() => _updating = true);
    try {
      await _rs.updateStatus(widget.report.id, status);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Status updated to: ${_prettyStatus(status)}")),
      );

      Navigator.pop(context); // back to list (same behavior as your original)
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
    final urls = widget.report.evidenceUrls;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EvidenceViewer(
          urls: urls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _showAdminActions() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.visibility_outlined),
                  title: const Text("Mark Under Review"),
                  subtitle: const Text("Admin will investigate this report"),
                  onTap: _updating ? null : () => _setStatus('under_review'),
                ),
                ListTile(
                  leading: const Icon(Icons.verified_outlined),
                  title: const Text("Mark Resolved"),
                  subtitle: const Text("Close the report as resolved"),
                  onTap: _updating ? null : () => _setStatus('resolved'),
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
      appBar: AppBar(
        title: const Text("Report Details"),
        actions: [
          if (widget.isAdmin)
            IconButton(
              tooltip: "Admin actions",
              onPressed: _updating ? null : _showAdminActions,
              icon: _updating
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.admin_panel_settings_outlined),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // If you later add "fetch report by id", you can refresh data here.
          await Future.delayed(const Duration(milliseconds: 350));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title card
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.description_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.anonymous ? "[Anonymous] ${r.title}" : r.title,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _Chip(
                                  icon: Icons.category_outlined,
                                  label: r.category,
                                ),
                                _Chip(
                                  icon: Icons.circle,
                                  label: _prettyStatus(r.status),
                                  color: statusColor.withOpacity(0.12),
                                  iconColor: statusColor,
                                  textColor: statusColor,
                                ),
                                if (r.anonymous)
                                  const _Chip(
                                    icon: Icons.person_off_outlined,
                                    label: "Anonymous",
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Info card
            _Card(
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.place_outlined,
                    title: "Location",
                    value: r.locationText,
                  ),
                  const Divider(height: 18),
                  _InfoRow(
                    icon: Icons.schedule_outlined,
                    title: "Created",
                    value: fmt.format(r.createdAt.toLocal()),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Description card
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Description",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    r.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Evidence gallery
            if (r.evidenceUrls.isNotEmpty)
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Evidence",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "(${r.evidenceUrls.length})",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: "View all",
                          onPressed: () => _openEvidenceViewer(0),
                          icon: const Icon(Icons.open_in_full_outlined),
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

            // Admin actions (nice CTA at bottom too)
            if (widget.isAdmin)
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Admin actions",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _updating ? null : () => _setStatus('under_review'),
                            icon: const Icon(Icons.visibility_outlined),
                            label: const Text("Under review"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _updating ? null : () => _setStatus('resolved'),
                            icon: const Icon(Icons.verified_outlined),
                            label: const Text("Resolved"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
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
      appBar: AppBar(title: const Text("Evidence")),
      body: PageView.builder(
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
    );
  }
}

// ---------- Small UI helpers ----------
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final Color? iconColor;
  final Color? textColor;

  const _Chip({
    required this.icon,
    required this.label,
    this.color,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor ?? onSurface.withOpacity(0.75)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: textColor ?? onSurface.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: cs.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: cs.onSurface)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(color: cs.onSurfaceVariant)),
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
