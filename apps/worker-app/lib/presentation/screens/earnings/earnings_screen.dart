import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../domain/repositories/booking_repository.dart';
import '../../../domain/repositories/wallet_repository.dart';
import '../../../domain/repositories/worker_repository.dart';
import '../../../injection_container.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final WorkerRepository _repository = sl<WorkerRepository>();
  final BookingRepository _bookingRepository = sl<BookingRepository>();
  final WalletRepository _walletDS = sl<WalletRepository>();
  bool _isLoading = true;
  String _selectedPeriod = 'week';

  double _totalEarnings = 0;
  double _pendingEarnings = 0;
  int _totalJobs = 0;
  List<Map<String, dynamic>> _earningsBreakdown = [];

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DateTime startDate;
      final now = DateTime.now();

      switch (_selectedPeriod) {
        case 'today':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(now.year, now.month - 1, now.day);
          break;
        default:
          startDate = now.subtract(const Duration(days: 7));
      }

      final data = await _repository.getEarnings(
        startDate: startDate,
        endDate: now,
      );

      // Calculate pending earnings from IN_PROGRESS/ACCEPTED bookings
      double pending = 0;
      try {
        final inProgressBookings = await _bookingRepository.getWorkerBookings(
          status: 'IN_PROGRESS',
        );
        final acceptedBookings = await _bookingRepository.getWorkerBookings(
          status: 'ACCEPTED',
        );
        for (final b in [...inProgressBookings, ...acceptedBookings]) {
          pending += b.pricing.estimatedPrice ?? 0;
        }
      } catch (_) {
        // Pending calculation is best-effort
      }

      // Build period label for display
      String periodLabel;
      switch (_selectedPeriod) {
        case 'today':
          periodLabel = 'Today';
          break;
        case 'week':
          periodLabel = 'This Week';
          break;
        case 'month':
          periodLabel = 'This Month';
          break;
        default:
          periodLabel = _selectedPeriod;
      }

      setState(() {
        _totalEarnings =
            ((data['totalEarnings'] ?? data['total']) ?? 0).toDouble();
        _totalJobs = (data['completedJobs'] ?? data['count'] ?? 0) as int;
        _pendingEarnings = pending;
        final breakdown = data['breakdown'];
        if (breakdown is List) {
          _earningsBreakdown = breakdown
              .map<Map<String, dynamic>>(
                (item) => {
                  'service': item['bookingNumber'] ?? item['service'] ?? 'Job',
                  'amount': item['amount'] ?? 0,
                  'date': item['date'] ?? periodLabel,
                },
              )
              .toList();
        } else {
          final breakdownMap =
              breakdown as Map<String, dynamic>? ?? <String, dynamic>{};
          _earningsBreakdown = breakdownMap.entries
              .map(
                (e) => {
                  'service': e.key.replaceAll('_', ' '),
                  'amount': e.value,
                  'date': periodLabel,
                },
              )
              .toList();
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load earnings: ${e.toString().replaceAll("Exception: ", "")}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEarnings,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Earnings Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        gradient: AppColors.earningsGradient,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLG,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Total Earnings',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textOnPrimary.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Rs. ${_totalEarnings.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textOnPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.work,
                                color: AppColors.textOnPrimary.withValues(
                                  alpha: 0.7,
                                ),
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$_totalJobs jobs completed',
                                style: TextStyle(
                                  color: AppColors.textOnPrimary.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Period Selector
                    Row(
                      children: [
                        _buildPeriodChip('Today', 'today'),
                        const SizedBox(width: AppSpacing.sm),
                        _buildPeriodChip('This Week', 'week'),
                        const SizedBox(width: AppSpacing.sm),
                        _buildPeriodChip('This Month', 'month'),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Quick Stats
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.trending_up,
                            label: 'Avg. per Job',
                            value: _totalJobs > 0
                                ? 'Rs. ${(_totalEarnings / _totalJobs).toStringAsFixed(0)}'
                                : 'Rs. 0',
                            color: AppColors.info,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.timer,
                            label: 'Pending',
                            value: 'Rs. ${_pendingEarnings.toStringAsFixed(0)}',
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Earnings History
                    const Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    if (_earningsBreakdown.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            children: [
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 64,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'No transactions yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _earningsBreakdown.length,
                        separatorBuilder: (_, index) =>
                            const Divider(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final item = _earningsBreakdown[index];
                          return _buildTransactionItem(item);
                        },
                      ),

                    const SizedBox(height: AppSpacing.xl),

                    // Withdraw Button
                    OutlinedButton.icon(
                      onPressed: _totalEarnings >= 500
                          ? () => _showWithdrawDialog()
                          : null,
                      icon: const Icon(Icons.account_balance),
                      label: Text(
                        _totalEarnings < 500
                            ? 'Min Rs. 500 to withdraw'
                            : 'Withdraw to Bank',
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
    );
  }

  void _showWithdrawDialog() {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw to Bank'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available: Rs. ${_totalEarnings.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (Rs.)',
                hintText: 'Min 500',
                prefixIcon: Icon(Icons.money),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Funds will be transferred to your registered bank account.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount < 500) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Minimum withdrawal is Rs. 500'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              if (amount > _totalEarnings) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Insufficient balance'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await _walletDS.requestWithdrawal(
                  userId: 'local-worker-wallet',
                  amount: amount,
                  bankDetails: {}, // Uses bank details from worker profile
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Withdrawal request submitted'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  _loadEarnings();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Withdrawal failed: ${e.toString().replaceAll("Exception: ", "")}',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = value;
        });
        _loadEarnings();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryDark
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
          border: Border.all(
            color: isSelected ? AppColors.primaryDark : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppColors.textOnPrimary
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> item) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
        ),
        child: const Icon(Icons.check_circle, color: AppColors.success),
      ),
      title: Text(
        item['service'] ?? 'Service',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(item['date'] ?? '', style: const TextStyle(fontSize: 12)),
      trailing: Text(
        'Rs. ${(item['amount'] ?? 0).toStringAsFixed(0)}',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.success,
        ),
      ),
    );
  }
}
