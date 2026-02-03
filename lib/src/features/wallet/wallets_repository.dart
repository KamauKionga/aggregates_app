import 'data/wallets_datasource.dart';
import 'domain/wallet.dart';

class WalletsRepository {
  final WalletsDataSource _ds;

  WalletsRepository(this._ds);

  Future<Wallet> ensureWallet(String id, String ownerType) =>
      _ds.ensureWallet(id, ownerType);

  Future<Wallet?> getWallet(String id) => _ds.getWallet(id);

  Future<void> creditPending(String walletId, int amount, String reference) =>
      _ds.addPendingCredit(walletId, amount, reference);

  Future<void> movePendingToAvailable(String walletId) =>
      _ds.movePendingToAvailable(walletId);

  Future<void> requestWithdrawal(
    String walletId,
    int amount,
    String requestedBy,
  ) => _ds.createWithdrawalRequest(walletId, amount, requestedBy);

  Future<void> adminApproveWithdrawal(String withdrawalId, String adminId) =>
      _ds.adminApproveWithdrawal(withdrawalId, adminId);

  Future<List<Map<String, dynamic>>> listWithdrawals({
    String status = 'requested',
  }) => _ds.listWithdrawals(status: status);
}
