import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report.dart';

class ReportService {
  final _db = FirebaseFirestore.instance;
  CollectionReference get _reports => _db.collection('reports');

  Stream<List<CrimeReport>> watchMyReports(String uid) {
    return _reports
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CrimeReport.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  Stream<List<CrimeReport>> watchPublicReports() {
    return _reports
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CrimeReport.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  Stream<List<CrimeReport>> watchAllReportsAdmin() {
    return _reports
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CrimeReport.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }
Future<String> createReport(CrimeReport report) async {
  await _reports.doc(report.id).set(report.toMap()); // ✅ use UUID as doc id
  return report.id;
}

  Future<void> updateStatus(String reportId, String newStatus) async {
    await _reports.doc(reportId).update({'status': newStatus});
  }
}
