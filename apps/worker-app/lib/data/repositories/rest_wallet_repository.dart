import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../models/wallet_model.dart';

/// REST implementation of WalletRepository, backed by the worker
/// withdrawal endpoints (GET/POST /users/worker/withdrawals). The backend
/// has no generic top-up wallet — "balance" here is the worker's
/// withdrawable balance (net completed-job earnings minus amounts already
/// withdrawn or pending), and "transactions" are withdrawal requests.
class RestWalletRepository implements WalletRepository {
  final Dio _dio;

  RestWalletRepository({required Dio dio}) : _dio = dio;

  Future<Map<String, dynamic>> _fetchWithdrawals() async {
    final response = await _dio.get(ApiEndpoints.workerWithdrawals);
    return (response.data['data'] ?? response.data) as Map<String, dynamic>;
  }

  @override
  Future<WalletModel> getOrCreateWallet(String userId) async {
    final data = await _fetchWithdrawals();
    final now = DateTime.now();
    return WalletModel(
      id: 'worker-wallet-$userId',
      userId: userId,
      balance: ((data['availableBalance'] ?? 0) as num).toDouble(),
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
    final data = await _fetchWithdrawals();
    final items = (data['withdrawals'] as List? ?? []);
    final transactions = items
        .cast<Map<String, dynamic>>()
        .map(_withdrawalToTransaction)
        .skip(offset)
        .take(limit)
        .toList();
    return (transactions: transactions, total: items.length);
  }

  @override
  Future<({String transactionId, double newBalance})> requestWithdrawal({
    required String userId,
    required double amount,
    Map<String, String>? bankDetails,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.workerWithdrawals,
        data: {'amount': amount},
      );
      final data = (response.data['data'] ?? response.data) as Map<String, dynamic>;
      final withdrawal = _withdrawalToTransaction(data);

      // The create response only returns the new request, not the updated
      // balance — fetch it fresh so callers (e.g. EarningsBloc) see the
      // post-withdrawal available balance rather than a stale value.
      final newBalance = await getBalance(userId);

      return (transactionId: withdrawal.id, newBalance: newBalance);
    } on DioException catch (e) {
      throw Exception(_serverMessage(e));
    }
  }

  /// Extracts the backend's own error message (e.g. "Withdrawal amount
  /// exceeds available balance (Rs. 1200)") instead of letting the raw
  /// DioException reach the UI.
  String _serverMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return 'Something went wrong. Please try again.';
  }

  TransactionModel _withdrawalToTransaction(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now();
    final updatedAt = DateTime.tryParse(json['updatedAt'] ?? '') ?? createdAt;
    return TransactionModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      userId: (json['worker'] ?? '').toString(),
      type: WalletTransactionType.withdrawal,
      amount: ((json['amount'] ?? 0) as num).toDouble(),
      status: _mapWithdrawalStatus(json['status'] as String?),
      description: json['adminNotes'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  TransactionStatus _mapWithdrawalStatus(String? status) {
    switch (status) {
      case 'PAID':
        return TransactionStatus.completed;
      case 'REJECTED':
        return TransactionStatus.failed;
      case 'APPROVED':
      case 'PENDING':
      default:
        return TransactionStatus.pending;
    }
  }
}
