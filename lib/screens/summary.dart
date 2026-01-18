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
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: _buildAppBar(context, isDark),
      body: Selector<WalletProvider, WalletSummary>(
        selector: (_, provider) => provider.summary,
        builder: (context, summary, child) {
          if (Provider.of<WalletProvider>(
            context,
            listen: false,
          ).wallets.isEmpty) {
            return Center(
              child: Text(
                "Add credit cards to see a summary.",
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (summary.incompleteCards.isNotEmpty)
                _LiquidGlassIncompleteCardsSection(
                  incompleteCards: summary.incompleteCards,
                  isDark: isDark,
                ),

              _LiquidGlassFinancialOverviewCard(
                totalLimit: summary.totalLimit,
                totalSpends: summary.totalSpends,
                utilization: summary.utilization,
                totalCashback: summary.totalCashback,
                isDark: isDark,
              ),
              const SizedBox(height: 24),

              _LiquidGlassCardDistributionSection(
                networkCounts: summary.networkCounts,
                issuerCounts: summary.issuerCounts,
                cardTypeCounts: summary.cardTypeCounts,
                isDark: isDark,
              ),

              if (summary.upcomingBills.isNotEmpty)
                _LiquidGlassUpcomingBillsSection(
                  upcomingBills: summary.upcomingBills,
                  isDark: isDark,
                ),

              if (summary.topCashbackCard != null ||
                  summary.highestLimitCard != null)
                _LiquidGlassInsightsSection(
                  topCashbackCard: summary.topCashbackCard,
                  highestLimitCard: summary.highestLimitCard,
                  isDark: isDark,
                ),

              if (summary.feeWaiverCards.isNotEmpty)
                _LiquidGlassFeeWaiverSection(
                  feeWaiverCards: summary.feeWaiverCards,
                  isDark: isDark,
                ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      title: const Text("Financial Summary"),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
}

// --- LIQUID GLASS INCOMPLETE CARDS SECTION ---
class _LiquidGlassIncompleteCardsSection extends StatelessWidget {
  final List<Wallet> incompleteCards;
  final bool isDark;

  const _LiquidGlassIncompleteCardsSection({
    required this.incompleteCards,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black;

    return _LiquidGlassSummarySection(
      title: "Improve Your Summary",
      icon: Icons.edit_note_rounded,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "The following cards are missing key financial details. Update them for a more accurate summary.",
            style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 14),
          ),
          const SizedBox(height: 12),
          ...incompleteCards.map((wallet) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                dense: true,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.credit_card_outlined,
                    color: textColor.withOpacity(0.6),
                    size: 18,
                  ),
                ),
                title: Text(wallet.name, style: TextStyle(color: textColor)),
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: textColor.withOpacity(0.3),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WalletDetailScreen(wallet: wallet),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// --- LIQUID GLASS FINANCIAL OVERVIEW CARD ---
class _LiquidGlassFinancialOverviewCard extends StatelessWidget {
  final double totalLimit, totalSpends, utilization, totalCashback;
  final bool isDark;

  const _LiquidGlassFinancialOverviewCard({
    required this.totalLimit,
    required this.totalSpends,
    required this.utilization,
    required this.totalCashback,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black;

    return _LiquidGlassContainer(
      isDark: isDark,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  label: 'Total Limit',
                  value: '₹${totalLimit.toStringAsFixed(0)}',
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  label: 'Total Spends',
                  value: '₹${totalSpends.toStringAsFixed(0)}',
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  label: 'Est. Cashback',
                  value: '₹${totalCashback.toStringAsFixed(2)}',
                  isDark: isDark,
                  valueColor: Colors.green.shade400,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          CircularPercentIndicator(
            radius: 50.0,
            lineWidth: 8.0,
            percent: utilization.clamp(0.0, 1.0),
            center: Text(
              "${(utilization * 100).toStringAsFixed(1)}%",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
                color: textColor,
              ),
            ),
            footer: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                "Utilization",
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withOpacity(0.5),
                ),
              ),
            ),
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: isDark ? Colors.white : Colors.black,
            backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(
              0.15,
            ),
          ),
        ],
      ),
    );
  }
}

// --- LIQUID GLASS CARD DISTRIBUTION SECTION ---
class _LiquidGlassCardDistributionSection extends StatelessWidget {
  final Map<String, int> networkCounts;
  final Map<String, int> issuerCounts;
  final Map<String, int> cardTypeCounts;
  final bool isDark;

  const _LiquidGlassCardDistributionSection({
    required this.networkCounts,
    required this.issuerCounts,
    required this.cardTypeCounts,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black;

    return _LiquidGlassSummarySection(
      title: "Portfolio Breakdown",
      icon: Icons.pie_chart_outline_rounded,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDistributionRow("Networks", networkCounts, textColor),
          if (issuerCounts.isNotEmpty) ...[
            Divider(
              height: 32,
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.08),
            ),
            _buildDistributionRow("Issuers", issuerCounts, textColor),
          ],
          if (cardTypeCounts.isNotEmpty) ...[
            Divider(
              height: 32,
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.08),
            ),
            _buildDistributionRow("Types", cardTypeCounts, textColor),
          ],
        ],
      ),
    );
  }

  Widget _buildDistributionRow(
    String title,
    Map<String, int> counts,
    Color textColor,
  ) {
    if (counts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: counts.entries.map((entry) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.08),
                ),
              ),
              child: Text(
                '${entry.key} (${entry.value})',
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// --- LIQUID GLASS UPCOMING BILLS SECTION ---
class _LiquidGlassUpcomingBillsSection extends StatelessWidget {
  final List<Map<String, dynamic>> upcomingBills;
  final bool isDark;

  const _LiquidGlassUpcomingBillsSection({
    required this.upcomingBills,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black;

    return _LiquidGlassSummarySection(
      title: "Upcoming Bill Dates",
      icon: Icons.event_note_outlined,
      isDark: isDark,
      child: SizedBox(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: upcomingBills.length,
          itemBuilder: (context, index) {
            final item = upcomingBills[index];
            final wallet = item['wallet'] as Wallet;
            return Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.06),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    wallet.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Day ${item['date']}",
                    style: TextStyle(color: textColor.withOpacity(0.6)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// --- LIQUID GLASS INSIGHTS SECTION ---
class _LiquidGlassInsightsSection extends StatelessWidget {
  final Wallet? topCashbackCard;
  final Wallet? highestLimitCard;
  final bool isDark;

  const _LiquidGlassInsightsSection({
    this.topCashbackCard,
    this.highestLimitCard,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return _LiquidGlassSummarySection(
      title: "Insights",
      icon: Icons.insights_rounded,
      isDark: isDark,
      child: Column(
        children: [
          if (topCashbackCard != null)
            _InfoRow(
              label: 'Top Earner',
              value:
                  "${topCashbackCard!.name} (${topCashbackCard!.rewards ?? '0'}%)",
              isDark: isDark,
            ),
          if (topCashbackCard != null && highestLimitCard != null)
            Divider(
              height: 28,
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.08),
            ),
          if (highestLimitCard != null)
            _InfoRow(
              label: 'Highest Limit',
              value:
                  "${highestLimitCard!.name} (₹${highestLimitCard!.maxlimit ?? '0'})",
              isDark: isDark,
            ),
        ],
      ),
    );
  }
}

// --- LIQUID GLASS FEE WAIVER SECTION ---
class _LiquidGlassFeeWaiverSection extends StatelessWidget {
  final List<Wallet> feeWaiverCards;
  final bool isDark;

  const _LiquidGlassFeeWaiverSection({
    required this.feeWaiverCards,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black;

    return _LiquidGlassSummarySection(
      title: "Fee Waiver Tracker",
      icon: Icons.verified_outlined,
      isDark: isDark,
      child: Column(
        children: feeWaiverCards.map((wallet) {
          double spends = double.tryParse(wallet.spends ?? '0') ?? 0;
          double waiver = double.tryParse(wallet.annualFeeWaiver ?? '0') ?? 0;
          double progress = waiver > 0
              ? (spends / waiver).clamp(0.0, 1.0)
              : 1.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wallet.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: (isDark ? Colors.white : Colors.black).withOpacity(
                      0.1,
                    ),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          colors: isDark
                              ? [Colors.white.withOpacity(0.8), Colors.white]
                              : [Colors.black.withOpacity(0.7), Colors.black],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "₹${spends.toStringAsFixed(0)} / ₹${waiver.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withOpacity(0.6),
                    ),
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

// --- BASE LIQUID GLASS WIDGETS ---

class _LiquidGlassSummarySection extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;
  final bool isDark;

  const _LiquidGlassSummarySection({
    required this.title,
    this.icon,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: textColor.withOpacity(0.4)),
                const SizedBox(width: 8),
              ],
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: textColor.withOpacity(0.4),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        _LiquidGlassContainer(isDark: isDark, child: child),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _LiquidGlassContainer({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8),
          width: 0.5,
        ),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black;
    final mutedColor = isDark ? Colors.white60 : Colors.black54;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: mutedColor)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: valueColor ?? textColor,
          ),
        ),
      ],
    );
  }
}
