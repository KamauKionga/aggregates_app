import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/reports_repository.dart';
import 'services/receipt_service.dart';
import '../auth/auth_providers.dart';
import 'package:aggregates_app/services/mock_storage_repository.dart';

final reportsRepositoryProvider = Provider(
  (ref) => ReportsRepository(ref.read(firebaseFirestoreProvider)),
);
final receiptServiceProvider = Provider(
  (ref) => ReceiptService(storage: MockStorageRepository()),
);
