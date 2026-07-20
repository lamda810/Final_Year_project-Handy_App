import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/models/wallet_model.dart';

/// Wallet screen showing balance and transactions
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  // TODO: Rewire to a REST wallet API once the backend exposes wallet
  // endpoints. The old Appwrite Functions integration was removed with the
  // migration to the Node backend.
  final double _balance = 0.0;
  final List<TransactionModel> _transactions = [];
  final bool _isLoading = false;

  Future<void> _loadWallet() async {
    // Wallet backend not available yet; balance and transactions stay empty.
  }

  void _showWalletUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Wallet service is not available yet'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showTransactionHistory(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWallet,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Balance card
                    _buildBalanceCard(),

                    const SizedBox(height: AppSpacing.lg),

                    // Quick actions
                    _buildQuickActions(),

                    const SizedBox(height: AppSpacing.lg),

                    // Recent transactions
                    _buildSectionTitle('Recent Transactions'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildRecentTransactions(),

                    const SizedBox(height: AppSpacing.lg),

                    // Promo code section
                    _buildPromoCodeSection(),

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBalanceCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.textOnPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'Available Balance',
                style: TextStyle(fontSize: 14, color: AppColors.textOnPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Rs. ${_balance.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppColors.textOnPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddMoneyDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Money'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.surface,
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _balance > 0
                      ? () => _showWithdrawDialog(context)
                      : null,
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  label: const Text('Withdraw'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textOnPrimary,
                    side: const BorderSide(color: AppColors.textOnPrimary),
                    disabledForegroundColor: AppColors.textOnPrimary.withValues(
                      alpha: 0.54,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            icon: Icons.card_giftcard,
            label: 'Rewards',
            onTap: () => _showRewardsInfo(context),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildActionCard(
            icon: Icons.confirmation_number,
            label: 'Coupons',
            onTap: () => _showCoupons(context),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildActionCard(
            icon: Icons.people,
            label: 'Refer',
            onTap: () => _showReferralInfo(context),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.1),
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    if (_transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.1),
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add money to your wallet to get started',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 5,
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _transactions.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final transaction = _transactions[index];
          return _buildTransactionTile(transaction);
        },
      ),
    );
  }

  Widget _buildTransactionTile(TransactionModel transaction) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCredit = transaction.isCredit;
    final dateStr = DateFormat(
      'MMM dd, yyyy – HH:mm',
    ).format(transaction.createdAt);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: (isCredit ? AppColors.success : AppColors.error).withValues(
            alpha: 0.1,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Icon(
          isCredit ? Icons.add : Icons.remove,
          color: isCredit ? AppColors.success : AppColors.error,
          size: 20,
        ),
      ),
      title: Text(
        transaction.description ?? transaction.typeLabel,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        dateStr,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
      trailing: Text(
        '${isCredit ? '+' : '-'} Rs. ${transaction.amount.toStringAsFixed(0)}',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isCredit ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }

  Widget _buildPromoCodeSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final controller = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Have a promo code?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Enter code',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ElevatedButton(
                onPressed: () => _applyPromoCode(controller.text),
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddMoneyDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final amounts = [500, 1000, 2000, 5000];
    int? selectedAmount;
    final customController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (context, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Add Money to Wallet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Amount',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: amounts.map((amount) {
                        final isSelected = selectedAmount == amount;
                        return GestureDetector(
                          onTap: () => setSheetState(() {
                            selectedAmount = amount;
                            customController.clear();
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              'Rs. $amount',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppColors.textOnPrimary
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Or enter custom amount',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: customController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setSheetState(() {
                        selectedAmount = null;
                      }),
                      decoration: InputDecoration(
                        prefixText: 'Rs. ',
                        hintText: '0',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final amount =
                              selectedAmount ??
                              int.tryParse(customController.text) ??
                              0;
                          if (amount >= 100) {
                            Navigator.pop(sheetContext);
                            _processAddMoney(amount);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Minimum amount is Rs. 100'),
                              ),
                            );
                          }
                        },
                        child: const Text('Continue'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw to Bank'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            prefixText: 'Rs. ',
            hintText: 'Min. 500',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount < 500) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Minimum withdrawal is Rs. 500'),
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              if (!mounted) return;
              _showWalletUnavailable();
            },
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  void _showTransactionHistory(BuildContext context) {
    // Already shown on main page; navigate to full history if needed
    if (_transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transaction history yet')),
      );
    }
  }

  void _showRewardsInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rewards Program'),
        content: const Text(
          'Earn rewards on every booking!\n\n'
          '• Get 1% cashback on all bookings\n'
          '• Extra rewards on referrals\n'
          '• Special bonuses on milestones',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showCoupons(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'My Coupons',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.confirmation_number_outlined,
                  size: 48,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No coupons available',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReferralInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refer & Earn'),
        content: const Text(
          'Share HandyGo with friends!\n\n'
          '• Get Rs. 100 for each friend who signs up\n'
          '• Your friend gets Rs. 100 too\n'
          '• No limit on referrals',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Clipboard.setData(
                const ClipboardData(
                  text:
                      'Join Handy Go and get Rs. 100! Download now: https://handygo.app/invite',
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Referral link copied to clipboard!'),
                ),
              );
            },
            child: const Text('Share Now'),
          ),
        ],
      ),
    );
  }

  void _applyPromoCode(String code) {
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a promo code')),
      );
      return;
    }

    // Promo code validation will be added when promo_codes collection is ready
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Invalid promo code: $code')));
  }

  void _processAddMoney(int amount) async {
    // TODO: Integrate a payment gateway (JazzCash / Easypaisa / Stripe)
    // once the backend exposes wallet top-up endpoints.
    _showWalletUnavailable();
  }
}
