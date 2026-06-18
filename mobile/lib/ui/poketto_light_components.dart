import 'package:flutter/material.dart';
import 'package:poketto/ui/app_theme.dart';
import 'package:poketto/ui/app_widgets.dart';

class LightHeader extends StatelessWidget {
  final String userName;
  final String subtitle;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationsTap;
  final int unreadNotificationsCount;

  const LightHeader({
    super.key,
    required this.userName,
    required this.subtitle,
    required this.onProfileTap,
    required this.onNotificationsTap,
    this.unreadNotificationsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Halo, $userName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: TextStyle(
                      color: context.poketto.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(.8),
            borderRadius: BorderRadius.circular(PokettoRadius.medium),
            border: Border.all(color: context.poketto.border),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: 'Notifikasi',
                    onPressed: onNotificationsTap,
                    icon: const Icon(Icons.notifications_outlined),
                    color: theme.colorScheme.primary,
                    constraints:
                        const BoxConstraints.tightFor(width: 44, height: 44),
                  ),
                  if (unreadNotificationsCount > 0)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        constraints:
                            const BoxConstraints(minWidth: 17, minHeight: 17),
                        decoration: BoxDecoration(
                          color: context.poketto.expense,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                              color: theme.colorScheme.surface, width: 1.5),
                        ),
                        child: Text(
                          unreadNotificationsCount > 9
                              ? '9+'
                              : '$unreadNotificationsCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Container(width: 1, height: 24, color: context.poketto.border),
              IconButton(
                tooltip: 'Profil',
                onPressed: onProfileTap,
                icon: const Icon(Icons.person_outline_rounded),
                color: theme.colorScheme.primary,
                constraints:
                    const BoxConstraints.tightFor(width: 44, height: 44),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LightBalanceCard extends StatelessWidget {
  final String balance;
  final String income;
  final String expense;
  final VoidCallback? onAddPressed;

  const LightBalanceCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
    this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PokettoSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF8B38), Color(0xFFFF6B00), Color(0xFF8A3100)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(.25),
            blurRadius: 30,
            offset: const Offset(0, 15),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded, color: Colors.white),
              Spacer(),
              Text('Saldo utama',
                  style: TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 22),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(balance,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 6),
          const Text('Total pemasukan dikurangi pengeluaran',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: PokettoSpacing.lg),
          Row(children: [
            Expanded(child: _BalanceMetric(label: 'Pemasukan', value: income)),
            const SizedBox(width: 10),
            Expanded(
                child: _BalanceMetric(label: 'Pengeluaran', value: expense)),
          ]),
          if (onAddPressed != null) ...[
            const SizedBox(height: PokettoSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAddPressed,
                icon: const Icon(Icons.add_rounded, size: 19),
                label: const Text('Tambah transaksi'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF9A3900),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(PokettoRadius.medium),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BalanceMetric extends StatelessWidget {
  final String label;
  final String value;
  const _BalanceMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(.14),
            borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 5),
          FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w900))),
        ]),
      );
}

class LightFeatureShortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const LightFeatureShortcut({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: context.poketto.softSurface,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}

class LightTransactionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final bool isIncome;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const LightTransactionItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isIncome,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) => TransactionListItem(
        icon: icon,
        title: title,
        subtitle: subtitle,
        amount: amount,
        isIncome: isIncome,
        onTap: onTap,
        onLongPress: onLongPress,
      );
}

class BudgetSummaryCard extends StatelessWidget {
  final String spending;
  final String remaining;
  final double progress;
  final String caption;

  const BudgetSummaryCard({
    super.key,
    required this.spending,
    required this.remaining,
    required this.progress,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = context.poketto;
    final value = progress.clamp(0.0, 1.0);
    final progressColor = progress >= 1
        ? semantic.expense
        : Theme.of(context).colorScheme.primary;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Ringkasan budget',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _Metric(label: 'Pengeluaran', value: spending)),
          const SizedBox(width: 10),
          Expanded(child: _Metric(label: 'Sisa harian', value: remaining)),
        ]),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 9,
            value: value,
            color: progressColor,
            backgroundColor: semantic.softSurface,
          ),
        ),
        const SizedBox(height: 9),
        Text(caption,
            style: TextStyle(color: semantic.mutedText, fontSize: 12)),
      ]),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: context.poketto.softSurface,
            borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(color: context.poketto.mutedText, fontSize: 11)),
          const SizedBox(height: 5),
          FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w900))),
        ]),
      );
}

class LightBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const LightBottomNav({super.key, this.currentIndex = 0, required this.onTap});

  @override
  Widget build(BuildContext context) => PokettoBottomNav(
        currentIndex: currentIndex.clamp(0, 3),
        onDestinationSelected: onTap,
      );
}

class LightSectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const LightSectionTitle({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ]);
}
