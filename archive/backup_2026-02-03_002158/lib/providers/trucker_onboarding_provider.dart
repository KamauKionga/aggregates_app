import 'package:flutter/material.dart';
import '../Models/trucker_model.dart';
import '../services/trucker_repository.dart';
import '../Models/enums.dart';

class TruckerOnboardingProvider extends ChangeNotifier {
  TruckerModel? _trucker;
  TruckerModel? get trucker => _trucker;

  bool _loading = false;
  bool get loading => _loading;

  Future<void> loadByUserId(String userId) async {
    _loading = true;
    notifyListeners();
    _trucker = await TruckerRepository.getByUserId(userId);
    _loading = false;
    notifyListeners();
  }

  Future<void> createOrUpdate(TruckerModel t) async {
    _loading = true;
    notifyListeners();
    await TruckerRepository.saveTrucker(t);
    _trucker = t;
    _loading = false;
    notifyListeners();
  }

  Future<void> setStatus(VerificationStatus s) async {
    if (_trucker == null) return;
    _trucker = TruckerModel(
      id: _trucker!.id,
      userId: _trucker!.userId,
      email: _trucker!.email,
      phone: _trucker!.phone,
      type: _trucker!.type,
      verificationStatus: s,
      documents: _trucker!.documents,
      trucks: _trucker!.trucks,
      drivers: _trucker!.drivers,
    );
    await TruckerRepository.update(_trucker!);
    notifyListeners();
  }
}
