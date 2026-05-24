// lib/screens/summary.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wallet/models/db_helper.dart';
import 'package:wallet/models/provider_helper.dart';
import 'package:wallet/models/theme_provider.dart';
import 'package:wallet/models/startup_settings_provider.dart';
import 'package:wallet/models/dataentry.dart'; // import palette & CardColorData
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:wallet/pages/walletdetails.dart';
import 'package:wallet/screens/homescreen.dart';

class Summary extends StatefulWidget {
  const Summary({super.key});

  @override
  State<Summary> createState() => _SummaryState();
}

class _SummaryState extends State<Summary> with SingleTickerProviderStateMixin {
  int _activeTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final startupProvider = Provider.of<StartupSettingsProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final symbol = startupProvider.selectedCurrencySymbol;

    return Scaffold(
      appBar: _buildAppBar(context, isDark),
      body: Selector<WalletProvider, WalletSummary>(
        selector: (_, provider) => provider.summary,
        builder: (context, summary, child) {
          final hasCards = Provider.of<WalletProvider>(
            context,
            listen: false,
          ).wallets.isNotEmpty;

          if (!hasCards) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.credit_card_rounded,
                    size: 80,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "No Credit Cards Found",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      "Add your credit cards to unlock a gorgeous financial summary and analytics dashboard.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white38 : Colors.black45,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildTabBar(isDark),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: KeyedSubtree(
                    key: ValueKey<int>(_activeTabIndex),
                    child: _buildActiveTabContent(summary, isDark, symbol),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      title: const Text(
        "Summary Dashboard",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      elevation: 0,
      centerTitle: true,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
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

  Widget _buildTabBar(bool isDark) {
    final capsuleBg = isDark ? const Color(0xFF161616) : const Color(0xFFECECEC);
    final activeBg = isDark ? const Color(0xFF2E2E2E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: capsuleBg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTabButton(0, "Overview", activeBg, textColor)),
          Expanded(child: _buildTabButton(1, "Analytics", activeBg, textColor)),
          Expanded(child: _buildTabButton(2, "Bills & Goals", activeBg, textColor)),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, Color activeBg, Color textColor) {
    final isActive = _activeTabIndex == index;
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          HapticFeedback.lightImpact();
          setState(() {
            _activeTabIndex = index;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? textColor : textColor.withValues(alpha: 0.5),
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(WalletSummary summary, bool isDark, String symbol) {
    switch (_activeTabIndex) {
      case 0:
        return _buildOverviewTab(summary, isDark, symbol);
      case 1:
        return _buildAnalyticsTab(summary, isDark, symbol);
      case 2:
        return _buildBillsWaiversTab(summary, isDark, symbol);
      default:
        return const SizedBox.shrink();
    }
  }

  // ==================== TAB 1: OVERVIEW TAB ====================
  Widget _buildOverviewTab(WalletSummary summary, bool isDark, String symbol) {
    final availableCredit = summary.totalLimit - summary.totalSpends;
    final progress = summary.totalLimit > 0
        ? (summary.totalSpends / summary.totalLimit).clamp(0.0, 1.0)
        : 0.0;
    final textColor = isDark ? Colors.white : Colors.black;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- 1. Portfolio Hero Card ---
        _LiquidGlassContainer(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "AVAILABLE CREDIT",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: textColor.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  "$symbol${availableCredit.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Linear Spend progress
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 8,
                  width: double.infinity,
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade400,
                            Colors.teal.shade500,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _HeroStatCol(
                    label: "Spent",
                    value: "$symbol${summary.totalSpends.toStringAsFixed(0)}",
                    isDark: isDark,
                  ),
                  _HeroStatCol(
                    label: "Total Limit",
                    value: "$symbol${summary.totalLimit.toStringAsFixed(0)}",
                    isDark: isDark,
                    alignRight: true,
                  ),
                ],
              ),
              Divider(
                height: 32,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade400.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.green.shade400,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Est. Cashback Reward",
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.6),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "$symbol${summary.totalCashback.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.green.shade400,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 20),

        // --- 2. Credit Utilization Circle ---
        _LiquidGlassContainer(
          isDark: isDark,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Credit Utilization",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Percentage of total limit you are currently utilizing.",
                      style: TextStyle(
                        fontSize: 12.5,
                        color: textColor.withValues(alpha: 0.5),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildUtilizationBadge(summary.utilization),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              CircularPercentIndicator(
                radius: 46.0,
                lineWidth: 8.0,
                percent: summary.utilization.clamp(0.0, 1.0),
                animation: true,
                animationDuration: 1000,
                center: Text(
                  "${(summary.utilization * 100).toStringAsFixed(1)}%",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                    color: textColor,
                  ),
                ),
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: _getUtilizationColor(summary.utilization),
                backgroundColor: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // --- 3. Smart Insights Engine ---
        _LiquidGlassSummarySection(
          title: "Smart Insights",
          icon: Icons.lightbulb_outline_rounded,
          isDark: isDark,
          child: Column(
            children: _buildSmartInsights(summary, isDark, symbol),
          ),
        ),

        // --- 4. Incomplete Cards (Quick actions) ---
        if (summary.incompleteCards.isNotEmpty)
          _LiquidGlassIncompleteCardsSection(
            incompleteCards: summary.incompleteCards,
            isDark: isDark,
          ),
      ],
    );
  }

  Color _getUtilizationColor(double utilization) {
    if (utilization <= 0.15) {
      return const Color(0xFF00C853); // Healthy (green)
    } else if (utilization <= 0.30) {
      return const Color(0xFF64DD17); // Light green
    } else if (utilization <= 0.50) {
      return const Color(0xFFFFAB00); // Warning (amber)
    } else {
      return const Color(0xFFD50000); // Dangerous (red)
    }
  }

  Widget _buildUtilizationBadge(double utilization) {
    String text;
    Color color;
    if (utilization <= 0.15) {
      text = "Excellent Credit Range";
      color = const Color(0xFF00C853);
    } else if (utilization <= 0.30) {
      text = "Good Credit Range";
      color = const Color(0xFF64DD17);
    } else if (utilization <= 0.50) {
      text = "High Utilization";
      color = const Color(0xFFFFAB00);
    } else {
      text = "Risky Utilization";
      color = const Color(0xFFD50000);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  List<Widget> _buildSmartInsights(WalletSummary summary, bool isDark, String symbol) {
    List<Widget> insights = [];
    final textColor = isDark ? Colors.white : Colors.black;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF2F2F2);

    Widget buildInsightCard({
      required IconData icon,
      required Color iconColor,
      required String title,
      required String description,
    }) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
            width: 0.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withValues(alpha: 0.7),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Insight 1: Utilization Score
    if (summary.utilization > 0.3) {
      insights.add(buildInsightCard(
        icon: Icons.warning_amber_rounded,
        iconColor: Colors.amber.shade600,
        title: "High Credit Utilization Alert",
        description: "Your utilization rate is at ${(summary.utilization * 100).toStringAsFixed(1)}%. Spends exceeding 30% can negatively impact your credit profile. Consider settling a portion before bill statement cycles.",
      ));
    } else if (summary.utilization > 0) {
      insights.add(buildInsightCard(
        icon: Icons.check_circle_outline_rounded,
        iconColor: Colors.green.shade500,
        title: "Optimal Credit Utilization",
        description: "Excellent job! Your credit utilization of ${(summary.utilization * 100).toStringAsFixed(1)}% is perfectly matching credit bureau recommendations under 30%.",
      ));
    }

    // Insight 2: Top rewards card
    if (summary.topCashbackCard != null) {
      final r = double.tryParse(summary.topCashbackCard!.rewards ?? '0') ?? 0;
      if (r > 0) {
        insights.add(buildInsightCard(
          icon: Icons.auto_awesome_rounded,
          iconColor: Colors.purple.shade400,
          title: "Maximize Cashback Strategy",
          description: "Use your '${summary.topCashbackCard!.name}' card for general purchases to secure a high $r% cashback rewards rate.",
        ));
      }
    }

    // Insight 3: Network Concentration
    if (summary.networkCounts.length == 1) {
      String onlyNetwork = summary.networkCounts.keys.first.toUpperCase();
      insights.add(buildInsightCard(
        icon: Icons.info_outline_rounded,
        iconColor: Colors.blue.shade400,
        title: "Network Diversity Tip",
        description: "Your cards are entirely on $onlyNetwork. Consider securing alternative networks (e.g. RuPay, MasterCard, or Amex) to diversify coverage and rewards structures.",
      ));
    }

    // Insight 4: Upcoming bill date
    if (summary.upcomingBills.isNotEmpty) {
      final nextBill = summary.upcomingBills.first;
      final wallet = nextBill['wallet'] as Wallet;
      final day = nextBill['date'] as int;
      final today = DateTime.now().day;
      int diff = day >= today ? day - today : day + 30 - today;

      String diffText = diff == 0 ? "today" : (diff == 1 ? "tomorrow" : "in $diff days");
      insights.add(buildInsightCard(
        icon: Icons.calendar_month_rounded,
        iconColor: diff <= 5 ? Colors.redAccent : Colors.teal.shade400,
        title: "Upcoming Payment Reminder",
        description: "Your bill for '${wallet.name}' is due $diffText (Day $day). Pay in full to avoid late finance charges.",
      ));
    }

    if (insights.isEmpty) {
      insights.add(buildInsightCard(
        icon: Icons.lightbulb_outline_rounded,
        iconColor: Colors.amber,
        title: "Insights Engine Active",
        description: "Add rewards percentage, credit limits, and billing dates to your cards to receive automated credit safety guidelines.",
      ));
    }

    return insights;
  }

  // ==================== TAB 2: ANALYTICS TAB ====================
  Widget _buildAnalyticsTab(WalletSummary summary, bool isDark, String symbol) {
    final textColor = isDark ? Colors.white : Colors.black;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- 1. Brand Colored Network Share ---
        _LiquidGlassSummarySection(
          title: "Network Distribution",
          icon: Icons.pie_chart_outline_rounded,
          isDark: isDark,
          child: _buildNetworkDistributionChart(summary.networkCounts, isDark),
        ),

        // --- 2. Issuers and Card Type breakdowns ---
        if (summary.issuerCounts.isNotEmpty || summary.cardTypeCounts.isNotEmpty)
          _LiquidGlassSummarySection(
            title: "Portfolio Allocation Breakdown",
            icon: Icons.bar_chart_rounded,
            isDark: isDark,
            child: Column(
              children: [
                if (summary.issuerCounts.isNotEmpty) ...[
                  _buildDistributionList("Portfolio Issuers", summary.issuerCounts, isDark, Colors.teal),
                  if (summary.cardTypeCounts.isNotEmpty)
                    Divider(
                      height: 32,
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                ],
                if (summary.cardTypeCounts.isNotEmpty)
                  _buildDistributionList("Card Types", summary.cardTypeCounts, isDark, Colors.purple),
              ],
            ),
          ),

        // --- 3. Portfolio Highlights ---
        if (summary.topCashbackCard != null || summary.highestLimitCard != null)
          _LiquidGlassSummarySection(
            title: "Portfolio Superstars",
            icon: Icons.auto_awesome_motion_rounded,
            isDark: isDark,
            child: Column(
              children: [
                if (summary.topCashbackCard != null) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        "TOP EARNER (REWARDS)",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                  _buildMiniCardMockup(summary.topCashbackCard!, isDark, symbol),
                  const SizedBox(height: 24),
                ],
                if (summary.highestLimitCard != null) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        "HIGHEST CREDIT LIMIT",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                  _buildMiniCardMockup(summary.highestLimitCard!, isDark, symbol),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNetworkDistributionChart(Map<String, int> counts, bool isDark) {
    if (counts.isEmpty) return const SizedBox.shrink();
    int total = counts.values.fold(0, (sum, val) => sum + val);

    final brandColors = {
      'VISA': const Color(0xFF1A1F71),
      'MASTERCARD': const Color(0xFFEB001B),
      'RUPAY': const Color(0xFF00A2E8),
      'AMEX': const Color(0xFF007CC2),
      'DISCOVER': const Color(0xFFF45E2A),
    };

    List<Widget> segments = [];
    List<Widget> legendItems = [];

    for (final entry in counts.entries) {
      String name = entry.key.toUpperCase();
      int count = entry.value;
      double pct = count / total;
      Color color = brandColors[name] ?? Colors.purple;

      segments.add(
        Expanded(
          flex: (pct * 100).round().clamp(1, 100),
          child: Container(
            height: 12,
            color: color,
          ),
        ),
      );

      legendItems.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              "$name ($count)",
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white70 : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Row(
            children: segments
                .expand((widget) => [widget, const SizedBox(width: 1.5)])
                .toList()
              ..removeLast(),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 10,
          children: legendItems,
        ),
      ],
    );
  }

  Widget _buildDistributionList(
    String title,
    Map<String, int> counts,
    bool isDark,
    Color baseThemeColor,
  ) {
    final textColor = isDark ? Colors.white : Colors.black;
    int total = counts.values.fold(0, (sum, val) => sum + val);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: textColor.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 12),
        ...counts.entries.map((entry) {
          double pct = entry.value / total;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: textColor,
                      ),
                    ),
                    Text(
                      "${entry.value} (${(pct * 100).toStringAsFixed(0)}%)",
                      style: TextStyle(
                        fontSize: 12.5,
                        color: textColor.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Container(
                    height: 5,
                    width: double.infinity,
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: pct,
                      child: Container(
                        color: baseThemeColor.withValues(
                          alpha: isDark ? 0.7 : 0.9,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMiniCardMockup(Wallet wallet, bool isDark, String symbol) {
    final colorKey = wallet.color ?? 'obsidian';
    final colorData = cardColorPalette[colorKey] ?? cardColorPalette['obsidian']!;
    final textColor = Colors.white;
    final maxLimitStr = wallet.maxlimit ?? '0';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorData.accent,
            colorData.secondary,
            colorData.primary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                wallet.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: textColor,
                ),
              ),
              if (wallet.network != null && wallet.network!.isNotEmpty)
                Text(
                  wallet.network!.toUpperCase(),
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: textColor.withValues(alpha: 0.8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "CREDIT LIMIT",
                    style: TextStyle(
                      fontSize: 8.5,
                      color: textColor.withValues(alpha: 0.5),
                      letterSpacing: 1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$symbol${double.tryParse(maxLimitStr)?.toStringAsFixed(0) ?? maxLimitStr}",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "REWARDS RATE",
                    style: TextStyle(
                      fontSize: 8.5,
                      color: textColor.withValues(alpha: 0.5),
                      letterSpacing: 1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${wallet.rewards ?? '0'}%",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== TAB 3: BILLS & goals TAB ====================
  Widget _buildBillsWaiversTab(WalletSummary summary, bool isDark, String symbol) {
    final textColor = isDark ? Colors.white : Colors.black;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- 1. Upcoming Bills Timeline ---
        _LiquidGlassSummarySection(
          title: "Upcoming Bill Schedule",
          icon: Icons.event_note_rounded,
          isDark: isDark,
          child: summary.upcomingBills.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      "No bills scheduled. Update card due dates.",
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: summary.upcomingBills.map((item) {
                    final wallet = item['wallet'] as Wallet;
                    final date = item['date'] as int;
                    final today = DateTime.now().day;
                    int diff = date >= today ? date - today : date + 30 - today;

                    return _buildTimelineItem(wallet, date, diff, isDark, symbol);
                  }).toList(),
                ),
        ),

        // --- 2. Fee Waiver Trackers ---
        _LiquidGlassSummarySection(
          title: "Annual Fee Waiver Goals",
          icon: Icons.verified_outlined,
          isDark: isDark,
          child: summary.feeWaiverCards.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      "No waiver spends configured.",
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: summary.feeWaiverCards.map((wallet) {
                    double spends = double.tryParse(wallet.spends ?? '0') ?? 0;
                    double waiver = double.tryParse(wallet.annualFeeWaiver ?? '0') ?? 0;
                    double progress = waiver > 0 ? (spends / waiver).clamp(0.0, 1.0) : 1.0;
                    bool isMet = spends >= waiver;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                wallet.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  fontSize: 13.5,
                                ),
                              ),
                              _buildWaiverBadge(isMet, progress),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: progress,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    gradient: LinearGradient(
                                      colors: isMet
                                          ? [
                                              Colors.teal.shade400,
                                              Colors.green.shade500,
                                            ]
                                          : [
                                              Colors.blue.shade400,
                                              Colors.teal.shade500,
                                            ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${(progress * 100).toStringAsFixed(0)}% Completed",
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: textColor.withValues(alpha: 0.4),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                "$symbol${spends.toStringAsFixed(0)} / $symbol${waiver.toStringAsFixed(0)}",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: textColor.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(Wallet wallet, int dueDay, int diffDays, bool isDark, String symbol) {
    final textColor = isDark ? Colors.white : Colors.black;
    Color urgencyColor;
    String statusText;

    if (diffDays == 0) {
      urgencyColor = Colors.red.shade600;
      statusText = "DUE TODAY";
    } else if (diffDays <= 3) {
      urgencyColor = Colors.red.shade400;
      statusText = "$diffDays DAYS LEFT";
    } else if (diffDays <= 7) {
      urgencyColor = Colors.amber.shade600;
      statusText = "$diffDays DAYS LEFT";
    } else {
      urgencyColor = isDark ? Colors.white24 : Colors.black26;
      statusText = "$diffDays DAYS LEFT";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: urgencyColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "DAY",
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: diffDays <= 7 ? urgencyColor : textColor.withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  "$dueDay",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: diffDays <= 7 ? urgencyColor : textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wallet.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (wallet.network != null && wallet.network!.isNotEmpty) ...[
                      Text(
                        wallet.network!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: textColor.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: textColor.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      "Spends: $symbol${double.tryParse(wallet.spends ?? '0')?.toStringAsFixed(0) ?? '0'}",
                      style: TextStyle(
                        fontSize: 11,
                        color: textColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: diffDays <= 7 ? urgencyColor.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: diffDays <= 7 ? urgencyColor : textColor.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaiverBadge(bool isMet, double progress) {
    if (isMet) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.green.shade400.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.shade400.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, color: Colors.green.shade400, size: 11),
            const SizedBox(width: 4),
            Text(
              "Waiver Achieved 🎉",
              style: TextStyle(
                color: Colors.green.shade400,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.blue.shade400.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade400.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        "Active Goal",
        style: TextStyle(
          color: Colors.blue.shade400,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _HeroStatCol extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool alignRight;

  const _HeroStatCol({
    required this.label,
    required this.value,
    required this.isDark,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black;
    final align = alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: textColor.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor.withValues(alpha: 0.85),
          ),
        ),
      ],
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
            "The following cards are missing key details. Update them for fully accurate summary metrics.",
            style: TextStyle(
              color: textColor.withValues(alpha: 0.5),
              fontSize: 12.5,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          ...incompleteCards.map((wallet) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                dense: true,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.credit_card_outlined,
                    color: textColor.withValues(alpha: 0.6),
                    size: 18,
                  ),
                ),
                title: Text(
                  wallet.name,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    "Missing limit, reward, or due dates",
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade400.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Configure",
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade400,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 9,
                        color: Colors.blue.shade400,
                      ),
                    ],
                  ),
                ),
                onTap: () => Navigator.push(
                  context,
                  SmoothPageRoute(page: WalletDetailScreen(wallet: wallet)),
                ),
              ),
            );
          }),
        ],
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
                Icon(icon, size: 16, color: textColor.withValues(alpha: 0.4)),
                const SizedBox(width: 8),
              ],
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.4),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 11.5,
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
        color: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
        border: Border.all(
          color: isDark ? const Color(0xFF222222) : const Color(0xFFE2E2E2),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }
}
