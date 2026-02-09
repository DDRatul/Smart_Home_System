import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;

  Future<String> uploadEvidence({
    required String userId,
    required String fileName,
    required File file,
  }) async {
    final ref = _storage.ref().child('evidence/$userId/$fileName');
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }
}
