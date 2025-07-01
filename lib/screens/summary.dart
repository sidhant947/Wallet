import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:wallet/models/provider_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class Summary extends StatefulWidget {
  const Summary({super.key});

  @override
  State<Summary> createState() => _SummaryState();
}

class _SummaryState extends State<Summary> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Summary of Your Data"),
        centerTitle: true,
        forceMaterialTransparency: true,
        actions: [],
      ),
      body: Consumer<WalletProvider>(
        builder: (context, provider, child) {
          if (provider.wallets.isEmpty) {
            return Center(child: Text("Please Add Data to View this Page"));
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
                            border: Border.all(color: Colors.black),
                            color: Colors
                                .grey[200], // Light grey background for header
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
                              border: Border.all(color: Colors.white),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  _tableCell(wallet.name, 150),
                                  _tableCell(
                                      wallet.number
                                          .substring(wallet.number.length - 4),
                                      150),
                                  _tableCell(wallet.expiry, 100),
                                  _tableCell(wallet.network ?? "N/A", 100),
                                  _tableCell(
                                      double.parse(wallet.spends ?? "0")
                                          .toStringAsFixed(2),
                                      100),
                                  _tableCell(
                                      wallet.spends != null &&
                                              wallet.rewards != null
                                          ? calculateRewards(
                                                  double.parse(
                                                      wallet.spends ?? "0"),
                                                  double.parse(
                                                      wallet.rewards ?? "0"))
                                              .toStringAsFixed(2)
                                          : "N/A",
                                      100),
                                  _tableCell(
                                      wallet.annualFeeWaiver != null &&
                                              wallet.spends != null
                                          ? (double.parse(
                                                      wallet.annualFeeWaiver ??
                                                          "0") <
                                                  double.parse(
                                                      wallet.spends ?? "0")
                                              ? "waived off"
                                              : wallet.annualFeeWaiver!)
                                          : "N/A",
                                      150),
                                  _tableCell(wallet.maxlimit ?? "N/A", 150),
                                  _tableCell(wallet.cardtype ?? "N/A", 100),
                                  _tableCell(wallet.billdate ?? "N/A", 120),
                                  _tableCell(wallet.category ?? "N/A", 120),
                                ],
                              ),
                            ),
                          ),
                        SizedBox(height: 30),
                        GestureDetector(
                          onTap: () async {
                            final doc = pw.Document();

                            doc.addPage(pw.Page(
                                pageFormat: PdfPageFormat.a4,
                                build: (pw.Context context) {
                                  return buildPrintableData(provider);
                                }));

                            await Printing.layoutPdf(
                                onLayout: (PdfPageFormat format) async =>
                                    doc.save());
                          },
                          child: Container(
                            padding: EdgeInsets.all(30),
                            width: 200,
                            color: Colors.deepPurple,
                            child: Center(
                                child: Text(
                              "Download PDF",
                              style: TextStyle(fontSize: 25),
                            )),
                          ),
                        )
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
    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black), // Adding border
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // Helper method to create regular cells with fixed width and borders
  Widget _tableCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          text,
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

buildPrintableData(WalletProvider provider) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(16.0),
    child: pw.Column(children: [
      pw.Text("Wallet Summary", style: pw.TextStyle(fontSize: 14)),
      pw.SizedBox(height: 10.0),
      pw.Divider(),
      pw.SizedBox(height: 10.0),

      // Table Header
      pw.Table(
        border: pw.TableBorder.all(color: PdfColor.fromHex('#000000')),
        columnWidths: {
          0: pw.FixedColumnWidth(120),
          1: pw.FixedColumnWidth(50),
          2: pw.FixedColumnWidth(50),
          3: pw.FixedColumnWidth(50),
          4: pw.FixedColumnWidth(50),
          5: pw.FixedColumnWidth(80),
          6: pw.FixedColumnWidth(80),
          7: pw.FixedColumnWidth(50),
          8: pw.FixedColumnWidth(50),
        },
        children: [
          // Header Row
          pw.TableRow(
            children: [
              _buildTableHeader("Card Name"),
              _buildTableHeader("Number"),
              _buildTableHeader("Network"),
              _buildTableHeader("Card Type"),
              _buildTableHeader("Bill Date"),
              _buildTableHeader("Max Limit"),
              _buildTableHeader("Annual Fee Waiver"),
              _buildTableHeader("Spends"),
              _buildTableHeader("Rewards"),
            ],
          ),

          // Table Rows
          for (var wallet in provider.wallets)
            pw.TableRow(
              children: [
                _buildTableCell(wallet.name),
                _buildTableCell(
                    wallet.number.substring(wallet.number.length - 4)),
                _buildTableCell(wallet.network?.toUpperCase() ?? "N/A"),
                _buildTableCell(wallet.cardtype ?? "N/A"),
                _buildTableCell(wallet.billdate ?? "N/A"),
                _buildTableCell(wallet.maxlimit ?? "N/A"),
                _buildTableCell(wallet.annualFeeWaiver ?? "N/A"),
                _buildTableCell(wallet.spends?.toString() ?? "N/A"),

                // Calculate and display the rewards
                _buildTableCell(wallet.spends != null && wallet.rewards != null
                    ? calculateRewards(double.parse(wallet.spends ?? "0"),
                            double.parse(wallet.rewards ?? "0"))
                        .toStringAsFixed(2)
                    : "N/A"),
              ],
            ),
        ],
      ),
      // Spacer to push the link to the bottom
      pw.Spacer(),

      // Bottom clickable link text
      pw.UrlLink(
        destination:
            'https://play.google.com/store/apps/details?id=com.sidhant.wallet', // Replace with your URL
        child: pw.Text(
          'Tap here to Download our App',
          style: pw.TextStyle(
            fontSize: 20,
            color: PdfColor.fromHex(
                '#1E90FF'), // Change color to blue for link-like appearance
            decoration: pw.TextDecoration
                .underline, // Underline the text like a typical link
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
    ]),
  );
}

// Helper method to build header cells
pw.Widget _buildTableHeader(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(4.0),
    child: pw.Text(
      text,
      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6),
      textAlign: pw.TextAlign.center,
    ),
  );
}

// Helper method to build regular data cells
pw.Widget _buildTableCell(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(4.0),
    child: pw.Text(
      text,
      style: pw.TextStyle(
          fontSize: 4), // Slightly smaller font size for compactness
      textAlign: pw.TextAlign.center,
    ),
  );
}

// New helper function to calculate rewards
double calculateRewards(double spends, double rewards) {
  return (spends * rewards) / 100;
}
