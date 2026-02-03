import 'dart:async';
import 'storage_repository.dart';

/// UploadService orchestrates uploads and returns progress streams and final URL metadata.
class UploadService {
  final StorageRepository storage;

  UploadService({required this.storage});

  /// Returns a stream of progress (0..1). When stream completes at 1.0, callers should call `getUrl` in a real storage implementation.
  Stream<double> uploadFile(String localPath, String destinationPath) {
    // In a real service we'd return an upload task that resolves to a download URL
    return storage.upload(localPath, destinationPath);
  }
}
