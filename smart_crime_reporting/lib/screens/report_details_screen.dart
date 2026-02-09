import 'package:flutter/material.dart';
import '../models/report.dart';
import '../services/report_service.dart';
import 'package:intl/intl.dart';

class ReportDetailsScreen extends StatelessWidget {
  final CrimeReport report;
  final bool isAdmin;

  const ReportDetailsScreen({
    super.key,
    required this.report,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy-MM-dd HH:mm');
    final rs = ReportService();

    return Scaffold(
      appBar: AppBar(title: const Text('Report Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(report.anonymous ? '[Anonymous] ${report.title}' : report.title,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('${report.category} • ${report.status}'),
            const SizedBox(height: 6),
            Text('Location: ${report.locationText}'),
            const SizedBox(height: 6),
            Text('Created: ${fmt.format(report.createdAt.toLocal())}'),
            const Divider(height: 24),
            Text(report.description),
            const SizedBox(height: 16),

            if (report.evidenceUrls.isNotEmpty) ...[
              Text('Evidence (${report.evidenceUrls.length})',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...report.evidenceUrls.map((u) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(u, fit: BoxFit.cover),
                    ),
                  )),
            ],

            if (isAdmin) ...[
              const SizedBox(height: 16),
              Text('Admin actions', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      await rs.updateStatus(report.id, 'under_review');
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Mark Under Review'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      await rs.updateStatus(report.id, 'resolved');
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Mark Resolved'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
