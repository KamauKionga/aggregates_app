import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/quarries_datasource.dart';
import 'quarries_repository.dart';
import '../auth/auth_providers.dart' show firebaseFirestoreProvider;

final quarriesDataSourceProvider = Provider.autoDispose<QuarriesDataSource>(
  (ref) => QuarriesDataSource(ref.read(firebaseFirestoreProvider)),
);

final quarriesRepositoryProvider = Provider<QuarriesRepository>(
  (ref) => QuarriesRepository(ref.read(quarriesDataSourceProvider)),
);
