import 'dart:async';

abstract class StorageRepository {
  /// Uploads file at [filePath] to [destinationPath] and returns a stream of progress (0..1)
  Stream<double> upload(String filePath, String destinationPath);

  /// Retrieve a download URL for a file at [destinationPath]
  Future<String?> getDownloadUrl(String destinationPath);

  /// Cancel ongoing upload (optional)
  void cancelUpload(String uploadId) {}
}
