import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallet/models/provider_helper.dart';
import 'package:wallet/models/theme_provider.dart';

class Summary extends StatefulWidget {
  const Summary({super.key});

  @override
  State<Summary> createState() => _SummaryState();
}

class _SummaryState extends State<Summary> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        title: Text(
          "Summary of Your Data",
          style: themeProvider.getTextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: themeProvider.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: themeProvider.primaryColor),
      ),
      body: Consumer<WalletProvider>(
        builder: (context, provider, child) {
          if (provider.wallets.isEmpty) {
            return Center(
              child: Text(
                "Please Add Data to View this Page",
                style: themeProvider.getTextStyle(
                  fontSize: 18,
                  color: themeProvider.secondaryColor,
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Table headers as a row of text widgets
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: themeProvider.borderColor,
                            ),
                            color: themeProvider.surfaceColor,
                          ),
                          child: Row(
                            children: [
                              _tableHeaderCell("Card Name", 150),
                              _tableHeaderCell("Number", 150),
                              _tableHeaderCell("Expiry", 100),
                              _tableHeaderCell("Network", 100),
                              _tableHeaderCell("Spends", 100),
                              _tableHeaderCell("Rewards", 100),
                              _tableHeaderCell("Annual Fee Waiver", 150),
                              _tableHeaderCell("Max Limit", 150),
                              _tableHeaderCell("Card Type", 100),
                              _tableHeaderCell("Bill Date", 120),
                              _tableHeaderCell("Category", 120),
                            ],
                          ),
                        ),
                        Divider(),
                        for (var wallet in provider.wallets)
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: themeProvider.borderColor,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Row(
                                children: [
                                  _tableCell(wallet.name, 150),
                                  _tableCell(
                                    wallet.number.substring(
                                      wallet.number.length - 4,
                                    ),
                                    150,
                                  ),
                                  _tableCell(wallet.expiry, 100),
                                  _tableCell(wallet.network ?? "N/A", 100),
                                  _tableCell(
                                    double.parse(
                                      wallet.spends ?? "0",
                                    ).toStringAsFixed(2),
                                    100,
                                  ),
                                  _tableCell(
                                    wallet.spends != null &&
                                            wallet.rewards != null
                                        ? calculateRewards(
                                            double.parse(wallet.spends ?? "0"),
                                            double.parse(wallet.rewards ?? "0"),
                                          ).toStringAsFixed(2)
                                        : "N/A",
                                    100,
                                  ),
                                  _tableCell(
                                    wallet.annualFeeWaiver != null &&
                                            wallet.spends != null
                                        ? (double.parse(
                                                    wallet.annualFeeWaiver ??
                                                        "0",
                                                  ) <
                                                  double.parse(
                                                    wallet.spends ?? "0",
                                                  )
                                              ? "waived off"
                                              : wallet.annualFeeWaiver!)
                                        : "N/A",
                                    150,
                                  ),
                                  _tableCell(wallet.maxlimit ?? "N/A", 150),
                                  _tableCell(wallet.cardtype ?? "N/A", 100),
                                  _tableCell(wallet.billdate ?? "N/A", 120),
                                  _tableCell(wallet.category ?? "N/A", 120),
                                ],
                              ),
                            ),
                          ),
                        SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper method to create header cells with fixed width and borders
  Widget _tableHeaderCell(String text, double width) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border.all(color: themeProvider.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          text,
          style: themeProvider.getTextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // Helper method to create regular cells with fixed width and borders
  Widget _tableCell(String text, double width) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          text,
          style: themeProvider.getTextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // Example method to calculate rewards if needed
  double calculateRewards(double spends, double rewards) {
    // Calculate reward as per some logic
    return (spends * rewards) / 100; // Sample formula
  }
}
