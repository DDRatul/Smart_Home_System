import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/report_service.dart';
import '../models/report.dart';
import 'create_report_screen.dart';
import 'report_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = AuthService();
  final _reports = ReportService();

  // Simple admin list
  final Set<String> adminEmails = {'admin@youruni.edu'};

  bool get isAdmin {
    final email = FirebaseAuth.instance.currentUser?.email?.toLowerCase();
    return email != null && adminEmails.contains(email);
  }

  bool _showPublic = false;

  Stream<List<CrimeReport>> _currentStream() {
    final user = FirebaseAuth.instance.currentUser!;
    if (isAdmin) return _reports.watchAllReportsAdmin();
    return _showPublic ? _reports.watchPublicReports() : _reports.watchMyReports(user.uid);
  }

  String _screenTitle() {
    if (isAdmin) return "All Reports (Admin)";
    return _showPublic ? "Public Reports" : "My Reports";
  }

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

  IconData _catIcon(String c) {
    switch (c.toLowerCase()) {
      case 'theft':
        return Icons.shopping_bag_outlined;
      case 'harassment':
        return Icons.record_voice_over_outlined;
      case 'violence':
        return Icons.report_gmailerrorred_outlined;
      case 'suspicious':
        return Icons.visibility_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_screenTitle(), style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          if (!isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text("Mine"), icon: Icon(Icons.person_outline)),
                  ButtonSegment(value: true, label: Text("Public"), icon: Icon(Icons.public)),
                ],
                selected: {_showPublic},
                onSelectionChanged: (s) => setState(() => _showPublic = s.first),
              ),
            ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _auth.logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateReportScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Report'),
      ),

      body: StreamBuilder<List<CrimeReport>>(
        stream: _currentStream(),
        builder: (context, snap) {
          // ✅ 1) Error handling (prevents infinite spinner)
          if (snap.hasError) {
            return _ErrorState(
              message: snap.error.toString(),
              hint:
                  "If the error says 'index required', open Firebase Console → Firestore → Indexes and create the suggested index.",
              onRetry: () => setState(() {}),
            );
          }

          // ✅ 2) Loading state
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ✅ 3) Empty / Data
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return _EmptyState(
              title: _showPublic ? "No public reports yet" : "No reports yet",
              subtitle: _showPublic
                  ? "When users submit public reports, they’ll appear here."
                  : "Tap “New Report” to submit your first report.",
              icon: _showPublic ? Icons.public_off_outlined : Icons.description_outlined,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Stream refresh is automatic; this just gives a nice UX.
              setState(() {});
              await Future.delayed(const Duration(milliseconds: 300));
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final r = items[i];
                final title = r.anonymous ? '[Anonymous] ${r.title}' : r.title;
                final statusColor = _statusColor(r.status);

                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ReportDetailsScreen(report: r, isAdmin: isAdmin)),
                  ),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                height: 42,
                                width: 42,
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(_catIcon(r.category), color: cs.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  title,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (r.evidenceUrls.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.attachment, color: cs.onSurfaceVariant),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _Chip(
                                icon: Icons.category_outlined,
                                text: r.category,
                              ),
                              _Chip(
                                icon: Icons.circle,
                                text: r.status.replaceAll('_', ' '),
                                bg: statusColor.withOpacity(0.12),
                                fg: statusColor,
                              ),
                              _Chip(
                                icon: Icons.place_outlined,
                                text: r.locationText.isEmpty ? "Unknown location" : r.locationText,
                              ),
                              if (r.anonymous) const _Chip(icon: Icons.person_off_outlined, text: "Anonymous"),
                              if (r.isPublic) const _Chip(icon: Icons.public, text: "Public"),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ---------- Small UI helpers ----------
class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? bg;
  final Color? fg;

  const _Chip({
    required this.icon,
    required this.text,
    this.bg,
    this.fg,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg ?? cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg ?? cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontWeight: FontWeight.w700, color: fg ?? cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, size: 38, color: cs.primary),
            ),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final String hint;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.hint,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 42),
              const SizedBox(height: 10),
              const Text("Something went wrong", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(hint, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}