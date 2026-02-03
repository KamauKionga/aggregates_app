import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'data/agents_datasource.dart';
import 'agents_repository.dart';

final agentsDataSourceProvider = Provider<AgentsDataSource>((ref) {
  final fs = FirebaseFirestore.instance;
  return AgentsDataSource(fs);
});

final agentsRepositoryProvider = Provider<AgentsRepository>((ref) {
  final ds = ref.read(agentsDataSourceProvider);
  final fs = FirebaseFirestore.instance;
  return AgentsRepository(ds, fs);
});
