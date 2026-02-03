import 'dart:async';
import 'storage_repository.dart';

/// Stubbed FirebaseStorageRepository: not used in mock mode. Leave as placeholder for a future Firebase-backed implementation.
class FirebaseStorageRepository implements StorageRepository {
  @override
  Stream<double> upload(String filePath, String destinationPath) async* {
    throw UnimplementedError('FirebaseStorageRepository is not available in mock mode.');
  }

  @override
  Future<String?> getDownloadUrl(String destinationPath) async {
    return null;
  }

  @override
  void cancelUpload(String uploadId) {}
} 
