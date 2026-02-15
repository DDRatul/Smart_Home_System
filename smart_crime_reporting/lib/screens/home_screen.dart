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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _screenTitle(),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          if (!isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Theme(
                // Make segmented button readable on dark background
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                        onSurface: Colors.white,
                        onSurfaceVariant: Colors.white70,
                        surface: Colors.white.withOpacity(0.12),
                        outline: Colors.white.withOpacity(0.25),
                      ),
                ),
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text("Mine"), icon: Icon(Icons.person_outline)),
                    ButtonSegment(value: true, label: Text("Public"), icon: Icon(Icons.public)),
                  ],
                  selected: {_showPublic},
                  onSelectionChanged: (s) => setState(() => _showPublic = s.first),
                ),
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

      body: Stack(
        children: [
          // ✅ Background gradient (same as other screens)
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

          // ✅ Decorative bubbles
          const Positioned(top: -80, left: -60, child: _Bubble(size: 220, opacity: 0.16)),
          const Positioned(bottom: -90, right: -70, child: _Bubble(size: 260, opacity: 0.12)),
          const Positioned(top: 160, right: -40, child: _Bubble(size: 140, opacity: 0.10)),

          // ✅ Content
          SafeArea(
            child: StreamBuilder<List<CrimeReport>>(
              stream: _currentStream(),
              builder: (context, snap) {
                // Error handling
                if (snap.hasError) {
                  return _ErrorState(
                    message: snap.error.toString(),
                    hint:
                        "If the error says 'index required', open Firebase Console → Firestore → Indexes and create the suggested index.",
                    onRetry: () => setState(() {}),
                  );
                }

                // Loading
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }

                // Empty / Data
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
                    setState(() {});
                    await Future.delayed(const Duration(milliseconds: 300));
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final r = items[i];
                      final title = r.anonymous ? '[Anonymous] ${r.title}' : r.title;
                      final statusColor = _statusColor(r.status);

                      return InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportDetailsScreen(report: r, isAdmin: isAdmin),
                          ),
                        ),
                        child: _GlassCard(
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
                                        color: Colors.white.withOpacity(0.14),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: Colors.white.withOpacity(0.18)),
                                      ),
                                      child: Icon(_catIcon(r.category), color: Colors.white),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (r.evidenceUrls.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Icon(Icons.attachment, color: Colors.white.withOpacity(0.85)),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _DarkChip(
                                      icon: Icons.category_outlined,
                                      text: r.category,
                                    ),
                                    _DarkChip(
                                      icon: Icons.circle,
                                      text: r.status.replaceAll('_', ' '),
                                      bg: statusColor.withOpacity(0.22),
                                      fg: statusColor,
                                    ),
                                    _DarkChip(
                                      icon: Icons.place_outlined,
                                      text: r.locationText.isEmpty ? "Unknown location" : r.locationText,
                                    ),
                                    if (r.anonymous)
                                      const _DarkChip(icon: Icons.person_off_outlined, text: "Anonymous"),
                                    if (r.isPublic) const _DarkChip(icon: Icons.public, text: "Public"),
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
          ),
        ],
      ),
    );
  }
}

// ---------- UI helpers (dark/blue theme) ----------
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
      child: child,
    );
  }
}

class _DarkChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? bg;
  final Color? fg;

  const _DarkChip({
    required this.icon,
    required this.text,
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
            text,
            style: TextStyle(fontWeight: FontWeight.w800, color: fgColor),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.22)),
              ),
              child: Icon(icon, size: 38, color: Colors.white),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.78)),
            ),
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
              const Icon(Icons.error_outline, size: 42, color: Colors.white),
              const SizedBox(height: 10),
              const Text(
                "Something went wrong",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.85))),
              const SizedBox(height: 10),
              Text(hint, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.75))),
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