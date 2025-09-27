// lib/screens/summary.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:wallet/models/provider_helper.dart';
import 'package:wallet/models/theme_provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:wallet/pages/walletdetails.dart';

class Summary extends StatelessWidget {
  const Summary({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final wallets = Provider.of<WalletProvider>(context).wallets;

    if (wallets.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Financial Summary")),
        body: Center(
          child: Text(
            "Add credit cards to see a summary.",
            style: themeProvider.getTextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // --- 1. Data Aggregation & Calculation ---
    double totalLimit = 0;
    double totalSpends = 0;
    double totalEstimatedCashback = 0;
    Wallet? topCashbackCard;
    Wallet? highestLimitCard;
    List<Wallet> feeWaiverCards = [];
    List<Map<String, dynamic>> upcomingBills = [];
    List<Wallet> incompleteCards = [];

    // Maps for new portfolio breakdowns
    Map<String, int> networkCounts = {};
    Map<String, int> issuerCounts = {};
    Map<String, int> cardTypeCounts = {};

    for (var wallet in wallets) {
      final limit = double.tryParse(wallet.maxlimit ?? '0') ?? 0;
      final spends = double.tryParse(wallet.spends ?? '0') ?? 0;
      final rewardsRate = double.tryParse(wallet.rewards ?? '0') ?? 0;
      final waiver = double.tryParse(wallet.annualFeeWaiver ?? '0') ?? 0;
      final billDate = int.tryParse(wallet.billdate ?? '');

      totalLimit += limit;
      totalSpends += spends;
      totalEstimatedCashback += (spends * rewardsRate) / 100;

      // Check for incomplete data to prompt the user
      if ((wallet.maxlimit ?? '').isEmpty ||
          (wallet.spends ?? '').isEmpty ||
          (wallet.rewards ?? '').isEmpty ||
          (wallet.billdate ?? '').isEmpty) {
        incompleteCards.add(wallet);
      }

      // Aggregate portfolio data
      if ((wallet.network ?? '').isNotEmpty) {
        networkCounts.update(
          wallet.network!.toUpperCase(),
          (val) => val + 1,
          ifAbsent: () => 1,
        );
      }
      if ((wallet.issuer ?? '').isNotEmpty) {
        issuerCounts.update(
          wallet.issuer!,
          (val) => val + 1,
          ifAbsent: () => 1,
        );
      }
      if ((wallet.cardtype ?? '').isNotEmpty) {
        cardTypeCounts.update(
          wallet.cardtype!,
          (val) => val + 1,
          ifAbsent: () => 1,
        );
      }

      // Existing Insights logic
      if (topCashbackCard == null ||
          rewardsRate >
              (double.tryParse(topCashbackCard.rewards ?? '0') ?? 0)) {
        topCashbackCard = wallet;
      }
      if (highestLimitCard == null ||
          limit > (double.tryParse(highestLimitCard.maxlimit ?? '0') ?? 0)) {
        highestLimitCard = wallet;
      }
      if (waiver > 0) {
        feeWaiverCards.add(wallet);
      }
      if (billDate != null) {
        upcomingBills.add({'wallet': wallet, 'date': billDate});
      }
    }

    final utilization = totalLimit > 0 ? (totalSpends / totalLimit) : 0.0;
    final today = DateTime.now().day;
    upcomingBills.sort((a, b) {
      int dayA = a['date'];
      int dayB = b['date'];
      int diffA = dayA >= today ? dayA - today : dayA + 30 - today;
      int diffB = dayB >= today ? dayB - today : dayB + 30 - today;
      return diffA.compareTo(diffB);
    });

    // --- 2. UI Build ---
    return Scaffold(
      appBar: AppBar(title: const Text("Financial Summary")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // NEW: Section to prompt user to update incomplete cards
          if (incompleteCards.isNotEmpty)
            _IncompleteCardsSection(incompleteCards: incompleteCards),

          _FinancialOverviewCard(
            totalLimit: totalLimit,
            totalSpends: totalSpends,
            utilization: utilization,
            totalCashback: totalEstimatedCashback,
          ),
          const SizedBox(height: 24),

          // NEW: Section for portfolio breakdown
          _CardDistributionSection(
            networkCounts: networkCounts,
            issuerCounts: issuerCounts,
            cardTypeCounts: cardTypeCounts,
          ),

          if (upcomingBills.isNotEmpty)
            _UpcomingBillsSection(upcomingBills: upcomingBills),

          if (topCashbackCard != null || highestLimitCard != null)
            _InsightsSection(
              topCashbackCard: topCashbackCard,
              highestLimitCard: highestLimitCard,
            ),

          if (feeWaiverCards.isNotEmpty)
            _FeeWaiverSection(feeWaiverCards: feeWaiverCards),
        ],
      ),
    );
  }
}

// --- NEW & MODIFIED WIDGETS ---

class _IncompleteCardsSection extends StatelessWidget {
  final List<Wallet> incompleteCards;
  const _IncompleteCardsSection({required this.incompleteCards});

  @override
  Widget build(BuildContext context) {
    return _SummarySection(
      title: "Improve Your Summary",
      icon: Icons.edit_note_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "The following cards are missing key financial details. Update them for a more accurate summary.",
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          ...incompleteCards.map((wallet) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.credit_card_outlined),
              title: Text(wallet.name),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WalletDetailScreen(wallet: wallet),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FinancialOverviewCard extends StatelessWidget {
  final double totalLimit, totalSpends, utilization, totalCashback;
  const _FinancialOverviewCard({
    required this.totalLimit,
    required this.totalSpends,
    required this.utilization,
    required this.totalCashback,
  });

  @override
  Widget build(BuildContext context) {
    return _SummaryContainer(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  label: 'Total Limit',
                  value: '₹${totalLimit.toStringAsFixed(0)}',
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  label: 'Total Spends',
                  value: '₹${totalSpends.toStringAsFixed(0)}',
                ),
                const SizedBox(height: 12),
                // MODIFIED: Added total cashback display
                _InfoRow(
                  label: 'Est. Cashback',
                  value: '₹${totalCashback.toStringAsFixed(2)}',
                  valueColor: Colors.green.shade600,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          CircularPercentIndicator(
            radius: 45.0,
            lineWidth: 8.0,
            percent: utilization.clamp(0.0, 1.0),
            center: Text(
              "${(utilization * 100).toStringAsFixed(1)}%",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
            footer: const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text("Utilization", style: TextStyle(fontSize: 12)),
            ),
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withAlpha(51),
          ),
        ],
      ),
    );
  }
}

class _CardDistributionSection extends StatelessWidget {
  final Map<String, int> networkCounts;
  final Map<String, int> issuerCounts;
  final Map<String, int> cardTypeCounts;

  const _CardDistributionSection({
    required this.networkCounts,
    required this.issuerCounts,
    required this.cardTypeCounts,
  });

  @override
  Widget build(BuildContext context) {
    return _SummarySection(
      title: "Portfolio Breakdown",
      icon: Icons.pie_chart_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDistributionRow("Networks", networkCounts, context),
          const Divider(height: 24),
          _buildDistributionRow("Issuers", issuerCounts, context),
          const Divider(height: 24),
          _buildDistributionRow("Types", cardTypeCounts, context),
        ],
      ),
    );
  }

  Widget _buildDistributionRow(
    String title,
    Map<String, int> counts,
    BuildContext context,
  ) {
    if (counts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: counts.entries.map((entry) {
            return Chip(
              label: Text('${entry.key} (${entry.value})'),
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withAlpha(26),
              side: BorderSide.none,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// --- EXISTING WIDGETS (with minor style consistency changes) ---

class _UpcomingBillsSection extends StatelessWidget {
  final List<Map<String, dynamic>> upcomingBills;
  const _UpcomingBillsSection({required this.upcomingBills});

  @override
  Widget build(BuildContext context) {
    return _SummarySection(
      title: "Upcoming Bill Dates",
      icon: Icons.event_note_outlined,
      child: SizedBox(
        height: 60,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: upcomingBills.length,
          itemBuilder: (context, index) {
            final item = upcomingBills[index];
            final wallet = item['wallet'] as Wallet;
            return Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withAlpha(51)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    wallet.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text("Day ${item['date']} of month"),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InsightsSection extends StatelessWidget {
  final Wallet? topCashbackCard;
  final Wallet? highestLimitCard;
  const _InsightsSection({this.topCashbackCard, this.highestLimitCard});

  @override
  Widget build(BuildContext context) {
    return _SummarySection(
      title: "Insights",
      icon: Icons.insights_rounded,
      child: Column(
        children: [
          if (topCashbackCard != null)
            _InfoRow(
              label: 'Top Earner',
              value:
                  "${topCashbackCard!.name} (${topCashbackCard!.rewards ?? '0'}%)",
            ),
          if (topCashbackCard != null && highestLimitCard != null)
            const Divider(height: 24, thickness: 0.5),
          if (highestLimitCard != null)
            _InfoRow(
              label: 'Highest Limit',
              value:
                  "${highestLimitCard!.name} (₹${highestLimitCard!.maxlimit ?? '0'})",
            ),
        ],
      ),
    );
  }
}

class _FeeWaiverSection extends StatelessWidget {
  final List<Wallet> feeWaiverCards;
  const _FeeWaiverSection({required this.feeWaiverCards});

  @override
  Widget build(BuildContext context) {
    return _SummarySection(
      title: "Fee Waiver Tracker",
      icon: Icons.verified_outlined,
      child: Column(
        children: feeWaiverCards.map((wallet) {
          double spends = double.tryParse(wallet.spends ?? '0') ?? 0;
          double waiver = double.tryParse(wallet.annualFeeWaiver ?? '0') ?? 0;
          double progress = waiver > 0
              ? (spends / waiver).clamp(0.0, 1.0)
              : 1.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wallet.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withAlpha(51),
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "₹${spends.toStringAsFixed(0)} / ₹${waiver.toStringAsFixed(0)}",
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// --- Base Widgets for consistent styling ---

class _SummarySection extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;
  const _SummarySection({required this.title, this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null)
              Icon(
                icon,
                size: 16,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            if (icon != null) const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SummaryContainer(child: child),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SummaryContainer extends StatelessWidget {
  final Widget child;
  const _SummaryContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withAlpha(51)),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withAlpha(204),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
