import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/wallet.dart';
import '../domain/ledger_entry.dart';

class WalletsDataSource {
  final FirebaseFirestore firestore;
  final CollectionReference _wallets;

  WalletsDataSource(this.firestore)
    : _wallets = firestore.collection('wallets');

  Future<Wallet> ensureWallet(String id, String ownerType) async {
    final ref = _wallets.doc(id);
    final snap = await ref.get();
    if (snap.exists)
      return Wallet.fromMap(Map<String, dynamic>.from(snap.data() as Map));
    final w = Wallet(
      id: id,
      ownerType: ownerType,
      available: 0,
      pending: 0,
      updatedAt: DateTime.now().toUtc(),
    );
    await ref.set(w.toMap());
    return w;
  }

  Future<Wallet?> getWallet(String id) async {
    final snap = await _wallets.doc(id).get();
    if (!snap.exists) return null;
    return Wallet.fromMap(Map<String, dynamic>.from(snap.data() as Map));
  }

  Future<void> addPendingCredit(
    String walletId,
    int amount,
    String reference,
  ) async {
    final ref = _wallets.doc(walletId);
    final ledgerRef = ref.collection('ledger');
    await firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists)
        tx.set(ref, {
          'id': walletId,
          'ownerType': 'unknown',
          'available': 0,
          'pending': amount,
          'updatedAt': DateTime.now().toUtc(),
        });
      else {
        final data = snap.data() as Map<String, dynamic>;
        final pending = (data['pending'] as num?)?.toInt() ?? 0;
        tx.update(ref, {
          'pending': pending + amount,
          'updatedAt': DateTime.now().toUtc(),
        });
      }
      final id = ledgerRef.doc().id;
      tx.set(
        ledgerRef.doc(id),
        LedgerEntry(
          id: id,
          walletId: walletId,
          amount: amount,
          type: 'pending_credit',
          reference: reference,
          createdAt: DateTime.now().toUtc(),
        ).toMap(),
      );
    });
  }

  Future<void> movePendingToAvailable(String walletId) async {
    final ref = _wallets.doc(walletId);
    final ledgerRef = ref.collection('ledger');
    await firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final pending = (data['pending'] as num?)?.toInt() ?? 0;
      if (pending == 0) return;
      final available = (data['available'] as num?)?.toInt() ?? 0;
      tx.update(ref, {
        'available': available + pending,
        'pending': 0,
        'updatedAt': DateTime.now().toUtc(),
      });
      final id = ledgerRef.doc().id;
      tx.set(
        ledgerRef.doc(id),
        LedgerEntry(
          id: id,
          walletId: walletId,
          amount: pending,
          type: 'available_credit',
          reference: 'eod-settlement',
          createdAt: DateTime.now().toUtc(),
        ).toMap(),
      );
    });
  }

  Future<void> createWithdrawalRequest(
    String walletId,
    int amount,
    String requestedBy,
  ) async {
    final withdraws = firestore.collection('withdrawals');
    final id = withdraws.doc().id;
    await withdraws.doc(id).set({
      'id': id,
      'walletId': walletId,
      'amount': amount,
      'status': 'requested', // requested, approved, paid, rejected
      'requestedBy': requestedBy,
      'requestedAt': DateTime.now().toUtc(),
    });
  }

  Future<void> adminApproveWithdrawal(
    String withdrawalId,
    String adminId,
  ) async {
    final withdrawRef = firestore.collection('withdrawals').doc(withdrawalId);
    await firestore.runTransaction((tx) async {
      final snap = await tx.get(withdrawRef);
      if (!snap.exists) throw Exception('Withdrawal not found');
      final data = snap.data() as Map<String, dynamic>;
      if (data['status'] != 'requested')
        throw Exception('Withdrawal not in requested state');
      final walletRef = _wallets.doc(data['walletId'] as String);
      final wSnap = await tx.get(walletRef);
      if (!wSnap.exists) throw Exception('Wallet missing');
      final wData = wSnap.data() as Map<String, dynamic>;
      final available = (wData['available'] as num?)?.toInt() ?? 0;
      final amount = (data['amount'] as num).toInt();
      if (available < amount) throw Exception('Insufficient wallet balance');
      tx.update(walletRef, {
        'available': available - amount,
        'updatedAt': DateTime.now().toUtc(),
      });
      tx.update(withdrawRef, {
        'status': 'approved',
        'approvedBy': adminId,
        'approvedAt': DateTime.now().toUtc(),
      });

      final ledgerRef = walletRef.collection('ledger');
      final id = ledgerRef.doc().id;
      tx.set(
        ledgerRef.doc(id),
        LedgerEntry(
          id: id,
          walletId: walletRef.id,
          amount: -amount,
          type: 'withdrawal',
          reference: withdrawalId,
          createdAt: DateTime.now().toUtc(),
        ).toMap(),
      );
    });
  }

  Future<List<Map<String, dynamic>>> listWithdrawals({
    String status = 'requested',
  }) async {
    final q = await firestore
        .collection('withdrawals')
        .where('status', isEqualTo: status)
        .get();
    return q.docs
        .map((d) => Map<String, dynamic>.from(d.data() as Map))
        .toList();
  }
}
