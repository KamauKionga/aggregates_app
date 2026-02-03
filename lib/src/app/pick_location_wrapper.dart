import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/location/presentation/map_picker.dart';

class PickLocationRouteWrapper extends ConsumerWidget {
  const PickLocationRouteWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MapPicker();
  }
}
