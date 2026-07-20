import '../../domain/repositories/wallet_repository.dart';
import '../models/wallet_model.dart';

/// REST implementation of WalletRepository (Placeholder/Dummy)
class RestWalletRepository implements WalletRepository {
  @override
  Future<WalletModel> getOrCreateWallet(String userId) async {
    final now = DateTime.now();
    return WalletModel(
      id: 'local-wallet-$userId',
      userId: userId,
      balance: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<double> getBalance(String userId) async {
    final wallet = await getOrCreateWallet(userId);
    return wallet.balance;
  }

  @override
  Future<({List<TransactionModel> transactions, int total})> getTransactions({
    required String userId,
    String? type,
    int limit = 25,
    int offset = 0,
  }) async {
    return (transactions: const <TransactionModel>[], total: 0);
  }

  @override
  Future<({String transactionId, double newBalance})> requestWithdrawal({
    required String userId,
    required double amount,
    Map<String, String>? bankDetails,
  }) async {
    return (
      transactionId: 'local-withdrawal-${DateTime.now().millisecondsSinceEpoch}',
      newBalance: 0.0,
    );
  }
}
