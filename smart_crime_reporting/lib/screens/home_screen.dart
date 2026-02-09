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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final stream = isAdmin
        ? _reports.watchAllReportsAdmin()
        : (_showPublic ? _reports.watchPublicReports() : _reports.watchMyReports(user.uid));

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'All Reports (Admin)' : (_showPublic ? 'Public Reports' : 'My Reports')),
        actions: [
          if (!isAdmin)
            IconButton(
              tooltip: _showPublic ? 'Show My Reports' : 'Show Public Reports',
              onPressed: () => setState(() => _showPublic = !_showPublic),
              icon: Icon(_showPublic ? Icons.person : Icons.public),
            ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _auth.logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateReportScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Report'),
      ),
      body: StreamBuilder<List<CrimeReport>>(
        stream: stream,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          if (items.isEmpty) return const Center(child: Text('No reports yet.'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = items[i];
              final title = r.anonymous ? '[Anonymous] ${r.title}' : r.title;
              return Card(
                child: ListTile(
                  title: Text(title),
                  subtitle: Text('${r.category} • ${r.status}\n${r.locationText}'),
                  isThreeLine: true,
                  trailing: r.evidenceUrls.isNotEmpty ? const Icon(Icons.attachment) : null,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ReportDetailsScreen(report: r, isAdmin: isAdmin)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
