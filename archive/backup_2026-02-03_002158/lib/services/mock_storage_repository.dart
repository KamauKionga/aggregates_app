import 'dart:async';
import 'storage_repository.dart';

class MockStorageRepository implements StorageRepository {
  @override
  Stream<double> upload(String filePath, String destinationPath) async* {
    // Simulate upload progress
    for (var i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      yield i / 10.0;
    }
    // After upload completes, yield 1.0 and rely on caller to interpret as success
    yield 1.0;
  }

  @override
  Future<String?> getDownloadUrl(String destinationPath) async {
    // In mock, just return path as URL-like string
    return 'mock://$destinationPath';
  }

  @override
  void cancelUpload(String uploadId) {}
}
